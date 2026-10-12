pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Monitor configuration through niri (`flamenco display …`).
Singleton {
    id: root

    property var outputs: []            // see `flamenco display list --json`
    property bool loading: lister.running
    property bool busy: applier.running || saver.running
    property string status: ""
    property bool identifying: false

    signal applied(bool ok)
    signal saved(bool ok)

    function refresh() {
        if (!lister.running)
            lister.running = true;
    }

    // Editable layout derived from the current state.
    function specFrom(list) {
        return list.map(o => ({
                    name: o.name,
                    enabled: o.enabled,
                    mode: o.current ?? o.modes.find(m => m.preferred) ?? o.modes[0] ?? null,
                    scale: o.scale || 1,
                    transform: o.transform,
                    x: o.x,
                    y: o.y,
                    vrr: o.vrrEnabled,
                    vrrSupported: o.vrrSupported
                }));
    }

    function apply(spec) {
        applier.command = [Paths.bin, "display", "apply", "--json", JSON.stringify(spec)];
        applier.running = true;
    }

    function save(spec) {
        saver.command = [Paths.bin, "display", "save", "--json", JSON.stringify(spec)];
        saver.running = true;
    }

    // ── apply → confirm → keep / revert ──
    property var pendingSpec: null
    property var revertSpec: null
    property int countdown: 0
    readonly property bool confirming: countdown > 0

    function tryApply(spec) {
        revertSpec = specFrom(outputs);
        pendingSpec = spec;
        apply(spec);
        countdown = 15;
        tick.restart();
    }

    function keep() {
        tick.stop();
        countdown = 0;
        if (pendingSpec)
            save(pendingSpec);
        pendingSpec = null;
    }

    function revert() {
        tick.stop();
        countdown = 0;
        if (revertSpec)
            apply(revertSpec);
        pendingSpec = null;
        status = "Reverted to the previous display settings";
    }

    Timer {
        id: tick
        interval: 1000
        repeat: true
        onTriggered: {
            root.countdown -= 1;
            if (root.countdown <= 0)
                root.revert();
        }
    }

    function identify() {
        identifying = true;
        identifyTimer.restart();
    }

    Timer {
        id: identifyTimer
        interval: 2500
        onTriggered: root.identifying = false
    }

    Process {
        id: lister
        command: [Paths.bin, "display", "list", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.outputs = JSON.parse(text);
                } catch (e) {
                    root.status = "Couldn't read displays from niri";
                }
            }
        }
    }

    Process {
        id: applier
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) root.status = text.trim().split("\n").pop()
        }
        onExited: code => {
            root.applied(code === 0);
            root.refresh();
        }
    }

    Process {
        id: saver
        stdout: StdioCollector {
            onStreamFinished: if (text.trim()) root.status = text.trim().split("\n").pop()
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) root.status = text.trim().split("\n").pop()
        }
        onExited: code => root.saved(code === 0)
    }
}
