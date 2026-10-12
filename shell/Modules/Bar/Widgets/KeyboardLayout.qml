import QtQuick
import qs.Commons
import qs.Services
import qs.Widgets

BarChip {
    property bool barVisible: Niri.layouts.length > 1
    onClicked: Niri.action("switch-layout", "next")

    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4
        FIcon { icon: "keyboard"; size: 16; anchors.verticalCenter: parent.verticalCenter }
        FText {
            text: {
                const l = Niri.currentLayout;
                const m = l.match(/\(([A-Z]{2,3})\)/);
                return m ? m[1] : l.slice(0, 2).toUpperCase();
            }
            font.pixelSize: Theme.fsSm
            font.weight: Font.Bold
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
