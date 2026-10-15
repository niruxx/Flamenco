import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Commons
import qs.Services
import qs.Widgets

// A window in the overview: its picture where the compositor can capture it
// (else its app icon), the app icon as a badge and its title underneath.
// Click to go to it, middle-click or × to close it, drag it onto a workspace
// thumbnail to move it there.
Item {
    id: card

    property var winData
    property var overview
    property bool selected: false
    property bool previews: true
    property bool shown: false
    readonly property bool hovered: mouse.containsMouse || closeBtn.hovered
    readonly property int labelH: 30

    // Pictures only while the overview shows, and never in a nested niri (its output is
    // "winit"): capturing asks for dmabuf feedback, which nested niri's old dmabuf
    // version doesn't have, and the compositor then drops the whole shell.
    readonly property bool nested: Quickshell.screens.some(s => s.name === "winit")
    readonly property bool capture: previews && shown && !nested
    // the toplevel with this app id and title, for its picture
    readonly property var toplevel: capture ? (ToplevelManager.toplevels.values.find(t => t.appId === winData.app_id && t.title === winData.title) ?? null) : null
    readonly property bool hasPicture: pic.item?.hasContent ?? false
    readonly property real shape: {
        const s = winData.layout?.window_size;
        if (s && s[1] > 0)
            return s[0] / s[1];
        return hasPicture && pic.item.sourceSize.height > 0 ? pic.item.sourceSize.width / pic.item.sourceSize.height : 1.6;
    }
    readonly property real boxW: Math.max(40, Math.min(width, (height - labelH) * shape))
    readonly property real boxH: boxW / shape

    // a fresh picture each time the overview opens
    onShownChanged: if (shown && pic.item?.captureSource) pic.item.captureFrame()

    function home() {
        body.x = Qt.binding(() => (card.width - body.width) / 2);
        body.y = Qt.binding(() => (card.height - card.labelH - body.height) / 2);
    }

    Item {
        id: body
        property var winData: card.winData       // read by the workspace it's dropped on
        width: card.boxW
        height: card.boxH
        x: (card.width - width) / 2
        y: (card.height - card.labelH - height) / 2
        z: mouse.drag.active ? 10 : 0
        scale: mouse.drag.active ? 0.5 : card.hovered && Theme.hoverZoom ? 1.03 : 1
        Behavior on scale { Anim { easing.bezierCurve: Theme.curves.springFast } }
        Drag.active: mouse.drag.active
        Drag.keys: ["flamenco-window"]
        Drag.source: body
        Drag.hotSpot.x: width / 2
        Drag.hotSpot.y: height / 2

        ClippingRectangle {
            anchors.fill: parent
            radius: Theme.rLg
            color: Theme.alpha(Theme.surface, 0.92)

            Loader {
                id: pic
                anchors.fill: parent
                active: card.toplevel !== null
                sourceComponent: ScreencopyView {
                    captureSource: card.toplevel
                    live: false
                    visible: hasContent
                }
            }
            AppIcon {
                anchors.centerIn: parent
                visible: !card.hasPicture
                implicitSize: Math.min(96, Math.max(32, card.boxH * 0.4))
                name: Apps.iconFor(card.winData.app_id)
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: Theme.rLg
            color: "transparent"
            border.width: card.selected || card.hovered ? 3 : 1
            border.color: card.selected || card.hovered ? Theme.accent : Qt.rgba(1, 1, 1, 0.14)
            Behavior on border.color { CAnim {} }
        }

        // the app's icon over the bottom edge, like GNOME
        AppIcon {
            visible: card.hasPicture
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.bottom
            implicitSize: Math.min(48, Math.max(24, card.boxH * 0.18))
            name: Apps.iconFor(card.winData.app_id)
        }

        MouseArea {
            id: mouse
            property bool moved: false
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            drag.target: body
            drag.threshold: 12
            onPressed: moved = false
            drag.onActiveChanged: if (drag.active) moved = true
            onReleased: {
                if (moved)
                    body.Drag.drop();
                card.home();
            }
            onClicked: event => {
                if (moved)
                    return;
                if (event.button === Qt.MiddleButton)
                    Niri.closeWindow(card.winData.id);
                else
                    card.overview.openWindow(card.winData);
            }
        }

        FIconButton {
            id: closeBtn
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: -8
            size: 30
            icon: "close"
            flat: false
            opacity: card.hovered && !mouse.drag.active ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { Anim { duration: Theme.durShort } }
            onClicked: Niri.closeWindow(card.winData.id)
        }
    }

    FText {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width, Math.max(card.boxW, 160))
        height: card.labelH - 6
        verticalAlignment: Text.AlignBottom
        horizontalAlignment: Text.AlignHCenter
        text: card.winData.title || card.winData.app_id || ""
        color: "white"
        elide: Text.ElideRight
        font.pixelSize: Theme.fsSm
        font.weight: card.selected ? Font.DemiBold : Font.Normal
        opacity: card.hovered || card.selected ? 1 : 0.75
    }
}
