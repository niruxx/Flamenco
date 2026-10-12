import QtQuick
import qs.Commons

Rectangle {
    id: root

    property bool checked: false
    signal toggled(bool checked)

    implicitWidth: 52
    implicitHeight: 30
    radius: height / 2
    color: checked ? Theme.accent : Theme.surfaceHighest
    border.width: checked ? 0 : 2
    border.color: Theme.border

    Behavior on color { CAnim {} }

    Rectangle {
        id: knob

        property real d: mouse.pressed ? 24 : root.checked ? 22 : 16
        width: d
        height: d
        radius: d / 2
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? root.width - width - 4 : 7
        color: root.checked ? Theme.onAccent : Theme.textDim

        Behavior on x { Anim { easing.bezierCurve: Theme.curves.spring } }
        Behavior on d { Anim { duration: Theme.durShort; easing.bezierCurve: Theme.curves.springFast } }
        Behavior on color { CAnim {} }

        FIcon {
            anchors.centerIn: parent
            icon: "check"
            size: 15
            weight: 700
            color: Theme.accent
            opacity: root.checked ? 1 : 0
            scale: root.checked ? 1 : 0.4

            Behavior on opacity { Anim {} }
            Behavior on scale { Anim { easing.bezierCurve: Theme.curves.spring } }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
