import QtQuick

// Turns wheel events into whole steps, for things that move one step per notch
// (workspaces, volume, months…). A mouse wheel notch is one step; a touchpad or a
// free-spinning wheel sends lots of small events, which add up to a step instead
// of each being one (a light swipe used to fly through several workspaces).
//   WheelSteps { id: notches }
//   onWheel: e => { const n = notches.take(e); if (n) … }     // n > 0: up
QtObject {
    property bool sideways: false         // count sideways scrolling too (right = down)
    property real acc: 0
    property real last: 0

    function take(event) {
        const d = event.angleDelta.y !== 0 ? event.angleDelta.y : sideways ? -event.angleDelta.x : 0;
        if (d === 0)
            return 0;
        const now = Date.now();
        // a pause or a change of direction starts over
        if (now - last > 400 || (d > 0) !== (acc > 0))
            acc = 0;
        last = now;
        acc += d;
        const n = acc > 0 ? Math.floor(acc / 120) : Math.ceil(acc / 120);
        acc -= n * 120;
        return n;
    }
}
