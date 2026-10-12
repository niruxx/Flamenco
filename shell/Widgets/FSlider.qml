import QtQuick
import qs.Commons

// Thick "expressive" slider. Bind `value`, react to `moved(value)`.
Item {
    id: root

    property real value: 0
    property real from: 0
    property real to: 1
    property real stepSize: 0
    property string icon: ""
    property bool showValue: false
    property string valueText: Math.round(frac * 100) + "%"
    property color accent: Theme.accent

    signal moved(real value)
    signal iconClicked

    readonly property real frac: Math.max(0, Math.min(1, (value - from) / (to - from)))
    property real shown: frac

    implicitWidth: 220
    implicitHeight: 34

    Binding {
        target: root
        property: "shown"
        value: root.frac
        when: !area.pressed
    }

    Behavior on shown {
        enabled: !area.pressed
        Anim { easing.bezierCurve: Theme.curves.emphasizedDecel }
    }

    function setFromX(x) {
        let f = Math.max(0, Math.min(1, x / track.width));
        let v = from + f * (to - from);
        if (stepSize > 0)
            v = Math.round(v / stepSize) * stepSize;
        shown = (v - from) / (to - from);
        moved(v);
    }

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: Theme.surfaceHighest

        Rectangle {
            id: fill
            height: parent.height
            width: Math.max(height, parent.width * root.shown)
            radius: height / 2
            color: root.accent

            Behavior on color { CAnim {} }

            // handle line
            Rectangle {
                width: 4
                height: parent.height - 12
                radius: 2
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 8
                color: Theme.onAccent
                opacity: area.pressed || area.containsMouse ? 0.9 : 0.5
                scale: area.pressed ? 1.25 : 1

                Behavior on opacity { Anim {} }
                Behavior on scale { Anim { easing.bezierCurve: Theme.curves.springFast } }
            }
        }

        FIcon {
            visible: root.icon !== ""
            anchors.left: parent.left
            anchors.leftMargin: 9
            anchors.verticalCenter: parent.verticalCenter
            icon: root.icon
            size: 18
            fill: 1
            color: root.shown * track.width > 30 ? Theme.onAccent : Theme.text

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: root.iconClicked()
                z: 2
            }
        }

        FText {
            visible: root.showValue
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: root.valueText
            font.pixelSize: Theme.fsSm
            mono: true
            color: root.shown > 0.85 ? Theme.onAccent : Theme.textDim
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        preventStealing: true
        onPressed: mouse => root.setFromX(mouse.x)
        onPositionChanged: mouse => {
            if (pressed)
                root.setFromX(mouse.x);
        }
        onWheel: wheel => {
            const step = root.stepSize > 0 ? root.stepSize : (root.to - root.from) / 20;
            const v = Math.max(root.from, Math.min(root.to, root.value + (wheel.angleDelta.y > 0 ? step : -step)));
            root.moved(v);
        }
    }
}
