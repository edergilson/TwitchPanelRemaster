import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PC3
import "../../code/oauth.js" as OAuth

Kirigami.ScrollablePage {
    id: accountPage
    title: i18n("Twitch Account")

    property string cfg_accessToken
    property string cfg_refreshToken
    property string cfg_userName
    property string cfg_userId
    property string cfg_userAvatar

    // Timer nativo do QML para fazer o "polling" aguardando seu login
    Timer {
        id: pollTimer
        repeat: true
        running: false
        property string deviceCode: ""
        property int attempts: 0

        onTriggered: {
            if (attempts >= 20) {
                pollTimer.stop();
                authMessage.type = Kirigami.MessageType.Error;
                authMessage.text = i18n("Time limit exceeded. Try to connect again.");
                return;
            }
            attempts++;

            OAuth.checkDeviceToken(deviceCode, function(err, tokenData) {
                if (err === "pending") {
                    return; // Usuário ainda não terminou de logar no navegador
                }

                pollTimer.stop(); // Para o relógio

                if (err) {
                    authMessage.type = Kirigami.MessageType.Error;
                    authMessage.text = i18n("Error: %1", err);
                    return;
                }

                // Sucesso! Salva os tokens
                cfg_accessToken = tokenData.access_token;
                if (tokenData.refresh_token) cfg_refreshToken = tokenData.refresh_token;

                authMessage.type = Kirigami.MessageType.Positive;
                authMessage.text = i18n("Successfully connected!");

                // Busca os dados do perfil (Nome e Foto)
                OAuth.fetchUserInfo(cfg_accessToken, function(uErr, uData) {
                    if (!uErr && uData.data && uData.data.length > 0) {
                        cfg_userId = uData.data[0].id;
                        cfg_userName = uData.data[0].display_name;
                        cfg_userAvatar = uData.data[0].profile_image_url;
                    }
                });
            });
        }
    }

    Kirigami.FormLayout {
        Kirigami.InlineMessage {
            id: authMessage
            Layout.fillWidth: true
            visible: false
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Status:")
            Item {
                Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                visible: cfg_userName !== ""

                Kirigami.Icon {
                    anchors.fill: parent
                    source: "im-user"
                    visible: accountAvatar.status !== Image.Ready
                }

                Image {
                    id: accountAvatar
                    anchors.fill: parent
                    source: cfg_userAvatar !== undefined ? cfg_userAvatar : ""
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    visible: status === Image.Ready
                }
            }
            PC3.Label {
                text: cfg_userName !== "" ? i18n("Connected as %1", cfg_userName) : i18n("Not connected")
            }
        }

        PC3.Button {
            text: cfg_userName !== "" ? i18n("Disconnect") : i18n("Connect with Twitch")
            icon.name: cfg_userName !== "" ? "network-disconnect" : "network-connect"
            onClicked: {
                if (cfg_userName !== "") {
                    // Desconectar
                    pollTimer.stop();
                    cfg_accessToken = "";
                    cfg_refreshToken = "";
                    cfg_userName = "";
                    cfg_userId = "";
                    cfg_userAvatar = "";
                    authMessage.visible = false;
                } else {
                    // Iniciar conexão
                    OAuth.startDeviceFlow(function(err, data) {
                        if (err) {
                            authMessage.type = Kirigami.MessageType.Error;
                            authMessage.text = i18n("Error on trying to connect: %1", err);
                            authMessage.visible = true;
                            return;
                        }

                        authMessage.type = Kirigami.MessageType.Information;
                        authMessage.text = i18n("Open Twitch in your browser and authorize. The code is: <b>%1</b>", data.user_code);
                        authMessage.visible = true;

                        Qt.openUrlExternally(data.verification_uri);

                        pollTimer.interval = data.interval * 1000;
                        pollTimer.deviceCode = data.device_code;
                        pollTimer.attempts = 0;
                        pollTimer.start();
                    });
                }
            }
        }

        Item { Kirigami.FormData.isSection: true }

        PC3.TextField {
            Kirigami.FormData.label: i18n("Access Token:")
            text: cfg_accessToken
            echoMode: TextInput.Password
            enabled: false
            Layout.fillWidth: true
        }
    }
}
