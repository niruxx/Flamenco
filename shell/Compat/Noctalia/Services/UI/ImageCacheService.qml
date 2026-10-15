pragma Singleton

import QtQuick
import Quickshell

// Flamenco shim for Noctalia's ImageCacheService: no cache, images load directly.
Singleton {
    readonly property bool initialized: true
    readonly property string wpThumbDir: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/flamenco/noctalia/thumbs/"
    readonly property var basicImageFilters: ["*.jpg", "*.jpeg", "*.png", "*.gif", "*.bmp", "*.webp"]

    function getLarge(path, callback) {
        if (callback)
            callback(path, true);
        return path;
    }
    function getThumbnail(path, callback) {
        return getLarge(path, callback);
    }
}
