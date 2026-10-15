pragma Singleton

import QtQuick
import Quickshell
import qs.Services as FS

// Flamenco shim for Noctalia's WallpaperService, on Flamenco's wallpapers.
Singleton {
    id: root

    readonly property bool isInitialized: true
    readonly property var currentWallpapers: {
        const out = {};
        for (const s of Quickshell.screens)
            out[s.name] = FS.Wallpapers.forScreen(s.name);
        return out;
    }
    readonly property string noctaliaDefaultWallpaper: ""
    readonly property var allTransitions: ["fade"]
    signal wallpaperChanged(string screenName, string path)
    signal wallpaperProcessingComplete(string screenName, string path, string cachedPath)

    function getWallpaper(screenName) {
        return FS.Wallpapers.forScreen(screenName || "");
    }
    function changeWallpaper(path, screenName) {
        FS.Wallpapers.set(String(path), screenName || "");
        wallpaperChanged(screenName || "", String(path));
    }
    function isSolidColorPath(path) {
        return String(path).startsWith("solid://");
    }
    function getSolidColor(path) {
        return String(path).replace("solid://", "");
    }
    function createSolidColorPath(color) {
        return "solid://" + color;
    }
    function getFillModeUniform() {
        return 1;
    }
}
