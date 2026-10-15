import QtQuick
import qs.Commons
import qs.Widgets

// A ring gauge with its value inside and a label under it (System card).
Column {
    id: root

    property real value: 0                 // 0–1
    property string text
    property string label
    property color color: Theme.accent2
    property int size: 56
    spacing: 4

    Item {
        width: root.size
        height: root.size
        anchors.horizontalCenter: parent.horizontalCenter

        Canvas {
            id: arc
            anchors.fill: parent
            readonly property real v: Math.max(0, Math.min(1, root.value))
            readonly property color fillColor: v > 0.85 ? Theme.error : root.color
            readonly property color track: Theme.alpha(Theme.text, 0.12)
            onVChanged: requestPaint()
            onFillColorChanged: requestPaint()
            onTrackChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const c = width / 2, r = c - 3.5;
                ctx.lineWidth = 4;
                ctx.lineCap = "round";
                ctx.strokeStyle = track;
                ctx.beginPath();
                ctx.arc(c, c, r, 0, Math.PI * 2);
                ctx.stroke();
                if (v > 0) {
                    ctx.strokeStyle = fillColor;
                    ctx.beginPath();
                    ctx.arc(c, c, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * v);
                    ctx.stroke();
                }
            }
        }
        FText {
            anchors.centerIn: parent
            text: root.text
            font.pixelSize: Theme.fsXs
            font.weight: Font.Bold
        }
    }
    FText {
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.label
        font.pixelSize: Theme.fsXs
        font.weight: Font.DemiBold
        dim: true
    }
}
