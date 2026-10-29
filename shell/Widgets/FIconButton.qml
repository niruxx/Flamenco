import QtQuick
import qs.Commons

Rectangle {
    id: root

    property string accessibleName: icon.replace(/_/g, " ")
    activeFocusOnTab: true
    enabled: !disabled
    Accessible.role: Accessible.Button
    Accessible.name: accessibleName
    Accessible.onPressAction: if (enabled) clicked()
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (!event.isAutoRepeat)
                root.clicked();
            event.accepted = true;
        }
    }

    FocusRing {}

    property string icon
    property int size: 34
    property int iconSize: Math.round(size * 0.56)
    property bool active: false
    property bool flat: true
    property bool disabled: false
    property color activeColor: Theme.accent
    property color iconColor: active ? Theme.onColor(activeColor) : Theme.text
    readonly property bool hovered: sl.containsMouse

    signal clicked
    signal rightClicked
    signal middleClicked
    signal wheel(var event)

    implicitWidth: size
    implicitHeight: size
    radius: active ? Math.min(Theme.rMd, size / 2) : size / 2
    color: active ? activeColor : flat ? "transparent" : Theme.controlSurface
    opacity: disabled ? 0.4 : 1
    scale: sl.pressed && Theme.spatialMotion() ? 0.96 : 1

    Finish { strength: 0.24; visible: Theme.materialGlass && (root.active || !root.flat) }

    Behavior on color { CAnim {} }
    Behavior on radius { Anim { motionRole: "shape" } }
    Behavior on scale { Anim { motionRole: "feedback"; easing.bezierCurve: Theme.curves.springFast } }

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
