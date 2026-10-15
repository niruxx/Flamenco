pragma Singleton

import QtQuick
import Quickshell
import qs.Commons

// The app switcher (Alt+Tab): the windows, most recent first, picked while Alt
// is held. `flamenco switcher next|prev` (Alt+Tab, Alt+Shift+Tab) open it or move
// along; letting go of Alt, Enter or a click goes there, Esc cancels.
Singleton {
    id: root

    property var list: []                 // the windows when it opened, in that order
    property int index: 0
    readonly property bool open: Panels.current === "switcher"
    readonly property var selected: list[index] ?? null

    function step(dir) {
        if (!open) {
            list = Niri.mru;
            if (list.length === 0)
                return;
            // the first press goes to the window before this one
            index = list.length > 1 ? (dir > 0 ? 1 : list.length - 1) : 0;
            Panels.open("switcher", "");
            return;
        }
        if (list.length)
            index = (index + dir + list.length) % list.length;
    }
    function activate() {
        const w = selected;
        Panels.close();
        if (w)
            Niri.focusWindow(w.id);
    }
    function cancel() {
        Panels.close();
    }
    // a window closed while it's open
    Connections {
        target: Niri
        function onWindowsChanged() {
            if (!root.open)
                return;
            root.list = root.list.filter(w => Niri.windows.some(x => x.id === w.id));
            root.index = Math.min(root.index, Math.max(0, root.list.length - 1));
            if (root.list.length === 0)
                root.cancel();
        }
    }
}
