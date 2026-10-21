import QtQuick
import Quickshell.Widgets
import qs.Commons
import qs.Services

// A person's picture in a circle, or their initial on a tint when there's none.
// Reloads when the picture is changed in Settings → Users (same file, new image).
ClippingRectangle {
    id: root
    property string path
    property string name: ""
    property int size: 44
    implicitWidth: size
    implicitHeight: size
    radius: size / 2
    color: Theme.alpha(Theme.accent, 0.22)

    FText {
        anchors.centerIn: parent
        visible: img.status !== Image.Ready
        text: (root.name || "?").slice(0, 1).toUpperCase()
        font.pixelSize: Math.round(root.size * 0.42)
        font.weight: Font.Bold
        color: Theme.accent
    }
    Image {
        id: img
        anchors.fill: parent
        readonly property string url: root.path ? Paths.toUrl(root.path) : ""
        source: url
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(root.size * 2, root.size * 2)
        asynchronous: true
        cache: false
        Connections {
            target: Users
            function onAvatarVersionChanged() {
                img.source = "";
                img.source = Qt.binding(() => img.url);
            }
        }
    }
}
