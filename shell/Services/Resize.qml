pragma Singleton

import QtQuick
import Quickshell
import qs.Commons

// The resize panel's window (Modules/Windows/ResizePanel): a way to size and place
// a window without grabbing its edges, for touchpads and apps without frames.
// Opened from a window's menu, or the "Resize the window" shortcut.
Singleton {
    id: root

    property var targetId: null
    readonly property var target: targetId === null ? null : (Niri.windows.find(w => w.id === targetId) ?? null)

    function open(id, screen) {
        targetId = id ?? Niri.focusedWindowId;
        if (targetId === null)
            return;
        Panels.open("resize", screen ?? "");
    }

    // niri's size changes: "50%", "+5%", "-40", "1200"
    function width(change) {
        if (target)
            Niri.action("set-window-width", "--id", String(target.id), change);
    }
    function height(change) {
        if (target)
            Niri.action("set-window-height", "--id", String(target.id), change);
    }
    function move(dx, dy) {
        if (target && target.is_floating)
            Niri.action("move-floating-window", "--id", String(target.id), "-x", (dx >= 0 ? "+" : "") + dx, "-y", (dy >= 0 ? "+" : "") + dy);
    }
    function center() {
        if (target)
            Niri.action("center-window", "--id", String(target.id));
    }
}
