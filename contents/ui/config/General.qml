import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PC3

Kirigami.ScrollablePage {
    id: generalPage
    title: i18n("General")

    property alias cfg_showAvatar: showAvatarCheck.checked
    property alias cfg_showTitle: showTitleCheck.checked
    property alias cfg_showViewers: showViewersCheck.checked
    property alias cfg_showUptime: showUptimeCheck.checked
    property alias cfg_showBadgeCount: showBadgeCountCheck.checked
    property alias cfg_showNotifications: notificationsSwitch.checked
    property alias cfg_refreshInterval: refreshSpin.value
    property string cfg_sortMode

    Kirigami.FormLayout {
        PC3.CheckBox {
            id: showAvatarCheck
            Kirigami.FormData.label: i18n("Display:")
            text: i18n("Profile image")
        }
        PC3.CheckBox {
            id: showTitleCheck
            text: i18n("Stream title")
        }
        PC3.CheckBox {
            id: showViewersCheck
            text: i18n("Viewers")
        }
        PC3.CheckBox {
            id: showUptimeCheck
            text: i18n("Live since time")
        }
        PC3.CheckBox {
            id: showBadgeCountCheck
            text: i18n("Online badge")
        }
        PC3.CheckBox {
            id: notificationsSwitch
            text: i18n("Notifications")
        }

        PC3.SpinBox {
            id: refreshSpin
            Kirigami.FormData.label: i18n("Refresh each:")
            from: 60
            to: 3600
            stepSize: 10
            valueFromText: function(text, locale) { return Number.fromLocaleString(locale, text); }
            textFromValue: function(value, locale) { return i18nc("Ex: 60 seconds", "%1 s", value); }
        }

        PC3.ComboBox {
            id: sortCombo
            Kirigami.FormData.label: i18n("Sort by:")
            model: [
                { text: i18n("Viewers (Descending)"), value: "viewers" },
                { text: i18n("Channel Name"), value: "name" }
            ]
            textRole: "text"
            valueRole: "value"
            currentIndex: {
                for (let i = 0; i < model.length; i++) {
                    if (model[i].value === generalPage.cfg_sortMode) {
                        return i;
                    }
                }
                return 0;
            }

            onActivated: {
                generalPage.cfg_sortMode = currentValue
            }
        }
    }
}
