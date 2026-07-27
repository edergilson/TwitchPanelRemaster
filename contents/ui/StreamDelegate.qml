import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support
import QtQuick.Effects

PC3.ItemDelegate {
    id: delegateRoot
    width: ListView.view ? ListView.view.width : parent.width

    // A mágica que resolve a sobreposição: define a altura baseada no conteúdo + margens
    implicitHeight: mainLayout.implicitHeight + topPadding + bottomPadding

    onClicked: {
        let openMethod = Plasmoid.configuration.openMethod;
        let url = "https://twitch.tv/" + model.login;

        if (openMethod === "streamlink") {
            executable.runCommand("streamlink --player " + Plasmoid.configuration.mediaPlayer + " " + Plasmoid.configuration.extraArgs + " " + url + " best")
            // console.log("Executar via QProcess:", "streamlink", url, "best");
        } else {
            Qt.openUrlExternally(url);
        }
    }

    contentItem: RowLayout {
        id: mainLayout
        spacing: Kirigami.Units.smallSpacing

        // Esquerda: Avatar
        Item {
            Layout.preferredWidth: Kirigami.Units.iconSizes.large
            Layout.preferredHeight: Kirigami.Units.iconSizes.large
            visible: Plasmoid.configuration.showAvatar

            Kirigami.Icon {
                anchors.fill: parent
                source: "im-user"
                visible: delegateAvatar.status !== Image.Ready
            }

            // 1. O MOLDE
            Rectangle {
                id: imageMask
                anchors.fill: parent
                radius: 6
                visible: false
                layer.enabled: true // <--- O SEGREDO É ESTA LINHA! (Força a renderização na GPU)
            }

            // 2. A IMAGEM
            Image {
                id: delegateAvatar
                anchors.fill: parent
                source: model.avatarUrl !== undefined && model.avatarUrl !== "" ? model.avatarUrl : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: status === Image.Ready

                // 3. APLICAÇÃO DO EFEITO
                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: imageMask
                }
            }
        }

        // Centro: Textos
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            PC3.Label {
                Layout.fillWidth: true
                text: model.userName
                font.bold: true
                elide: Text.ElideRight
            }

            PC3.Label {
                Layout.fillWidth: true
                text: model.title
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                elide: Text.ElideRight
                visible: Plasmoid.configuration.showTitle
                opacity: 0.8

                PC3.ToolTip {
                    text: model.title
                }
            }
        }

        // Direita: Status
        ColumnLayout {
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            spacing: 0

            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: Kirigami.Units.smallSpacing
                visible: Plasmoid.configuration.showViewers

                Kirigami.Icon {
                    source: "view-visible"
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    color: Kirigami.Theme.negativeTextColor
                }
                PC3.Label {
                    text: Number(model.viewerCount).toLocaleString(Qt.locale(), 'f', 0)
                    font.bold: true
                    color: Kirigami.Theme.negativeTextColor
                }
            }

            PC3.Label {
                Layout.alignment: Qt.AlignRight
                text: delegateRoot.calculateUptime(model.startedAt)
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                visible: Plasmoid.configuration.showUptime
                opacity: 0.7
            }
        }
    }

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []

        function runCommand(cmd) {
            connectedSources = [cmd]
        }

        onNewData: function(sourceName, data) {
            var stdout = data["stdout"]
            console.log("Output: " + stdout)
            disconnectedSources = [sourceName]
        }
    }

    function calculateUptime(isoDate) {
        if (!isoDate) return "";
        let start = new Date(isoDate);
        let now = new Date();
        let diffMs = now - start;
        let diffMins = Math.floor(diffMs / 60000);
        let h = Math.floor(diffMins / 60);
        let m = diffMins % 60;
        return h > 0 ? i18n("%1h %2m", h, m) : i18n("%1m", m);
    }
}
