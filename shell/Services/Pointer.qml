pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Mouse + touchpad settings, kept in settings.json and written into the
// compositor config (`flamenco pointer apply`). niri and Hyprland reload live.
Singleton {
    id: root

    readonly property var cfg: Settings.data.pointer
    readonly property var keys: ["mouseSpeed", "mouseAccel", "mouseNatural", "mouseLeftHanded", "mouseScroll",
        "touchSpeed", "touchAccel", "touchNatural", "tap", "dwt", "touchScroll", "disableWithMouse"]
    property string status: ""
    property bool busy: applier.running

    // first visit: start from what the compositor config already says
    function load() {
        if (!cfg.imported && !getter.running)
            getter.running = true;
    }

    // a setting changed: write it shortly after the slider stops
    function queue() {
        applyDelay.restart();
    }

    function spec() {
        const s = {};
        for (const k of keys)
            s[k] = cfg[k];
        return s;
    }

    Timer {
        id: applyDelay
        interval: 450
        onTriggered: {
            applier.command = [Paths.bin, "pointer", "apply", "--json", JSON.stringify(root.spec())];
            applier.running = true;
        }
    }

    Process {
        id: getter
        command: [Paths.bin, "pointer", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    for (const k of root.keys)
                        if (d[k] !== undefined)
                            root.cfg[k] = d[k];
                    root.cfg.imported = true;
                } catch (e) {}
            }
        }
    }

    Process {
        id: applier
        stdout: StdioCollector {
            onStreamFinished: if (text.trim()) root.status = text.trim().split("\n").pop()
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) root.status = text.trim().split("\n").pop()
        }
    }
}
