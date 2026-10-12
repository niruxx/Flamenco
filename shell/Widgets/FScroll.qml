import QtQuick
import qs.Commons

// Flickable with a slim auto-hiding scroll indicator.
Flickable {
    id: root

    clip: true
    boundsBehavior: Flickable.StopAtBounds
    contentWidth: width
    flickDeceleration: 4000

    Rectangle {
        parent: root
        anchors.right: parent.right
        anchors.rightMargin: 2
        y: root.visibleArea.yPosition * root.height
        width: 4
        height: Math.max(24, root.visibleArea.heightRatio * root.height)
        radius: 2
        color: Theme.textDim
        visible: root.contentHeight > root.height
        opacity: root.moving || hover.hovered ? 0.6 : 0

        Behavior on opacity { Anim {} }
    }

    HoverHandler { id: hover }
}
