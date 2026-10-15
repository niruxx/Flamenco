pragma Singleton

import QtQuick
import Quickshell
import qs.Services as FS

// Flamenco shim for DMS's CompositorService.
Singleton {
    readonly property bool isNiri: !FS.Niri.hyprland
    readonly property bool isHyprland: FS.Niri.hyprland
    readonly property bool isSway: false
    readonly property bool isMango: false
    readonly property bool isLabwc: false
    readonly property bool useHyprlandFocusGrab: false
    readonly property string compositor: FS.Niri.compositor

    function getFocusedScreen() {
        return Quickshell.screens.find(s => s.name === FS.Niri.focusedOutput) ?? Quickshell.screens[0] ?? null;
    }
    function getScreenScale(screen) {
        return screen?.devicePixelRatio ?? 1;
    }
    function fullscreenToplevelOnScreen(screen) {
        return null;
    }
    function framePeerSurfacesUseOverlayForScreen(screen) {
        return false;
    }
    function powerOffMonitors() {
        FS.Niri.action("power-off-monitors");
    }
}
