import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

// An audio visualizer (cava) for whatever's playing, in the theme's colors;
// resting bars when nothing is.
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

    Row {
        id: bars
        Layout.alignment: Qt.AlignHCenter
        spacing: Math.round(4 * root.k)
        height: Math.round(90 * root.k)
        readonly property int n: 24
        readonly property var src: Cava.values.length ? Cava.values : []
        Repeater {
            model: bars.n
            Rectangle {
                required property int index
                readonly property real t: index / (bars.n - 1)
                readonly property real v: bars.src.length ? (bars.src[Math.floor(t * (bars.src.length - 1))] ?? 0) : 0.06 + 0.04 * Math.sin(index * 0.7)
                anchors.bottom: parent.bottom
                width: Math.round(8 * root.k)
                height: Math.max(Math.round(4 * root.k), v * bars.height)
                radius: width / 2
                color: Theme.mix(Theme.accent, Theme.accent3, t)
                Behavior on height { NumberAnimation { duration: 90 } }
            }
        }
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
