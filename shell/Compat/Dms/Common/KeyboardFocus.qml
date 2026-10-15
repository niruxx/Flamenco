pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland

// Flamenco shim for DMS's KeyboardFocus.
Singleton {
    function keyboardFocus(active, customFocus) {
        if (customFocus !== null && customFocus !== undefined)
            return customFocus;
        return active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None;
    }
    function wantsGrab(active, customFocus) {
        return false;
    }
    function captureActiveToplevel() {
        return ToplevelManager.activeToplevel;
    }
    function restoreToplevel(toplevel) {
        if (toplevel)
            Qt.callLater(() => toplevel.activate());
        return null;
    }
    function registerBarWindow(window) {}
    function unregisterBarWindow(window) {}
}
