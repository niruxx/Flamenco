pragma Singleton

import QtQuick
import Quickshell
import qs.Services as FS

// Flamenco shim for Noctalia's CompositorService, from Flamenco's niri/Hyprland state.
Singleton {
    id: root

    readonly property bool isNiri: !FS.Niri.hyprland
    readonly property bool isHyprland: FS.Niri.hyprland
    readonly property bool isSway: false
    readonly property bool isMango: false
    readonly property bool isLabwc: false
    readonly property bool overviewActive: FS.Niri.overviewOpen
    // Noctalia's shape: { id, idx, name, output, isActive, isFocused, isUrgent }
    readonly property var workspaces: FS.Niri.workspaces.map(w => ({ id: w.id, idx: w.idx, name: w.name || "", output: w.output, isActive: !!w.is_active, isFocused: !!w.is_focused, isUrgent: !!w.is_urgent, isOccupied: FS.Niri.windows.some(x => x.workspace_id === w.id) }))
    readonly property var windows: FS.Niri.windows.map(w => ({ id: w.id, title: w.title || "", appId: w.app_id || "", workspaceId: w.workspace_id, isFocused: !!w.is_focused }))
    readonly property var focusedWindow: windows.find(w => w.isFocused) ?? null
    readonly property string focusedScreen: FS.Niri.focusedOutput

    function getDisplayScale(screenName) {
        const s = Quickshell.screens.find(x => x.name === screenName);
        return s?.devicePixelRatio ?? 1;
    }
    function switchToWorkspace(ws) {
        const w = FS.Niri.workspaces.find(x => x.id === (ws?.id ?? ws));
        if (w)
            FS.Niri.focusWorkspace(w);
    }
    function focusWindow(win) {
        FS.Niri.focusWindow(win?.id ?? win);
    }
    function closeWindow(win) {
        FS.Niri.closeWindow(win?.id ?? win);
    }
    function spawn(command) {
        Quickshell.execDetached(Array.isArray(command) ? command : ["sh", "-c", String(command)]);
    }
    function logout() {
        FS.Power.logout();
    }
}
