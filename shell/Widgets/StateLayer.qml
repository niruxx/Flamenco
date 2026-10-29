import QtQuick
import Quickshell.Widgets
import qs.Commons

// Hover / press overlay with an expanding ripple, clipped to the parent's radius.
// Place it as the last child of a Rectangle-like control.
MouseArea {
    id: root

    property real radius: parent?.radius ?? 0
    property color tint: Theme.text
    property bool disabled: false

    anchors.fill: parent
    hoverEnabled: true
    enabled: !disabled
    cursorShape: disabled ? Qt.ArrowCursor : Qt.PointingHandCursor

    onPressed: event => {
        if (Theme.ripple)
            ripple.burst(event.x, event.y);
    }

    ClippingRectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: root.tint
            opacity: root.disabled ? 0 : root.pressed ? 0.14 : root.containsMouse ? 0.08 : 0

            Behavior on opacity { Anim { motionRole: "feedback" } }
        }

        Rectangle {
            id: ripple

            property real cx: 0
            property real cy: 0

            function burst(px, py) {
                cx = px;
                cy = py;
                anim.restart();
            }

            x: cx - width / 2
            y: cy - height / 2
            width: 0
            height: width
            radius: width / 2
            color: root.tint
            opacity: 0

            ParallelAnimation {
                id: anim

                NumberAnimation {
                    target: ripple
                    property: "width"
                    from: 0
                    to: Math.hypot(root.width, root.height) * 2.2
                    duration: Theme.motionDuration("enter")
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.curves.standardDecel
                }
                SequentialAnimation {
                    NumberAnimation { target: ripple; property: "opacity"; to: 0.12; duration: Theme.motionDuration("feedback") }
                    NumberAnimation { target: ripple; property: "opacity"; to: 0; duration: Theme.motionDuration("enter"); easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curves.standardAccel }
                }
            }
        }
    }
}
