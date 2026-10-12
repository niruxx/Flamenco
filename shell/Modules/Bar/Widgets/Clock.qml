import QtQuick
import qs.Commons
import qs.Services
import qs.Widgets

// Horizontal: "14:05 • Sat 11 Oct". Vertical: hours over minutes.
BarChip {
    id: root
    property string screenName
    property int barLevel: 0
    highlighted: Panels.current === "calendar"
    onClicked: Panels.toggle("calendar", screenName)

    BarFlow {
        spacing: Theme.barVertical ? -2 : 8

        FText {
            text: Theme.barVertical ? Time.hours : Time.time
            font.weight: Font.Bold
        }
        Rectangle {
            visible: !Theme.barVertical && root.barLevel < 1
            width: 4; height: 4; radius: 2
            color: Theme.accent
        }
        FText {
            visible: Theme.barVertical || root.barLevel < 1
            text: Theme.barVertical ? Time.minutes : Time.shortDate
            dim: !Theme.barVertical
            color: Theme.barVertical ? Theme.accent : Theme.textDim
            font.weight: Theme.barVertical ? Font.Bold : Font.Normal
            font.pixelSize: Theme.barVertical ? Theme.fsMd : Theme.fsSm
        }
    }
}
