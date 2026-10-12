import QtQuick
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

BarChip {
    onClicked: Quickshell.execDetached([Settings.data.general.terminal, "-e", "btop"])

    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        component Stat: Row {
            property string icon
            property real value
            spacing: 4
            anchors.verticalCenter: parent.verticalCenter
            FIcon {
                icon: parent.icon
                size: 16
                color: parent.value > 0.85 ? Theme.error : Theme.accent2
                anchors.verticalCenter: parent.verticalCenter
            }
            FText {
                text: Math.round(parent.value * 100) + "%"
                mono: true
                font.pixelSize: Theme.fsSm
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Stat { icon: "memory"; value: SystemStats.cpu }
        Stat { icon: "developer_board"; value: SystemStats.mem }
    }
}
