import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami

Item {
    id: compactRoot

    // Injetado pelo main.qml
    property int liveCount: 0
    property bool isConnected: false
    property bool showBadgeWhenZero: false
    property bool swowBadgeCount: Plasmoid.configuration.showBadgeCount

    implicitWidth: Kirigami.Units.iconSizes.smallMedium
    implicitHeight: Kirigami.Units.iconSizes.smallMedium

    Kirigami.Icon {
        id: icon
        anchors.fill: parent
        source: Qt.resolvedUrl("../assets/twitch.svg")
        isMask: true
        color: compactRoot.isConnected ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor
    }

    PC3.Label {
        id: badge
        visible: compactRoot.swowBadgeCount && (compactRoot.liveCount > 0 || compactRoot.showBadgeWhenZero)
        text: compactRoot.liveCount > 99 ? "99+" : String(compactRoot.liveCount)

        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        anchors.rightMargin: 0

        topPadding: 1
        bottomPadding: 1
        leftPadding: 4
        rightPadding: 4

        font.pixelSize: Math.max(8, parent.height * 0.28)
        font.bold: true
        color: "white"

        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        background: Rectangle {
            radius: height / 2
            color: compactRoot.liveCount > 0 ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.disabledTextColor
        }
    }
}
