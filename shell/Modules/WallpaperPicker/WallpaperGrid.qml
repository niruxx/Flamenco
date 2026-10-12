import QtQuick
import Quickshell.Widgets
import qs.Commons
import qs.Services
import qs.Widgets

GridView {
    id: grid

    readonly property int cols: Math.max(2, Math.floor(width / 220))
    cellWidth: width / cols
    cellHeight: cellWidth * 0.62
    clip: true
    model: Wallpapers.files
    boundsBehavior: Flickable.StopAtBounds

    FText {
        anchors.centerIn: parent
        visible: grid.count === 0
        text: "No images in " + Settings.data.wallpaper.dir
        dim: true
    }

    delegate: Item {
        id: cell
        required property string modelData
        required property int index
        readonly property bool current: modelData === Wallpapers.current
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

            Image {
                anchors.fill: parent
                source: "file://" + cell.modelData
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize: Qt.size(320, 200)
                opacity: status === Image.Ready ? 1 : 0
                Behavior on opacity { Anim {} }
            }

            Rectangle {
                anchors.fill: parent
                color: "transparent"
                radius: parent.radius
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
            onClicked: Wallpapers.set(cell.modelData)
        }
    }
}
