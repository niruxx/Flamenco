import QtQuick
import qs.Commons
import qs.Services
import qs.Widgets

// Battery, in the theme picked in Settings → Bar → Battery (see BatteryGlyph).
BarChip {
    id: root
    property string screenName
    property int barLevel: 0
    property bool barVisible: Power.hasBattery
    readonly property var b: Settings.data.bar
    onClicked: Panels.toggle("control", screenName, root)

    // nearly empty and not charging: blink
    SequentialAnimation on opacity {
        running: root.b.batteryBlink && Power.percent <= Math.max(5, root.b.batteryLow - 5) && !Power.charging
        loops: Animation.Infinite
        NumberAnimation { to: 0.35; duration: 700 }
        NumberAnimation { to: 1; duration: 700 }
        onRunningChanged: if (!running) root.opacity = 1
    }

    BatteryGlyph {
        percent: Power.percent
        charging: Power.charging
        // the old two-way setting, and anything unknown, still works
        theme: root.b.batteryStyle || "battery"
        colors: root.b.batteryColors || "theme"
        showPercent: (root.b.batteryPercent ?? true) && root.barLevel < 2
        low: root.b.batteryLow || 15
        animate: root.b.batteryChargeAnim ?? true
        compact: Theme.barVertical
    }
}
