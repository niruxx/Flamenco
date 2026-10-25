import QtQuick
import qs.Commons
import qs.Widgets

// A big pill slider on the dashboard's Home: a gradient fill up to the value,
// the icon on the left (click it to mute) and the percent on the right.
Rectangle {
    id: root

    property real value: 0                 // 0–1
    property string icon
    property color from: Theme.accent
    property color to: Theme.accent2
    property bool muted: false
    signal moved(real v)
    signal iconClicked

    readonly property real shown: drag.pressed ? drag.live : Math.max(0, Math.min(1, value))
    implicitHeight: 40
    radius: height / 2
    color: Theme.alpha(Theme.text, 0.06)
    // the same faint edge as the tiles beside it
    border.width: 1
    border.color: Theme.alpha(Theme.text, 0.05)
    clip: true

    Rectangle {
        width: Math.max(parent.height, parent.width * root.shown)
        height: parent.height
        radius: height / 2
        opacity: root.muted ? 0.35 : 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: root.from }
            GradientStop { position: 1; color: root.to }
        }
        Behavior on width { enabled: !drag.pressed; Anim { duration: Theme.durShort } }

        // the handle: a short bar, half the slider's height, inside the fill (hidden while
        // the fill is just the circle under the icon, where it read as a stray line)
        Rectangle {
            visible: parent.width > root.height + 6
            anchors.right: parent.right
            anchors.rightMargin: Math.round(root.height * 0.22)
            anchors.verticalCenter: parent.verticalCenter
            width: 4
            height: Math.round(root.height * 0.45)
            radius: 2
            color: Theme.onAccent
            opacity: drag.pressed ? 0.95 : 0.7
            Behavior on opacity { Anim { duration: Theme.durShort } }
        }
    }

    MouseArea {
        id: drag
        property real live: 0
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        function at(x) {
            return Math.max(0, Math.min(1, x / width));
        }
        onPressed: mouse => {
            live = at(mouse.x);
            root.moved(live);
        }
        onPositionChanged: mouse => {
            if (pressed) {
                live = at(mouse.x);
                root.moved(live);
            }
        }
        onWheel: wheel => root.moved(Math.max(0, Math.min(1, root.value + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))))
    }

    FIconButton {
        anchors.left: parent.left
        anchors.leftMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        size: 32
        icon: root.icon
        iconColor: root.shown > 0.12 ? Theme.onAccent : Theme.text
        onClicked: root.iconClicked()
    }

    FText {
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        text: root.muted ? "Muted" : Math.round(root.shown * 100) + "%"
        font.pixelSize: Theme.fsSm
        font.weight: Font.DemiBold
        color: root.shown > 0.9 ? Theme.onAccent : Theme.text
    }
}
