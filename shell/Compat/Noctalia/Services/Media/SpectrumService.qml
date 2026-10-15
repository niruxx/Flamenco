pragma Singleton

import QtQuick
import Quickshell
import qs.Services as FS

// Flamenco shim for Noctalia's SpectrumService, on Flamenco's cava.
Singleton {
    id: root

    property var registered: ({})
    readonly property var values: FS.Cava.values
    readonly property bool isIdle: !FS.Cava.running || values.length === 0

    function registerComponent(id) {
        if (registered[id])
            return;
        registered[id] = true;
        FS.Cava.users++;
    }
    function unregisterComponent(id) {
        if (!registered[id])
            return;
        delete registered[id];
        FS.Cava.users = Math.max(0, FS.Cava.users - 1);
    }
}
