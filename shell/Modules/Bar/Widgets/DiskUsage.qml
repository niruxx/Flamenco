import QtQuick
import qs.Commons
import qs.Services
import qs.Widgets

// How full a disk is (Settings → Bar → Disk: which one, "/" by default), colored
// by the monitoring levels. Click: the Performance panel.
BarChip {
    id: root
    property string screenName
    property int barLevel: 0
    readonly property string mount: Settings.data.bar.diskMount || "/"
    readonly property var disk: SystemStats.disks.find(d => d.mount === mount) ?? SystemStats.disks[0] ?? null
    readonly property real used: disk && disk.size > 0 ? disk.used / disk.size * 100 : -1
    property bool barVisible: used >= 0 && barLevel < 2
    highlighted: Panels.current === "performance"
    onClicked: Panels.toggle("performance", screenName, root)
    Component.onCompleted: SystemStats.diskUsers++
    Component.onDestruction: SystemStats.diskUsers--

    BarFlow {
        spacing: Theme.barVertical ? 0 : 4
        FIcon { icon: "hard_drive"; size: Theme.barIcon; color: SystemStats.colorFor("disk", root.used, Theme.accent2) }
        FText { text: Math.round(root.used) + (Theme.barVertical ? "" : "%"); mono: true; font.pixelSize: Theme.barVertical ? Theme.fsXs : Theme.fsSm }
    }
}
