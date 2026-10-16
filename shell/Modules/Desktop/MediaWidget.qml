import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.Commons
import qs.Services
import qs.Widgets

// What's playing: cover art, title, artist and controls.
RowLayout {
    id: root
    property real k: 1
    property var spec
    property bool editing: false
    spacing: Math.round(Theme.sp3 * k)
    width: Math.round(330 * k)

    ClippingRectangle {
        Layout.preferredWidth: Math.round(76 * root.k)
        Layout.preferredHeight: Math.round(76 * root.k)
        radius: Theme.rLg
        color: Theme.alpha(Theme.accent, 0.2)
        FIcon {
            anchors.centerIn: parent
            visible: art.status !== Image.Ready
            icon: Media.active ? "music_note" : "music_off"
            size: Math.round(32 * root.k)
            color: Theme.accent
        }
        Image {
            id: art
            anchors.fill: parent
            source: Media.art
            sourceSize: Qt.size(300, 300)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
    }
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Math.round(2 * root.k)
        FText {
            Layout.fillWidth: true
            text: Media.title
            font.weight: Font.DemiBold
            font.pixelSize: Math.round(Theme.fsLg * root.k)
            elide: Text.ElideRight
        }
        FText {
            Layout.fillWidth: true
            visible: text !== ""
            text: Media.artist
            dim: true
            font.pixelSize: Math.round(Theme.fsSm * root.k)
            elide: Text.ElideRight
        }
        Row {
            visible: Media.active
            enabled: !root.editing
            spacing: 2
            FIconButton { icon: "skip_previous"; size: Math.round(32 * root.k); onClicked: Media.previous() }
            FIconButton { icon: Media.playing ? "pause" : "play_arrow"; size: Math.round(32 * root.k); active: true; onClicked: Media.toggle() }
            FIconButton { icon: "skip_next"; size: Math.round(32 * root.k); onClicked: Media.next() }
        }
    }
}
