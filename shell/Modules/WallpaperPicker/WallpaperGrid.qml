import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.Commons
import qs.Services
import qs.Widgets

GridView {
    id: grid

    // the screen a click sets (per-screen mode); "" sets every screen
    property string screenName: ""

    readonly property int cols: Math.max(2, Math.floor(width / 220))
    cellWidth: width / cols
    cellHeight: cellWidth * 0.62
    clip: true
    // ScriptModel diffs the list, so a rescan adds or removes cards without scrolling back to the top
    model: ScriptModel { values: Wallpapers.files }
    boundsBehavior: Flickable.OvershootBounds

    SmoothWheel {
        view: grid
    }

    FText {
        anchors.centerIn: parent
        visible: grid.count === 0
        text: Wallpapers.scanning ? "Scanning…" : Wallpapers.status === "missing" ? "Folder not found:\n" + Wallpapers.dir : "No images in " + Wallpapers.dir
        horizontalAlignment: Text.AlignHCenter
        dim: true
    }

    delegate: Item {
        id: cell
        required property string modelData
        required property int index
        readonly property bool current: modelData === Wallpapers.forScreen(grid.screenName)
        width: grid.cellWidth
        height: grid.cellHeight

        ClippingRectangle {
            id: thumb
            anchors.fill: parent
            anchors.margins: 6
            radius: cell.current ? Theme.rXl : Theme.rMd
            color: Theme.surfaceHigh
            scale: area.pressed ? 0.95 : area.containsMouse ? 1.03 : 1

            Behavior on radius { Anim { easing.bezierCurve: Theme.curves.spring } }
            Behavior on scale { Anim { easing.bezierCurve: Theme.curves.springFast } }

            SafeImage {
                anchors.fill: parent
                path: Wallpapers.stillUrl(cell.modelData)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize: Qt.size(320, 200)
                opacity: status === Image.Ready ? 1 : 0
                Behavior on opacity { Anim {} }
            }

            LiveBadge {
                path: cell.modelData
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.margins: 8
            }

            Rectangle {
                anchors.fill: parent
                color: "transparent"
                radius: cell.current ? Theme.rXl : Theme.rMd
                border.width: cell.current ? 3 : 0
                border.color: Theme.accent
                Behavior on border.width { Anim {} }
            }

            Rectangle {
                visible: cell.current
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 8
                width: 26; height: 26; radius: 13
                color: Theme.accent
                FIcon { anchors.centerIn: parent; icon: "check"; size: 16; color: Theme.onAccent }
            }
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Wallpapers.set(cell.modelData, grid.screenName)
        }

        // the star: a favorite (shown on hover, or always once starred)
        Rectangle {
            readonly property bool fav: Wallpapers.isFavorite(cell.modelData)
            visible: fav || area.containsMouse || starArea.containsMouse
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            width: 28; height: 28; radius: 14
            color: Theme.alpha(Theme.shadow, 0.45)
            FIcon { anchors.centerIn: parent; icon: "star"; size: 18; fill: parent.fav ? 1 : 0; color: parent.fav ? Theme.warning : "#ffffff" }
            MouseArea {
                id: starArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Wallpapers.toggleFavorite(cell.modelData)
            }
        }
    }
}
