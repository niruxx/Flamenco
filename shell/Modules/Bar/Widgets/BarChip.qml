import QtQuick
import qs.Commons
import qs.Widgets

// Generic hoverable pill in the bar.
Rectangle {
    id: root

    default property alias content: holder.data
    property int padding: 10
    property bool highlighted: false
    signal clicked
    signal rightClicked
    signal middleClicked
    signal wheel(var event)

    implicitHeight: Theme.barHeight - 10
    implicitWidth: holder.childrenRect.width + padding * 2
    radius: height / 2
    color: highlighted ? Theme.alpha(Theme.accent, 0.18) : "transparent"

    Behavior on color { CAnim {} }
    Behavior on implicitWidth { Anim { easing.bezierCurve: Theme.curves.emphasizedDecel } }

    Item {
        id: holder
        x: root.padding
        width: childrenRect.width
        height: parent.height
    }

    StateLayer {
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: mouse => mouse.button === Qt.RightButton ? root.rightClicked() : mouse.button === Qt.MiddleButton ? root.middleClicked() : root.clicked()
        onWheel: event => root.wheel(event)
    }
}
