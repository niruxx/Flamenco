import QtQuick
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

BarChip {
    id: root
    property string screenName
    property int barLevel: 0
    property bool barVisible: barLevel < 2
    highlighted: Panels.current === "performance"
    onClicked: Panels.toggle("performance", screenName)
    onMiddleClicked: Quickshell.execDetached(Paths.term(["btop"]))

    component Stat: BarFlow {
        property string icon
        property real value
        spacing: Theme.barVertical ? 0 : 4
        FIcon {
            icon: parent.icon
            size: 16
            color: parent.value > 0.85 ? Theme.error : Theme.accent2
        }
        FText {
            text: Math.round(parent.value * 100) + (Theme.barVertical ? "" : "%")
            mono: true
            font.pixelSize: Theme.barVertical ? Theme.fsXs : Theme.fsSm
        }
    }

    BarFlow {
        spacing: Theme.barVertical ? 6 : 10
        Stat { icon: "memory"; value: SystemStats.cpu }
        Stat { icon: "developer_board"; value: SystemStats.mem; visible: root.barLevel < 1 }
    }
}
