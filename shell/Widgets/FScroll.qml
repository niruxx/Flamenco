import QtQuick
import qs.Commons

// Flickable with a draggable scrollbar: grab the handle, or click the track
// to jump there and keep dragging. Mouse wheel and touchpad work as usual.
Flickable {
    id: root

    clip: true
    boundsBehavior: Flickable.StopAtBounds
    contentWidth: width
    flickDeceleration: 4000

    readonly property bool scrollable: contentHeight > height + 1
    readonly property real maxY: Math.max(0, contentHeight - height)
    // room to leave on the right for the scrollbar, so content doesn't sit under it
    readonly property real gutter: scrollable ? track.width + 4 : 0

    Item {
        id: track
        parent: root
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: 14
        visible: root.scrollable
        z: 10

        readonly property bool active: bar.pressed || bar.containsMouse
        readonly property real handleH: Math.max(32, root.height * root.height / Math.max(1, root.contentHeight))

        // track background, shown while hovering / dragging
        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: 2
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.margins: 2
            width: 8
            radius: 4
            color: Theme.alpha(Theme.text, 0.08)
            opacity: track.active ? 1 : 0
            Behavior on opacity { Anim {} }
        }

        Rectangle {
            id: handle
            anchors.right: parent.right
            anchors.rightMargin: 2
            y: 2 + (root.maxY > 0 ? root.contentY / root.maxY : 0) * (track.height - 4 - track.handleH)
            width: track.active ? 8 : 4
            height: track.handleH
            radius: width / 2
            color: bar.pressed ? Theme.accent : Theme.textDim
            opacity: track.active ? 0.9 : root.moving ? 0.6 : 0.35

            Behavior on width { Anim { duration: Theme.durShort } }
            Behavior on opacity { Anim {} }
            Behavior on color { CAnim {} }
        }

        MouseArea {
            id: bar
            anchors.fill: parent
            hoverEnabled: true
            preventStealing: true
            cursorShape: Qt.ArrowCursor

            property real grab: 0      // where on the handle it was grabbed

            function scrollTo(mouseY) {
                const range = track.height - 4 - track.handleH;
                const f = range > 0 ? Math.max(0, Math.min(1, (mouseY - 2 - grab) / range)) : 0;
                root.contentY = f * root.maxY;
            }

            onPressed: mouse => {
                root.cancelFlick();
                const onHandle = mouse.y >= handle.y && mouse.y <= handle.y + handle.height;
                // clicking the track centers the handle under the pointer, then drags from there
                grab = onHandle ? mouse.y - handle.y : track.handleH / 2;
                if (!onHandle)
                    scrollTo(mouse.y);
            }
            onPositionChanged: mouse => {
                if (pressed)
                    scrollTo(mouse.y);
            }
            onWheel: wheel => {
                root.contentY = Math.max(0, Math.min(root.maxY, root.contentY - wheel.angleDelta.y));
            }
        }
    }
}
