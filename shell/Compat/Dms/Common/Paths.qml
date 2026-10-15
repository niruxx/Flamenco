pragma Singleton

import QtQuick
import Quickshell
import qs.Commons as F

// Flamenco shim for DMS's Paths.
Singleton {
    readonly property string homeDir: Quickshell.env("HOME")
    readonly property url home: "file://" + homeDir
    readonly property url config: "file://" + (Quickshell.env("XDG_CONFIG_HOME") || homeDir + "/.config")
    readonly property url data: "file://" + (Quickshell.env("XDG_DATA_HOME") || homeDir + "/.local/share")
    readonly property url xdgCache: "file://" + (Quickshell.env("XDG_CACHE_HOME") || homeDir + "/.cache")
    readonly property url state: "file://" + (Quickshell.env("XDG_STATE_HOME") || homeDir + "/.local/state")
    readonly property url pictures: "file://" + homeDir + "/Pictures"
    readonly property string cache: strip(xdgCache) + "/flamenco/dms"

    function stringify(path) {
        return String(path).replace(/%20/g, " ");
    }
    function expandTilde(path) {
        const s = String(path);
        return s.startsWith("~") ? homeDir + s.slice(1) : s;
    }
    function shortenHome(path) {
        const s = String(path);
        return s.startsWith(homeDir) ? "~" + s.slice(homeDir.length) : s;
    }
    function strip(path) {
        return stringify(path).replace("file://", "");
    }
    function toFileUrl(path) {
        const s = String(path);
        return s.startsWith("file://") ? s : "file://" + expandTilde(s);
    }
    function mkdir(path) {
        Quickshell.execDetached(["mkdir", "-p", strip(path)]);
    }
    function copy(from, to) {
        Quickshell.execDetached(["cp", strip(from), strip(to)]);
    }
    function moddedAppId(appId) {
        return appId;
    }
    function resolveIconPath(name) {
        return Quickshell.iconPath(name, true);
    }
}
