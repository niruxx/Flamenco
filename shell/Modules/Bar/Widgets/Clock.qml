import QtQuick
import qs.Commons
import qs.Services
import qs.Widgets

// The bar clock. Settings → Clock & Weather → Bar clock picks the layout:
// inline "14:05 • Sat 11 Oct", stacked (time over a small date), or the time
// alone, and how its lines align. Vertical bars: hours over minutes.
BarChip {
    id: root
    property string screenName
    property int barLevel: 0
    readonly property var b: Settings.data.bar
    readonly property string layout: Theme.barVertical ? "vertical" : barLevel >= 1 && b.clockLayout === "inline" ? "time" : b.clockLayout
    readonly property int align: b.clockAlign === "left" ? Text.AlignLeft : b.clockAlign === "right" ? Text.AlignRight : Text.AlignHCenter
    highlighted: Panels.current === "calendar"
    onClicked: Panels.toggle("calendar", screenName, root)

    // one layout at a time (the chip sizes itself to what it holds)
    Loader {
        sourceComponent: root.layout === "stacked" ? stackedC : flowC
    }

    // inline, time only, or vertical
    Component {
        id: flowC

        BarFlow {
            spacing: Theme.barVertical ? -2 : 8

            FText {
                text: Theme.barVertical ? Time.hours : Time.time
                font.weight: Font.Bold
            }
            Rectangle {
                visible: root.layout === "inline"
                width: 4; height: 4; radius: 2
                color: Theme.accent
            }
            FText {
                visible: root.layout === "inline" || root.layout === "vertical"
                text: Theme.barVertical ? Time.minutes : Time.shortDate
                dim: !Theme.barVertical
                color: Theme.barVertical ? Theme.accent : Theme.textDim
                font.weight: Theme.barVertical ? Font.Bold : Font.Normal
                font.pixelSize: Theme.barVertical ? Theme.fsMd : Theme.fsSm
            }
        }
    }

    // stacked: the time over a small accent date; its lines line up as set
    Component {
        id: stackedC

        Column {
            spacing: -3
            readonly property real w: Math.max(timeText.implicitWidth, dateText.implicitWidth)

            FText {
                id: timeText
                width: parent.w
                horizontalAlignment: root.align
                text: Time.time
                font.weight: Font.Bold
                font.pixelSize: Math.min(Theme.fsMd, Math.round(Theme.barHeight * 0.36))
            }
            FText {
                id: dateText
                width: parent.w
                horizontalAlignment: root.align
                text: Time.format("ddd d")
                color: Theme.accent
                font.weight: Font.DemiBold
                font.pixelSize: Math.max(9, Math.round(Theme.barHeight * 0.24))
            }
        }
    }
}
