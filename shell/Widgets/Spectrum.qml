import QtQuick
import qs.Commons
import qs.Services

// The audio visualizer, drawn (Settings → Sound → Audio visualizer). One look for
// the bar, the desktop widget, the dashboard and the big desktop band:
//   style   bars | mirror (from the middle) | wave | dots (LED columns) | radial | peaks (with falling caps)
//   colors  accent | palette | rainbow | fire | mono
//   motion  smooth | snappy | bouncy | gravity (rises at once, falls slowly)
// Feed it `values` (0–1, e.g. Cava.values); with none it rests (a gentle idle line).
Canvas {
    id: root

    property var values: Cava.values
    property int count: 24                    // how many bars (cava's are spread over them)
    property string style: Settings.data.visualizer.style || "bars"
    property string colors: Settings.data.visualizer.colors || "accent"
    property string motion: Settings.data.visualizer.motion || "smooth"
    property bool vertical: false             // a side bar: bars grow sideways
    property real gap: 0.28                   // the space between bars, as a share of each slot
    property bool active: true

    property var levels: []
    property var peaks: []
    property var speeds: []                   // bouncy: each bar's velocity
    readonly property bool resting: !values || values.length === 0
    // at rest and settled: no more frames until sound comes back (an idle visualizer costs nothing)
    property bool settled: false
    onValuesChanged: settled = false
    onCountChanged: settled = false
    onStyleChanged: requestPaint()
    onColorsChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    // the target of bar i: cava's bars spread over ours, in between ones blended
    function target(i) {
        if (resting)
            return 0.04;
        const t = i / Math.max(1, count - 1) * (values.length - 1);
        const a = Math.floor(t), b = Math.min(values.length - 1, a + 1);
        return Math.max(0, Math.min(1, values[a] + (values[b] - values[a]) * (t - a)));
    }
    // a bar's color, from its place along the visualizer (0–1) and its level
    function colorAt(t, v) {
        return String(colorOf(t, v));
    }
    function colorOf(t, v) {
        switch (colors) {
        case "rainbow":
            return Qt.hsla((0.95 - 0.8 * t) % 1, 0.75, 0.6, 1);
        case "fire":
            return Theme.mix(Theme.warning, Theme.error, Math.min(1, v * 1.2));
        case "mono":
            return Theme.alpha(Theme.text, 0.55 + 0.45 * v);
        case "palette":
            return t < 0.5 ? Theme.mix(Theme.accent, Theme.accent3, t * 2) : Theme.mix(Theme.accent3, Theme.warning, (t - 0.5) * 2);
        default:
            return Theme.mix(Theme.accent, Theme.accent2, t);
        }
    }

    // ── each frame: ease the levels toward the sound, then draw ──
    FrameAnimation {
        id: idle
        running: root.active && root.visible && root.width > 0 && !root.settled
        onTriggered: {
            const n = root.count, dt = Math.min(0.05, Math.max(0.001, frameTime));
            const lv = root.levels.length === n ? root.levels : new Array(n).fill(0);
            const pk = root.peaks.length === n ? root.peaks : new Array(n).fill(0);
            const sp = root.speeds.length === n ? root.speeds : new Array(n).fill(0);
            // per motion: how fast a bar rises and falls (per second, as a share of the gap)
            const up = root.motion === "snappy" ? 40 : root.motion === "gravity" ? 60 : 14;
            const down = root.motion === "snappy" ? 30 : root.motion === "gravity" ? 2.2 : 9;
            for (let i = 0; i < n; i++) {
                const t = root.target(i);
                if (root.motion === "bouncy") {
                    // a spring: overshoots a little, then settles
                    sp[i] += ((t - lv[i]) * 260 - sp[i] * 14) * dt;
                    lv[i] = Math.max(0, Math.min(1.1, lv[i] + sp[i] * dt));
                } else {
                    const k = 1 - Math.exp(-dt * (t > lv[i] ? up : down));
                    lv[i] += (t - lv[i]) * k;
                }
                // peaks: caught at once, then they drop
                pk[i] = lv[i] >= pk[i] ? lv[i] : Math.max(0, pk[i] - dt * 0.45);
            }
            root.levels = lv;
            root.peaks = pk;
            root.speeds = sp;
            if (root.resting && lv.every((v, i) => Math.abs(v - root.target(i)) < 0.003 && Math.abs(sp[i]) < 0.01) && pk.every(p => p < 0.06))
                root.settled = true;
            root.requestPaint();
        }
    }

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        let W = width, H = height;
        if (vertical) {
            // draw as if horizontal, turned a quarter
            ctx.translate(0, height);
            ctx.rotate(-Math.PI / 2);
            W = height;
            H = width;
        }
        const n = count, lv = levels;
        if (lv.length !== n || W <= 0 || H <= 0)
            return;
        const slot = W / n, bw = Math.max(1, slot * (1 - gap)), r = Math.min(bw / 2, 6);
        const bar = (x, y, w, h) => {
            if (h <= 0)
                return;
            const rr = Math.min(r, w / 2, h / 2);
            ctx.beginPath();
            ctx.moveTo(x + rr, y);
            ctx.arcTo(x + w, y, x + w, y + h, rr);
            ctx.arcTo(x + w, y + h, x, y + h, rr);
            ctx.arcTo(x, y + h, x, y, rr);
            ctx.arcTo(x, y, x + w, y, rr);
            ctx.closePath();
            ctx.fill();
        };
        const lvl = i => Math.max(0, Math.min(1, lv[i]));

        if (style === "wave") {
            // a filled curve through the levels, a brighter line along its top
            const pts = [];
            for (let i = 0; i < n; i++)
                pts.push([slot * (i + 0.5), H - Math.max(2, lvl(i) * (H - 4))]);
            const grad = ctx.createLinearGradient(0, 0, W, 0);
            grad.addColorStop(0, colorAt(0, 0.6));
            grad.addColorStop(0.5, colorAt(0.5, 0.6));
            grad.addColorStop(1, colorAt(1, 0.6));
            ctx.beginPath();
            ctx.moveTo(0, H);
            ctx.lineTo(0, pts[0][1]);
            for (let i = 0; i < n - 1; i++) {
                const mx = (pts[i][0] + pts[i + 1][0]) / 2, my = (pts[i][1] + pts[i + 1][1]) / 2;
                ctx.quadraticCurveTo(pts[i][0], pts[i][1], mx, my);
            }
            ctx.lineTo(W, pts[n - 1][1]);
            ctx.lineTo(W, H);
            ctx.closePath();
            ctx.globalAlpha = 0.35;
            ctx.fillStyle = grad;
            ctx.fill();
            ctx.globalAlpha = 1;
            ctx.beginPath();
            ctx.moveTo(0, pts[0][1]);
            for (let i = 0; i < n - 1; i++) {
                const mx = (pts[i][0] + pts[i + 1][0]) / 2, my = (pts[i][1] + pts[i + 1][1]) / 2;
                ctx.quadraticCurveTo(pts[i][0], pts[i][1], mx, my);
            }
            ctx.lineTo(W, pts[n - 1][1]);
            ctx.lineWidth = Math.max(2, H / 40);
            ctx.lineJoin = "round";
            ctx.strokeStyle = grad;
            ctx.stroke();
            return;
        }
        if (style === "radial") {
            // bars around a circle, from its edge outward
            const cx = W / 2, cy = H / 2, R = Math.min(W, H) * 0.24, room = Math.min(W, H) / 2 - R - 2;
            ctx.lineCap = "round";
            ctx.lineWidth = Math.max(2, Math.min(8, (2 * Math.PI * R / n) * 0.55));
            for (let i = 0; i < n; i++) {
                const a = -Math.PI / 2 + i / n * Math.PI * 2, len = 2 + lvl(i) * room;
                ctx.strokeStyle = colorAt(i / Math.max(1, n - 1), lvl(i));
                ctx.beginPath();
                ctx.moveTo(cx + Math.cos(a) * R, cy + Math.sin(a) * R);
                ctx.lineTo(cx + Math.cos(a) * (R + len), cy + Math.sin(a) * (R + len));
                ctx.stroke();
            }
            ctx.globalAlpha = 0.25;
            ctx.strokeStyle = colorAt(0.5, 0.5);
            ctx.lineWidth = 2;
            ctx.beginPath();
            ctx.arc(cx, cy, R - 4, 0, Math.PI * 2);
            ctx.stroke();
            return;
        }
        for (let i = 0; i < n; i++) {
            const t = i / Math.max(1, n - 1), v = lvl(i), x = slot * i + (slot - bw) / 2;
            ctx.fillStyle = colorAt(t, v);
            if (style === "mirror") {
                const h = Math.max(bw, v * H);
                bar(x, (H - h) / 2, bw, h);
            } else if (style === "dots") {
                // LED columns: lit cells up to the level
                const cell = Math.max(3, Math.min(bw, H / 10)), rows = Math.max(1, Math.floor(H / (cell * 1.35))), lit = Math.round(v * rows);
                for (let j = 0; j < rows; j++) {
                    ctx.globalAlpha = j < Math.max(1, lit) ? 1 : 0.12;
                    const y = H - (j + 1) * cell * 1.35 + cell * 0.35;
                    ctx.beginPath();
                    ctx.arc(x + bw / 2, y + cell / 2, Math.min(bw, cell) / 2, 0, Math.PI * 2);
                    ctx.fill();
                }
                ctx.globalAlpha = 1;
            } else {
                const h = Math.max(Math.min(bw, 4), v * H);
                bar(x, H - h, bw, h);
                if (style === "peaks") {
                    // the cap: where it just was, falling
                    const py = H - Math.max(h, peaks[i] * H) - 4;
                    ctx.globalAlpha = 0.9;
                    bar(x, Math.max(0, py), bw, 3);
                    ctx.globalAlpha = 1;
                }
            }
        }
    }
}
