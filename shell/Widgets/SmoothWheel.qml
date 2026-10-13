import QtQuick

// Wheel and touchpad scrolling with momentum for a Flickable, ListView or GridView.
// Put it inside the view: SmoothWheel { view: myList }
//  - a wheel notch glides to its target instead of jumping
//  - a fast wheel spin or a touchpad swipe keeps going after the last event and
//    slows down; a strong one overshoots the end a little and springs back
//  - touchpad scrolling follows the fingers 1:1 while they're down
WheelHandler {
    id: root

    required property Flickable view
    property real step: 110             // pixels per wheel notch
    property real wheelCarry: 0.55      // how much of a wheel spin's speed carries on
    property real touchCarry: 1.0       // same for a touchpad swipe

    target: null
    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad

    property real goal: 0
    property var samples: []            // [ms, pixels, touchpad] of recent events

    function lo() { return view.originY - view.topMargin; }
    function hi() { return Math.max(lo(), view.originY + view.contentHeight + view.bottomMargin - view.height); }
    function clamp(y) { return Math.max(lo(), Math.min(hi(), y)); }

    // stop any glide or momentum, e.g. when the scrollbar is grabbed
    function halt() {
        glide.stop();
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
        glide.stop();
        // Flickable velocity is in drag direction: positive moves content down (contentY falls)
        const cap = view.maximumFlickVelocity;
        view.flick(0, -Math.max(-cap, Math.min(cap, v)));
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
            glide.stop();
            view.contentY = clamp(view.contentY + d);
            goal = view.contentY;
        } else {
            goal = clamp((glide.running ? goal : view.contentY) + d);
            glide.to = goal;
            glide.restart();
        }
        settle.interval = touch ? 90 : 60;
        settle.restart();
    }

    // a handler has no default property, so its helpers hang off properties
    property Timer settle: Timer {
        onTriggered: root.release()
    }

    property NumberAnimation glide: NumberAnimation {
        target: root.view
        property: "contentY"
        duration: 280
        easing.type: Easing.OutCubic
    }
}
