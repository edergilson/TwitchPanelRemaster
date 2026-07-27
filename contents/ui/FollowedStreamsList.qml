import QtQuick
import QtQuick.Layouts // Necessário para as propriedades de Layout
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami

Item {
    id: listRoot

    // Propriedades recebidas do main.qml
    property var listModel
    property bool isLoading: false
    property string lastError: ""
    property bool isConnected: false

    // Garante o tamanho base
    implicitWidth: Kirigami.Units.gridUnit * 20
    implicitHeight: Kirigami.Units.gridUnit * 25

    // CORREÇÃO: Garante que o painel reserve o espaço do popup e não o abra espremido (0x0)
    Layout.preferredWidth: Kirigami.Units.gridUnit * 20
    Layout.preferredHeight: Kirigami.Units.gridUnit * 25

    PC3.ScrollView {
        anchors.fill: parent

        ListView {
            id: listView
            model: listRoot.listModel
            clip: true
            delegate: StreamDelegate {}

            // Indicador de Carregamento
            PC3.BusyIndicator {
                anchors.centerIn: parent
                running: listRoot.isLoading && listView.count === 0
                visible: running
            }

            // Exibição de Erro
            PC3.Label {
                anchors.centerIn: parent
                anchors.margins: Kirigami.Units.largeSpacing
                width: parent.width - (Kirigami.Units.largeSpacing * 2)
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                text: listRoot.lastError
                visible: listRoot.lastError !== ""
                color: Kirigami.Theme.negativeTextColor
            }

            // Lista Vazia Original
            PC3.Label {
                anchors.centerIn: parent
                text: i18n("No live channels at the moment.")
                visible: listRoot.isConnected && listView.count === 0 && !listRoot.isLoading && listRoot.lastError === ""
                opacity: 0.7
            }

            // Desconectado
            PC3.Label {
                anchors.centerIn: parent
                text: i18n("Not connected. Go to settings.")
                visible: !listRoot.isConnected
                opacity: 0.7
            }
        }
    }
}
