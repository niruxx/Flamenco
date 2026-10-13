pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Singleton {
    id: root

    property var files: []
    readonly property var cfg: Settings.data.wallpaper
    readonly property string dir: Paths.normalize(cfg.dir)
    readonly property string current: Paths.expand(cfg.current)

    // scan state, for the folder field and the grid's empty message
    property bool scanning: scanner.running
    property string status: ""          // "" | "missing" | "empty" | "ok"
    property string scannedDir: ""
    property bool pending: false

    onDirChanged: rescan()
    Component.onCompleted: rescan()

    function setDir(path) {
        const p = Paths.normalize(path);
        if (!p)
            return;
        // store it the way the person would write it
        cfg.dir = p.startsWith(Paths.home + "/") ? "~" + p.slice(Paths.home.length) : p === Paths.home ? "~" : p;
    }

    function rescan() {
        if (!dir)
            return;
        // a scan is already running: run again for the latest folder when it ends
        if (scanner.running) {
            pending = true;
            return;
        }
        pending = false;
        scannedDir = dir;
        // `test -d` first so a missing folder is reported, not shown as "no images"
        scanner.command = ["sh", "-c", 'test -d "$1" || { echo "@missing"; exit 0; }; find -L "$1" -maxdepth 4 -type f \\( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.bmp" -o -iname "*.gif" -o -iname "*.avif" -o -iname "*.jxl" \\) 2>/dev/null', "sh", dir];
        scanner.running = true;
    }

    function set(path) {
        cfg.current = path;
    }

    function random() {
        const pool = files.filter(f => f !== current);
        if (pool.length > 0)
            set(pool[Math.floor(Math.random() * pool.length)]);
    }

    function next() {
        if (files.length === 0)
            return;
        set(files[(files.indexOf(current) + 1) % files.length]);
    }

    Process {
        id: scanner
        stdout: StdioCollector {
            onStreamFinished: {
                // results for a folder that's no longer selected are dropped
                if (root.scannedDir !== root.dir)
                    return;
                if (text.trim() === "@missing") {
                    root.files = [];
                    root.status = "missing";
                    return;
                }
                root.files = text.split("\n").filter(Boolean).sort((a, b) => a.localeCompare(b, undefined, { numeric: true, sensitivity: "base" }));
                root.status = root.files.length ? "ok" : "empty";
                if (!root.current && root.files.length > 0)
                    root.set(root.files[0]);
            }
        }
        onExited: if (root.pending || root.scannedDir !== root.dir) Qt.callLater(root.rescan)
    }

    Timer {
        running: root.cfg.cycle
        interval: Math.max(1, root.cfg.cycleMinutes) * 60000
        repeat: true
        onTriggered: root.random()
    }
}
