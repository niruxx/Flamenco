import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

// An audio visualizer (cava) for whatever's playing, in the visualizer's style,
// colors and motion (Settings → Sound); resting when nothing is.
ColumnLayout {
    id: root
    property real k: 1
    property var spec
    property bool editing: false
    readonly property bool live: visible && !editing
    onLiveChanged: live ? Cava.users++ : Cava.users = Math.max(0, Cava.users - 1)
    Component.onCompleted: if (live) Cava.users++
    Component.onDestruction: if (live) Cava.users = Math.max(0, Cava.users - 1)
    spacing: Math.round(Theme.sp2 * k)

    // the shared visualizer, in the style chosen in Settings → Sound → Audio visualizer
    Spectrum {
        readonly property bool round: (Settings.data.visualizer.style || "bars") === "radial"
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: Math.round((round ? 200 : 320) * root.k)
        Layout.preferredHeight: Math.round((round ? 200 : 100) * root.k)
        count: round ? 48 : 32
        active: root.live
    }
    FText {
        Layout.alignment: Qt.AlignHCenter
        text: Media.active ? (Media.title || "Playing") + (Media.artist ? " · " + Media.artist : "") : "Nothing playing"
        dim: !Media.active
        font.pixelSize: Math.round(Theme.fsSm * root.k)
        elide: Text.ElideRight
        Layout.maximumWidth: Math.round(300 * root.k)
    }
}
