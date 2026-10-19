import QtQuick
import qs.Commons

// "LIVE" on a wallpaper thumbnail that's a video or a GIF. Anchor it in a corner.
Rectangle {
    id: root
    property string path
    property bool big: false
    visible: Paths.isAnimated(path)
    width: row.implicitWidth + (big ? 16 : 10)
    height: big ? 24 : 18
    radius: height / 2
    color: Theme.alpha(Theme.shadow, 0.6)
    Row {
        id: row
        anchors.centerIn: parent
        spacing: 3
        FIcon {
            anchors.verticalCenter: parent.verticalCenter
            icon: Paths.isVideo(root.path) ? "play_circle" : "gif_box"
            size: root.big ? 15 : 12
            fill: 1
            color: "#ffffff"
        }
        FText {
            anchors.verticalCenter: parent.verticalCenter
            text: "LIVE"
            color: "#ffffff"
            font.pixelSize: root.big ? Theme.fsXs : 9
            font.weight: Font.Black
            font.letterSpacing: 1
        }
    }
}
