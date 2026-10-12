import QtQuick
import Quickshell
import qs.Commons
import qs.Widgets

// Small themed tooltip shown after a short hover delay.
PopupWindow {
    id: root

    required property var window
    property string title: ""
    property string body: ""
    property rect at: Qt.rect(0, 0, 1, 1)

    function showFor(t, b, rect) {
        title = t || "";
        body = (b || "").replace(/<[^>]*>/g, "");
        at = rect;
        if (title !== "")
            delay.restart();
    }

    function hide() {
        delay.stop();
        visible = false;
    }

    Timer {
        id: delay
        interval: 550
        onTriggered: root.visible = true
    }

    readonly property int gap: 8
    anchor.window: window
    anchor.rect.x: Theme.barPos === "right" ? at.x - gap : Theme.barPos === "left" ? at.x + at.width + gap : at.x + at.width / 2
    anchor.rect.y: Theme.barPos === "bottom" ? at.y - gap : Theme.barVertical ? at.y + at.height / 2 : at.y + at.height + gap
    anchor.rect.width: 1
    anchor.rect.height: 1
    anchor.edges: Theme.barPos === "bottom" ? Edges.Top : Theme.barPos === "left" ? Edges.Right : Theme.barPos === "right" ? Edges.Left : Edges.Bottom
    anchor.gravity: anchor.edges
    color: "transparent"
    visible: false

    implicitWidth: Math.min(320, col.implicitWidth + 20)
    implicitHeight: col.implicitHeight + 12

    Rectangle {
        anchors.fill: parent
        radius: Theme.rSm
        color: Theme.surfaceHighest
        border.width: 1
        border.color: Theme.alpha(Theme.border, 0.7)

        Column {
            id: col
            anchors.centerIn: parent
            width: Math.min(300, Math.max(t1.implicitWidth, t2.visible ? t2.implicitWidth : 0))
            spacing: 2
            FText {
                id: t1
                width: parent.width
                text: root.title
                font.pixelSize: Theme.fsSm
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            FText {
                id: t2
                width: parent.width
                visible: text !== ""
                text: root.body
                dim: true
                font.pixelSize: Theme.fsXs
                wrapMode: Text.Wrap
                maximumLineCount: 4
            }
        }
    }
}
