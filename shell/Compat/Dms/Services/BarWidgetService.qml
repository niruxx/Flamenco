pragma Singleton

import QtQuick
import Quickshell
import qs.Services as FS

// Flamenco shim for DMS's BarWidgetService.
Singleton {
    function getRegisteredWidgetIds() {
        return [];
    }
    function getWidget(id) {
        return null;
    }
    function getFocusedScreenName() {
        return FS.Niri.focusedOutput;
    }
    function triggerWidgetPopout(id) {}
}
