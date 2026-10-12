import QtQuick
import qs.Commons

Rectangle {
    id: root

    property string icon
    property int size: 34
    property int iconSize: Math.round(size * 0.56)
    property bool active: false
    property bool flat: true
    property bool disabled: false
    property color activeColor: Theme.accent
    property color iconColor: active ? Theme.onAccent : Theme.text
    readonly property bool hovered: sl.containsMouse

    signal clicked
    signal rightClicked
    signal middleClicked
    signal wheel(var event)

    implicitWidth: size
    implicitHeight: size
    radius: active ? Math.min(Theme.rMd, size / 2) : size / 2
    color: active ? activeColor : flat ? "transparent" : Theme.surfaceHigh
    opacity: disabled ? 0.4 : 1
    scale: sl.pressed ? 0.9 : 1

    Behavior on color { CAnim {} }
    Behavior on radius { Anim { easing.bezierCurve: Theme.curves.spring } }
    Behavior on scale { Anim { duration: Theme.durShort; easing.bezierCurve: Theme.curves.springFast } }

    FIcon {
        anchors.centerIn: parent
        icon: root.icon
        size: root.iconSize
        color: root.iconColor
        fill: root.active || root.hovered ? 1 : 0
    }

    StateLayer {
        id: sl
        disabled: root.disabled
        tint: root.iconColor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                root.rightClicked();
            else if (mouse.button === Qt.MiddleButton)
                root.middleClicked();
            else
                root.clicked();
        }
        onWheel: event => root.wheel(event)
    }
}
