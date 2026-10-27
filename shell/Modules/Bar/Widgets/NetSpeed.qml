import QtQuick
import qs.Commons
import qs.Services
import qs.Widgets

// Download and upload speed right now. Click: the Performance panel.
BarChip {
    id: root
    property string screenName
    property int barLevel: 0
    property bool barVisible: barLevel < 2
    highlighted: Panels.current === "performance"
    onClicked: Panels.toggle("performance", screenName, root)
    function rate(b) {
        return b < 1024 ? "0 K" : b < 1024 * 1024 ? Math.round(b / 1024) + " K" : (b / 1048576).toFixed(b < 10485760 ? 1 : 0) + " M";
    }

    BarFlow {
        spacing: Theme.barVertical ? 0 : 6
        FIcon { icon: "arrow_downward"; size: Theme.barIconSm; color: Theme.accent2 }
        FText { text: root.rate(SystemStats.netDown); mono: true; font.pixelSize: Theme.barVertical ? Theme.fsXs : Theme.fsSm }
        FIcon { visible: root.barLevel < 1; icon: "arrow_upward"; size: Theme.barIconSm; color: Theme.accent3 }
        FText { visible: root.barLevel < 1; text: root.rate(SystemStats.netUp); mono: true; font.pixelSize: Theme.barVertical ? Theme.fsXs : Theme.fsSm }
    }
}
