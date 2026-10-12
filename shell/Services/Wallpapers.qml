pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Singleton {
    id: root

    property var files: []
    readonly property var cfg: Settings.data.wallpaper
    readonly property string dir: Paths.expand(cfg.dir)
    readonly property string current: Paths.expand(cfg.current)

    onDirChanged: rescan()
    Component.onCompleted: rescan()

    function rescan() {
        if (!dir)
            return;
        scanner.command = ["find", "-L", dir, "-maxdepth", "3", "-type", "f", "(", "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.png", "-o", "-iname", "*.webp", "-o", "-iname", "*.bmp", ")"];
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
                root.files = text.split("\n").filter(Boolean).sort();
                if (!root.current && root.files.length > 0)
                    root.set(root.files[0]);
            }
        }
    }

    Timer {
        running: root.cfg.cycle
        interval: Math.max(1, root.cfg.cycleMinutes) * 60000
        repeat: true
        onTriggered: root.random()
    }
}
