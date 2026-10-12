pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Backlight via brightnessctl.
Singleton {
    id: root

    property bool available: false
    property real value: 0
    property real pending: -1

    signal changedByUser

    function set(v) {
        v = Math.max(0.01, Math.min(1, v));
        value = v;
        pending = v;
        writeTimer.restart();
        changedByUser();
    }

    function step(delta) {
        set(value + delta);
    }

    function refresh() {
        if (!reader.running)
            reader.running = true;
    }

    Process {
        id: reader
        command: ["brightnessctl", "-m", "-c", "backlight", "info"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                // name,class,current,percent,max
                const parts = text.trim().split(",");
                if (parts.length >= 5) {
                    root.available = true;
                    if (root.pending < 0)
                        root.value = parseInt(parts[2]) / parseInt(parts[4]);
                }
            }
        }
    }

    Timer {
        id: writeTimer
        interval: 40
        onTriggered: {
            Quickshell.execDetached(["brightnessctl", "-c", "backlight", "set", Math.round(root.pending * 100) + "%"]);
            root.pending = -1;
        }
    }

    Timer {
        interval: 5000
        running: root.available
        repeat: true
        onTriggered: root.refresh()
    }
}
