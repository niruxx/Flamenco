pragma Singleton

import QtQuick
import Quickshell
import qs.Services as FS

// Flamenco shim for DMS's NiriService.
Singleton {
    readonly property var allWorkspaces: FS.Niri.workspaces
    readonly property var windows: FS.Niri.windows
    readonly property bool inOverview: FS.Niri.overviewOpen
    readonly property var outputs: {
        const out = {};
        for (const s of Quickshell.screens)
            out[s.name] = { name: s.name, logical: { x: s.x, y: s.y, width: s.width, height: s.height, scale: s.devicePixelRatio } };
        return out;
    }
    function send(request) {}
    function switchToWorkspace(idx) {
        FS.Niri.action("focus-workspace", String(idx));
    }
    function focusWindow(id) {
        FS.Niri.focusWindow(id);
    }
}
