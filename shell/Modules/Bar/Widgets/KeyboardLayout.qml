import QtQuick
import qs.Commons
import qs.Services
import qs.Widgets

BarChip {
    id: root
    property int barLevel: 0
    property bool barVisible: Niri.layouts.length > 1
    onClicked: Niri.action("switch-layout", "next")

    BarFlow {
        spacing: 4
        FIcon { visible: !Theme.barVertical && root.barLevel < 1; icon: "keyboard"; size: 16 }
        FText {
            text: {
                const l = Niri.currentLayout;
                const m = l.match(/\(([A-Z]{2,3})\)/);
                return m ? m[1] : l.slice(0, 2).toUpperCase();
            }
            font.pixelSize: Theme.fsSm
            font.weight: Font.Bold
        }
    }
}
