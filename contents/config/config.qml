import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("General")
        icon: "configure"
        source: "config/General.qml"
    }
    ConfigCategory {
        name: i18n("Twitch Account")
        icon: "im-user"
        source: "config/Account.qml"
    }
    ConfigCategory {
        name: i18n("Playback")
        icon: "media-playback-start"
        source: "config/Playback.qml"
    }
}
