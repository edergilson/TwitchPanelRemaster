import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PC3

Kirigami.ScrollablePage {
    id: playbackPage
    title: i18n("Playback")

    property string cfg_openMethod
    property alias cfg_mediaPlayer: playerField.text
    property alias cfg_extraArgs: argsField.text

    Kirigami.FormLayout {
        PC3.ComboBox {
            id: methodCombo
            Kirigami.FormData.label: i18n("On click:")
            model: [
                { text: i18n("Open in browser"), value: "browser" },
                { text: i18n("Open in streamlink"), value: "streamlink" }
            ]
            textRole: "text"
            valueRole: "value"
            currentIndex: {
                for (let i = 0; i < model.length; i++) {
                    if (model[i].value === playbackPage.cfg_openMethod) {
                        return i;
                    }
                }
                return 0;
            }

            onActivated: {
                playbackPage.cfg_openMethod = currentValue
            }
        }

        PC3.TextField {
            id: playerField
            Kirigami.FormData.label: i18n("Media Player (ex: mpv):")
            enabled: playbackPage.cfg_openMethod === "streamlink"
            Layout.fillWidth: true
        }

        PC3.TextField {
            id: argsField
            Kirigami.FormData.label: i18n("Extra args:")
            enabled: playbackPage.cfg_openMethod === "streamlink"
            placeholderText: "--player-args '--no-border --no-keepaspect-window'"
            Layout.fillWidth: true
        }
    }
}
