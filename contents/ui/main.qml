import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami
import org.kde.notification as KNotifications
import org.kde.plasma.plasma5support as Plasma5Support
import "../code/twitch_api.js" as TwitchAPI

PlasmoidItem {
    id: root

    property int liveCount: streamsModel.count
    property bool isConnected: Plasmoid.configuration.accessToken !== ""
    property string lastError: ""
    property bool isLoading: false
    property var liveStreamIds: []
    property bool isFirstLoad: true
    property var notificationQueue: ({})

    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground

    KNotifications.Notification {
        id: streamNotification
        eventId: "notification"
        componentName: "plasma_workspace"
        iconName: "twitch"
    }

    Plasma5Support.DataSource {
        id: avatarDownloader
        engine: "executable"
        connectedSources: []

        onNewData: function(sourceName, data) {
            let exitCode = data["exit code"];
            disconnectSource(sourceName);

            let queuedData = root.notificationQueue[sourceName];
            if (queuedData) {
                let stream = queuedData.stream;
                let localPath = queuedData.localPath;
                delete root.notificationQueue[sourceName];

                streamNotification.title = stream.user_name + " " + i18n("is live now!");

                if (exitCode === 0) {
                    streamNotification.iconName = localPath;
                    streamNotification.text = stream.title;
                } else {
                    streamNotification.iconName = "twitch";
                    streamNotification.text = "<img src='" + queuedData.originalUrl + "' width='42' height='42'>  " + stream.title;
                }

                streamNotification.sendEvent();
            }
        }
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
        running: root.isConnected
        repeat: true
        onTriggered: fetchStreams()
    }

    Connections {
        target: Plasmoid.configuration

        function onUserIdChanged() {
            fetchStreams();
        }

        function onAccessTokenChanged() {
            if (Plasmoid.configuration.accessToken === "") {
                root.liveStreamIds = [];
                root.isFirstLoad = true;
            }
            fetchStreams();
        }

        function onSortModeChanged() {
            fetchStreams();
        }
    }

    Component.onCompleted: {
        fetchStreams();
    }

    onExpandedChanged: {
        fetchStreams();
    }

    function fireSingleNotification(stream, avatarUrl) {
        if (avatarUrl) {
            let localPath = "/tmp/twitch_avatar_" + stream.user_id + ".png";

            let cmd = "curl -s -L --max-time 8 -o " + localPath + " '" + avatarUrl + "'";

            root.notificationQueue[cmd] = {
                stream: stream,
                localPath: localPath,
                originalUrl: avatarUrl
            };

            avatarDownloader.connectSource(cmd);
        } else {
            streamNotification.title = stream.user_name + " " + i18n("is live now!");
            streamNotification.iconName = "twitch";
            streamNotification.text = stream.title;
            streamNotification.sendEvent();
        }
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
                    if (err.status === 401 && Plasmoid.configuration.refreshToken !== "") {
                        root.lastError = i18n("Token expired. Refreshing background session...");
                        root.isLoading = true;

                        TwitchAPI.refreshAccessToken(Plasmoid.configuration.refreshToken, function(refErr, refData) {
                            if (refErr) {
                                root.lastError = i18n("Session expired completely. Please go to settings and reconnect.");
                                root.isLoading = false;
                            } else {
                                if (refData.refresh_token) {
                                    Plasmoid.configuration.refreshToken = refData.refresh_token;
                                }
                                Plasmoid.configuration.accessToken = refData.access_token;
                            }
                        });
                        return;
                    }

                    root.lastError = "Error on Twitch API: " + (err.status ? err.status + " " + err.data : JSON.stringify(err));
                    return;
                }

                if (!data || !data.data) {
                    root.lastError = "Twitch Invalid Response.";
                    return;
                }

                let streams = data.data;

                let currentIds = [];
                let newLiveStreams = [];

                for (let i = 0; i < streams.length; i++) {
                    let s = streams[i];
                    currentIds.push(s.id);

                    if (root.liveStreamIds.indexOf(s.id) === -1) {
                        newLiveStreams.push(s);
                    }
                }

                root.liveStreamIds = currentIds;
                root.isFirstLoad = false;

                if (newLiveStreams.length !== 0 && Plasmoid.configuration.showNotifications) {
                    for (let k = 0; k < newLiveStreams.length; k++) {
                        let s = newLiveStreams[k];
                        let avatar = TwitchAPI.getCachedAvatar(s.user_id);

                        if (avatar) {
                            root.fireSingleNotification(s, avatar);
                        } else {
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

                if (missingAvatars.length > 0) {
                    missingAvatars = missingAvatars.slice(0, 100);
                    TwitchAPI.getUsers(missingAvatars, Plasmoid.configuration.accessToken, function(uErr, uData) {
                        if (!uErr && uData && uData.data) {
                            for (let j = 0; j < uData.data.length; j++) {
                                let user = uData.data[j];
                                TwitchAPI.avatarCache[user.id] = user.profile_image_url;
                            }

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
