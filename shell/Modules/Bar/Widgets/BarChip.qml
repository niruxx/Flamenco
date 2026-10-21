import QtQuick
import qs.Commons
import qs.Widgets

// Generic hoverable chip in the bar: a pill in a horizontal bar, a rounded
// tile in a vertical one.
Rectangle {
    id: root

    default property alias content: holder.data
    // matches the inset of the bar's icon buttons ((size - icon) / 2), so every
    // widget sits the same distance from its neighbours
    property int padding: 7
    property bool highlighted: false
    readonly property bool vertical: Theme.barVertical
    readonly property int cross: Theme.barItem
    signal clicked
    signal rightClicked
    signal middleClicked
    signal wheel(var event)

    implicitWidth: vertical ? cross : holder.width + padding * 2
    implicitHeight: vertical ? holder.height + 12 : cross
    radius: vertical ? Theme.rMd : height / 2
    color: highlighted ? Theme.alpha(Theme.accent, 0.18) : "transparent"

    Behavior on color { CAnim {} }
    Behavior on implicitWidth { enabled: !root.vertical; Anim { easing.bezierCurve: Theme.curves.emphasizedDecel } }

    Item {
        id: holder
        anchors.centerIn: parent
        width: childrenRect.width
        height: childrenRect.height
    }

    StateLayer {
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: mouse => mouse.button === Qt.RightButton ? root.rightClicked() : mouse.button === Qt.MiddleButton ? root.middleClicked() : root.clicked()
        onWheel: event => root.wheel(event)
    }
}
