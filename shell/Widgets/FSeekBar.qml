import QtQuick
import qs.Commons

// Media seek bar: click to jump, or drag and release to seek. While dragging,
// a bubble shows the time you'll land on; the player is only told on release.
Item {
    id: root

    property real position: 0        // seconds
    property real length: 0          // seconds
    property bool seekable: true
    property color accent: Theme.accent
    signal seek(real fraction)

    readonly property bool dragging: area.pressed && seekable
    property real dragFrac: 0
    readonly property real frac: length > 0 ? Math.max(0, Math.min(1, position / length)) : 0
    readonly property real shown: dragging ? dragFrac : frac
    readonly property bool hot: area.containsMouse || dragging

    function fmt(sec) {
        sec = Math.max(0, Math.floor(sec));
        const h = Math.floor(sec / 3600), m = Math.floor(sec % 3600 / 60), s = sec % 60;
        return (h > 0 ? h + ":" + String(m).padStart(2, "0") : m) + ":" + String(s).padStart(2, "0");
    }

    implicitHeight: 20
    implicitWidth: 200

    // track
    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: root.hot ? 8 : 5
        radius: height / 2
        color: Theme.alpha(Theme.text, 0.15)
        Behavior on height { Anim { duration: Theme.durShort } }

        Rectangle {
            height: parent.height
            radius: parent.radius
            width: Math.max(height, parent.width * root.shown)
            color: root.accent
            // follow playback smoothly, but track the pointer exactly while dragging
            Behavior on width {
                enabled: !root.dragging
                Anim { duration: 900; easing.type: Easing.Linear }
            }
        }
    }

    // knob
    Rectangle {
        visible: root.seekable
        width: root.dragging ? 18 : 14
        height: width
        radius: width / 2
        x: track.width * root.shown - width / 2
        anchors.verticalCenter: parent.verticalCenter
        color: root.accent
        border.width: 2
        border.color: Theme.surface
        opacity: root.hot ? 1 : 0
        scale: root.hot ? 1 : 0.4
        Behavior on opacity { Anim { duration: Theme.durShort } }
        Behavior on scale { Anim { duration: Theme.durShort; easing.bezierCurve: Theme.curves.springFast } }
        Behavior on width { Anim { duration: Theme.durShort } }
    }

    // time bubble while dragging
    Rectangle {
        visible: root.dragging
        width: bubble.implicitWidth + 14
        height: 22
        radius: 11
        y: -height - 6
        x: Math.max(0, Math.min(root.width - width, track.width * root.shown - width / 2))
        color: Theme.surfaceHighest
        border.width: 1
        border.color: Theme.border
        FText {
            id: bubble
            anchors.centerIn: parent
            text: root.fmt(root.dragFrac * root.length)
            mono: true
            font.pixelSize: Theme.fsXs
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        anchors.topMargin: -6
        anchors.bottomMargin: -6
        hoverEnabled: true
        preventStealing: true
        enabled: root.seekable && root.length > 0
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

        function fracAt(x) {
            return Math.max(0, Math.min(1, x / Math.max(1, root.width)));
        }
        onPressed: mouse => root.dragFrac = fracAt(mouse.x)
        onPositionChanged: mouse => {
            if (pressed)
                root.dragFrac = fracAt(mouse.x);
        }
        onReleased: mouse => root.seek(fracAt(mouse.x))
    }
}
