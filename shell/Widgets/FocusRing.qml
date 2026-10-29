import QtQuick
import qs.Commons

// Inset so rounded/clipped containers keep the keyboard indicator visible.
Rectangle {
    anchors.fill: parent
    anchors.margins: Theme.sp1
    radius: Math.max(0, (parent.radius ?? Theme.rMd) - Theme.sp1)
    color: "transparent"
    border.width: 2
    border.color: Theme.accent
    visible: parent.activeFocus
    z: 10
}
