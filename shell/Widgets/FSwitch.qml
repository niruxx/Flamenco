import QtQuick
import qs.Commons

Rectangle {
    id: root

    property string accessibleName: ""
    activeFocusOnTab: true
    Accessible.role: Accessible.CheckBox
    Accessible.name: accessibleName
    Accessible.checkable: true
    Accessible.checked: checked
    Accessible.onToggleAction: if (enabled) toggled(!checked)
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (!event.isAutoRepeat)
                root.toggled(!checked);
            event.accepted = true;
        }
    }

    FocusRing {}

    property bool checked: false
    signal toggled(bool checked)

    implicitWidth: Math.round(52 * Theme.scale)
    implicitHeight: Math.round(32 * Theme.scale)
    radius: height / 2
    color: checked ? Theme.accent : Theme.surfaceHighest
    border.width: checked ? 0 : 2
    border.color: Theme.border

    Behavior on color { CAnim {} }

    Rectangle {
        id: knob

        property real d: Math.round((mouse.pressed ? 28 : root.checked ? 24 : 16) * Theme.scale)
        width: d
        height: d
        radius: d / 2
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? root.width - width - Theme.sp1 : (root.height - width) / 2
        color: root.checked ? Theme.onAccent : Theme.textDim

        Behavior on x { Anim { easing.bezierCurve: Theme.curves.spring } }
        Behavior on d { Anim { motionRole: "feedback"; easing.bezierCurve: Theme.curves.springFast } }
        Behavior on color { CAnim {} }

        FIcon {
            anchors.centerIn: parent
            icon: "check"
            size: Math.round(15 * Theme.scale)
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
