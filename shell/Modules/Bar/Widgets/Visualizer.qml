import QtQuick
import qs.Commons
import qs.Services
import qs.Widgets

// Little bars that move with what's playing (cava), in the visualizer's style.
// Shows while something plays.
Item {
    id: root

    property string screenName
    property int barLevel: 0
    property bool barVisible: Settings.data.visualizer.enabled !== false && Cava.available && Media.playing && barLevel < 2
    readonly property bool vertical: Theme.barVertical
    readonly property int count: 10
    readonly property int thick: Theme.barItem - 8

    implicitWidth: vertical ? thick : count * 6
    implicitHeight: vertical ? count * 6 : thick

    // cava only runs while a visualizer is showing
    Component.onCompleted: if (barVisible) Cava.users++
    onBarVisibleChanged: Cava.users += barVisible ? 1 : -1
    Component.onDestruction: if (barVisible) Cava.users--

    // the shared visualizer (Settings → Sound → Audio visualizer: style, colors, motion)
    Spectrum {
        anchors.fill: parent
        count: root.count
        vertical: root.vertical
        gap: 0.33
        active: root.barVisible
    }
}
