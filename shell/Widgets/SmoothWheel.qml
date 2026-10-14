import QtQuick

// Wheel and touchpad scrolling with momentum for a Flickable, ListView or GridView.
// Put it inside the view: SmoothWheel { view: myList }
//  - a wheel notch glides to its target instead of jumping
//  - a fast wheel spin keeps going a little after the last notch and slows down
//  - touchpad scrolling follows the fingers 1:1 while they're down; a swipe keeps
//    going after they lift, and a strong one overshoots the end and springs back
//
// The wheel moves a target (goal) and the view eases toward it every frame. That
// matters for fast wheels: they send events faster than the screen redraws, and
// restarting an animation on each one kept it from ever taking a step, so the
// list stalled while the wheel spun and only caught up after it stopped.
WheelHandler {
    id: root

    required property Flickable view
    property real step: 110             // pixels per wheel notch
    property real ease: 0.075           // seconds: how quickly the view catches up with the wheel
    property real wheelCarry: 0.55      // how much of a wheel spin's speed carries on
    property real touchCarry: 1.0       // same for a touchpad swipe

    target: null
    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad

    property real goal: 0
    property bool chasing: false
    property real lastY: 0              // where the view was left, to notice someone else moving it
    property var samples: []            // [ms, pixels, touchpad] of recent events

    function lo() { return view.originY - view.topMargin; }
    function hi() { return Math.max(lo(), view.originY + view.contentHeight + view.bottomMargin - view.height); }
    function clamp(y) { return Math.max(lo(), Math.min(hi(), y)); }

    // stop any glide or momentum, e.g. when the scrollbar is grabbed
    function halt() {
        chasing = false;
        settle.stop();
        samples = [];
        view.cancelFlick();
    }

    // the wheel or fingers stopped: carry on with the recent speed, if it was fast
    function release() {
        settle.stop();
        const recent = samples;
        samples = [];
        if (recent.length < 3)
            return;
        const last = recent[recent.length - 1];
        const first = recent[0];
        const span = Math.max(16, last[0] - first[0]);
        let dist = 0;
        for (let i = 1; i < recent.length; i++)
            dist += recent[i][1];
        const v = dist / span * 1000 * (last[2] ? touchCarry : wheelCarry);
        if (Math.abs(v) < 350)
            return;
        if (last[2]) {
            // touchpad: Flickable's own fling, which can overshoot and spring back.
            // Its velocity is in drag direction: positive moves content down (contentY falls)
            chasing = false;
            const cap = view.maximumFlickVelocity;
            view.flick(0, -Math.max(-cap, Math.min(cap, v)));
        } else {
            // wheel: push the target a bit further, the same glide carries on there
            goal = clamp(goal + v * 0.12);
            lastY = view.contentY;
            chasing = true;
        }
    }

    onWheel: event => scroll(event)

    // also usable from a MouseArea's onWheel (e.g. a scrollbar on top of the view)
    function scroll(event) {
        if (!view.interactive || view.contentHeight <= view.height)
            return;
        const touch = event.pixelDelta.y !== 0;
        const d = touch ? -event.pixelDelta.y : -event.angleDelta.y / 120 * step;
        if (d === 0) {
            // touchpad fingers lifted (scroll end) or a purely sideways event
            if (event.angleDelta.x === 0 && event.pixelDelta.x === 0)
                release();
            return;
        }
        const now = Date.now();
        if (view.flicking)
            view.cancelFlick();
        // keep ~100 ms of history, and start over on a change of direction
        samples = samples.filter(s => now - s[0] < 100 && (s[1] > 0) === (d > 0)).concat([[now, d, touch]]);

        if (touch) {
            chasing = false;
            view.contentY = clamp(view.contentY + d);
            goal = view.contentY;
        } else {
            // a change of direction turns around from where the view is, not from the old target
            const from = chasing && (goal - view.contentY > 0) === (d > 0) ? goal : view.contentY;
            goal = clamp(from + d);
            lastY = view.contentY;
            chasing = true;
        }
        settle.interval = touch ? 90 : 60;
        settle.restart();
    }

    // a handler has no default property, so its helpers hang off properties
    property Timer settle: Timer {
        onTriggered: root.release()
    }

    // eases the view toward the goal once per frame
    property FrameAnimation tick: FrameAnimation {
        running: root.chasing
        onTriggered: {
            const v = root.view;
            // dragged, or moved by code (keyboard navigation): let go
            if (v.dragging || Math.abs(v.contentY - root.lastY) > 1) {
                root.chasing = false;
                return;
            }
            const g = root.clamp(root.goal);
            const left = g - v.contentY;
            if (Math.abs(left) < 0.5) {
                v.contentY = g;
                root.chasing = false;
                return;
            }
            const dt = Math.min(Math.max(frameTime, 0.001), 0.05);
            v.contentY += left * (1 - Math.exp(-dt / root.ease));
            root.lastY = v.contentY;
        }
    }
}
