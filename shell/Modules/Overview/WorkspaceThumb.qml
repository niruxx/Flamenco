import QtQuick
import Quickshell.Widgets
import qs.Commons
import qs.Services
import qs.Widgets

// A workspace along the top of the overview: the wallpaper and the icons of
// its windows. Click to switch to it; drop a window on it to move it there.
Item {
    id: thumb

    property var ws
    property string wallpaper
    readonly property var wins: Niri.windowsOn(ws.id)
    readonly property bool active: !!ws.is_active
    readonly property int iconSize: Math.max(16, Math.min(32, height * 0.3))
    readonly property int fits: Math.max(1, Math.floor((width - 16) / (iconSize + 4)))

    scale: drop.containsDrag ? 1.08 : mouse.containsMouse && Theme.hoverZoom ? 1.04 : 1
    Behavior on scale { Anim { easing.bezierCurve: Theme.curves.springFast } }

    ClippingRectangle {
        anchors.fill: parent
        radius: Theme.rMd
        color: Theme.surface

        Image {
            anchors.fill: parent
            source: thumb.wallpaper
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(Math.max(1, width * 2), Math.max(1, height * 2))
            asynchronous: true
        }
        Rectangle {
            anchors.fill: parent
            color: Theme.alpha(Theme.shadow, thumb.active ? 0.1 : 0.3)
        }
        Row {
            anchors.centerIn: parent
            spacing: 4
            Repeater {
                model: thumb.wins.slice(0, thumb.wins.length > thumb.fits ? thumb.fits - 1 : thumb.fits)
                AppIcon {
                    required property var modelData
                    implicitSize: thumb.iconSize
                    name: Apps.iconFor(modelData.app_id)
                }
            }
            FText {
                visible: thumb.wins.length > thumb.fits
                anchors.verticalCenter: parent.verticalCenter
                text: "+" + (thumb.wins.length - thumb.fits + 1)
                color: "white"
                font.weight: Font.DemiBold
            }
        }
        FText {
            visible: !!thumb.ws.name
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: 6
            text: thumb.ws.name ?? ""
            color: "white"
            font.pixelSize: Theme.fsXs
            font.weight: Font.DemiBold
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.rMd
        color: "transparent"
        border.width: thumb.active || drop.containsDrag ? 3 : 1
        border.color: thumb.active || drop.containsDrag ? Theme.accent : Qt.rgba(1, 1, 1, mouse.containsMouse ? 0.4 : 0.15)
        Behavior on border.color { CAnim {} }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Niri.focusWorkspace(thumb.ws)
    }

    DropArea {
        id: drop
        anchors.fill: parent
        keys: ["flamenco-window"]
        onDropped: d => {
            const w = d.source?.winData;
            if (w && w.workspace_id !== thumb.ws.id)
                Niri.moveWindowToWorkspace(w, thumb.ws);
            d.accept();
        }
    }
}
