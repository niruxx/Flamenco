import QtQuick
import qs.Commons
import qs.Services
import qs.Widgets

BarChip {
    id: root
    property string screenName
    property int barLevel: 0
    property bool barVisible: Weather.ready && barLevel < 2
    onClicked: Panels.toggle("calendar", screenName, root)

    BarFlow {
        spacing: Theme.barVertical ? 0 : 4
        FIcon { icon: Weather.icon; size: 18; fill: 1; color: Theme.accent2 }
        FText { text: Math.round(Weather.temp) + "°"; font.pixelSize: Theme.barVertical ? Theme.fsXs : Theme.fsSm }
    }
}
