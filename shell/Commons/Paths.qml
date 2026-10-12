pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME") || ""
    readonly property string user: Quickshell.env("USER") || "user"
    readonly property string configDir: (Quickshell.env("XDG_CONFIG_HOME") || home + "/.config") + "/flamenco"
    readonly property string cacheDir: (Quickshell.env("XDG_CACHE_HOME") || home + "/.cache") + "/flamenco"
    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || home + "/.local/state") + "/flamenco"

    // Path to the `flamenco` CLI, exported by `flamenco run`.
    readonly property string bin: Quickshell.env("FLAMENCO_BIN") || "flamenco"

    function expand(path) {
        if (!path)
            return "";
        return String(path).replace(/^~(?=\/|$)/, home);
    }

    function toUrl(path) {
        if (!path)
            return "";
        const p = expand(path);
        return p.startsWith("file://") || p.startsWith("image://") ? p : "file://" + p;
    }

    function fileName(path) {
        return String(path).split("/").pop();
    }
}
