import QtQuick
import qs.Commons

// A history as a line with a soft fill under it and a dot on the newest value.
Canvas {
    id: root

    property var values: []
    property real max: 1                 // the top of the graph (0 = the largest value)
    property int slots: 60
    property color color: Theme.accent

    implicitHeight: 40
    onValuesChanged: requestPaint()
    onColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const v = values.slice(-slots);
        if (v.length < 2)
            return;
        const top = max > 0 ? max : Math.max(...v, 1e-9);
        const step = width / (slots - 1);
        const x0 = width - (v.length - 1) * step;
        const y = val => height - 3 - Math.max(0, Math.min(1, val / top)) * (height - 6);
        ctx.beginPath();
        v.forEach((val, i) => i === 0 ? ctx.moveTo(x0, y(val)) : ctx.lineTo(x0 + i * step, y(val)));
        ctx.lineWidth = 2;
        ctx.lineJoin = "round";
        ctx.strokeStyle = color;
        ctx.stroke();
        // fill under it
        ctx.lineTo(width, height);
        ctx.lineTo(x0, height);
        ctx.closePath();
        const g = ctx.createLinearGradient(0, 0, 0, height);
        g.addColorStop(0, Qt.rgba(color.r, color.g, color.b, 0.28));
        g.addColorStop(1, Qt.rgba(color.r, color.g, color.b, 0));
        ctx.fillStyle = g;
        ctx.fill();
        // the newest value
        ctx.beginPath();
        ctx.arc(width - 3, y(v[v.length - 1]), 3, 0, Math.PI * 2);
        ctx.fillStyle = color;
        ctx.fill();
    }
}
