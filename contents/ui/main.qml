import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami
import org.kde.notification as KNotifications
import "../code/twitch_api.js" as TwitchAPI

PlasmoidItem {
    id: root

    property int liveCount: streamsModel.count
    property bool isConnected: Plasmoid.configuration.accessToken !== ""

    // Novas propriedades de estado para debug e UI
    property string lastError: ""
    property bool isLoading: false

    // Variáveis para rastrear os canais e evitar SPAM de notificações
    property var liveStreamIds: []
    property bool isFirstLoad: true

    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground

    // Componente de Notificação Nativa do KDE
    KNotifications.Notification {
        id: streamNotification
        eventId: "notification"
        componentName: "plasma_workspace"
        iconName: "twitch"
    }

    compactRepresentation: Component {
        Item {
            implicitWidth: Kirigami.Units.iconSizes.smallMedium
            implicitHeight: Kirigami.Units.iconSizes.smallMedium

            CompactRepresentation {
                anchors.fill: parent
                liveCount: root.liveCount
                isConnected: root.isConnected
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.expanded = !root.expanded
            }
        }
    }

    fullRepresentation: Component {
        FollowedStreamsList {
            // Injetamos as variáveis cruzando a barreira do componente!
            listModel: streamsModel
            isLoading: root.isLoading
            lastError: root.lastError
            isConnected: root.isConnected
        }
    }

    ListModel {
        id: streamsModel
    }

    Timer {
        id: refreshTimer
        interval: Math.max(30, Plasmoid.configuration.refreshInterval) * 1000
        running: root.isConnected && root.expanded
        repeat: true
        onTriggered: fetchStreams()
    }

    // Garante atualização automática no momento em que você clica em "Aplicar"
    Connections {
        target: Plasmoid.configuration

        // Gatilho 1: Quando você loga, o Plasma salva o novo ID
        function onUserIdChanged() {
            fetchStreams();
        }

        // Gatilho 2: Quando você desconecta, limpando o token
        function onAccessTokenChanged() {
            // Se deslogou, reseta o histórico para não bugar no próximo login
            if (Plasmoid.configuration.accessToken === "") {
                root.liveStreamIds = [];
                root.isFirstLoad = true;
            }
            fetchStreams();
        }

        // Gatilho 3: Se você for na aba Geral e mudar a ordenação
        function onSortModeChanged() {
            fetchStreams();
        }
    }

    // Chama a API imediatamente caso o widget já inicie expandido (ex: no Desktop)
    Component.onCompleted: {
        fetchStreams();
    }

    onExpandedChanged: {
        if (root.expanded) fetchStreams();
    }

    // Função auxiliar que formata o balão de notificação com HTML e dispara
    function fireSingleNotification(stream, avatarUrl) {
        streamNotification.title = stream.user_name + " " + i18n("is live now!");

        if (avatarUrl) {
            // Injetamos a imagem da internet dentro do texto usando HTML (Rich Text)
            streamNotification.text = "<img src='" + avatarUrl + "' width='42' height='42'>  " + stream.title;
        } else {
            streamNotification.text = stream.title;
        }

        streamNotification.sendEvent();
    }

    function fetchStreams() {
        if (!isConnected) return;

        if (Plasmoid.configuration.userId === "") {
            root.lastError = "User ID not found. Please, disconnect and connect again.";
            return;
        }

        root.isLoading = true;
        root.lastError = "";

        TwitchAPI.getFollowedStreams(
            Plasmoid.configuration.userId,
            Plasmoid.configuration.accessToken,
            function(err, data) {
                root.isLoading = false;

                if (err) {
                    root.lastError = "Error on Twitch API: " + (err.status ? err.status + " " + err.data : JSON.stringify(err));
                    return;
                }

                if (!data || !data.data) {
                    root.lastError = "Twitch Invalid Response.";
                    return;
                }

                let streams = data.data;

                // --- 1. LÓGICA DO SISTEMA DE NOTIFICAÇÕES ---
                let currentIds = [];
                let newLiveStreams = [];

                for (let i = 0; i < streams.length; i++) {
                    let s = streams[i];
                    currentIds.push(s.id); // Guardamos o ID único da transmissão

                    // Se a extensão já carregou antes e essa transmissão é inédita...
                    if (!root.isFirstLoad && root.liveStreamIds.indexOf(s.id) === -1) {
                        newLiveStreams.push(s);
                    }
                }

                root.liveStreamIds = currentIds;
                root.isFirstLoad = false;

                // Disparo inteligente das notificações
                if (newLiveStreams.length !== 0 && Plasmoid.configuration.showNotifications) {
                    for (let k = 0; k < newLiveStreams.length; k++) {
                        let s = newLiveStreams[k];
                        let avatar = TwitchAPI.getCachedAvatar(s.user_id);

                        if (avatar) {
                            root.fireSingleNotification(s, avatar);
                        } else {
                            // Se a foto não estiver no cache, baixa ela rapidinho na API da Twitch
                            TwitchAPI.getUsers([s.user_id], Plasmoid.configuration.accessToken, function(uErr, uData) {
                                let fetchedAvatar = "";
                                if (!uErr && uData && uData.data && uData.data.length > 0) {
                                    fetchedAvatar = uData.data[0].profile_image_url;
                                    TwitchAPI.avatarCache[s.user_id] = fetchedAvatar;
                                }
                                root.fireSingleNotification(s, fetchedAvatar);
                            });
                        }
                    }
                }
                // --- FIM DA LÓGICA DE NOTIFICAÇÕES ---

                // --- 2. PREENCHIMENTO DA UI (LISTA VISUAL) ---
                if (Plasmoid.configuration.sortMode === "viewers") {
                    streams.sort((a, b) => b.viewer_count - a.viewer_count);
                } else {
                    streams.sort((a, b) => a.user_name.localeCompare(b.user_name));
                }

                streamsModel.clear();
                let missingAvatars = [];

                for (let i = 0; i < streams.length; i++) {
                    let s = streams[i];
                    let avatar = TwitchAPI.getCachedAvatar(s.user_id);

                    if (!avatar && missingAvatars.indexOf(s.user_id) === -1) {
                        missingAvatars.push(s.user_id);
                    }

                    streamsModel.append({
                        streamId: s.id,
                        userId: s.user_id,
                        userName: s.user_name,
                        login: s.user_login,
                        title: s.title,
                        viewerCount: s.viewer_count,
                        startedAt: s.started_at,
                        avatarUrl: avatar
                    });
                }

                // Dispara a busca das fotos faltantes em background
                if (missingAvatars.length > 0) {
                    missingAvatars = missingAvatars.slice(0, 100);
                    TwitchAPI.getUsers(missingAvatars, Plasmoid.configuration.accessToken, function(uErr, uData) {
                        if (!uErr && uData && uData.data) {
                            // Atualiza o cache JS
                            for (let j = 0; j < uData.data.length; j++) {
                                let user = uData.data[j];
                                TwitchAPI.avatarCache[user.id] = user.profile_image_url;
                            }

                            // Atualiza os itens da lista dinamicamente
                            for (let k = 0; k < streamsModel.count; k++) {
                                let item = streamsModel.get(k);
                                if (TwitchAPI.avatarCache[item.userId]) {
                                    streamsModel.setProperty(k, "avatarUrl", TwitchAPI.avatarCache[item.userId]);
                                }
                            }
                        }
                    });
                }
            }
        );
    }
}
