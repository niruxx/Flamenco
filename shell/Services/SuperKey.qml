pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Super pressed and let go on its own, for the overview (Settings → Overview).
// `flamenco super-watch` reads the keyboards (it needs the input group) and
// prints "tap"; shell.qml opens the overview on it.
Singleton {
    id: root

    readonly property var cfg: Settings.data.overview
    readonly property bool wanted: Settings.ready && cfg.enabled && cfg.superKey
    // "" (off) | starting | ready | permission (not in the input group) | no-keyboard | failed
    property string status: ""
    signal tapped

    function start() {
        proc.running = false;
        if (!wanted) {
            status = "";
            return;
        }
        status = "starting";
        proc.command = [Paths.bin, "super-watch", "--max-hold", String(cfg.superHold || 0.6)];
        proc.running = true;
    }

    onWantedChanged: start()
    Component.onCompleted: start()
    Connections {
        target: root.cfg
        function onSuperHoldChanged() { root.start(); }
    }

    Process {
        id: proc
        stdout: SplitParser {
            onRead: line => {
                if (line === "tap")
                    root.tapped();
                else if (line.startsWith("ready"))
                    root.status = "ready";
                else if (line === "error permission")
                    root.status = "permission";
                else if (line === "error no-keyboard")
                    root.status = "no-keyboard";
            }
        }
        onExited: code => {
            if (!root.wanted)
                return;
            if (code === 3) {
                root.status = "permission";
                return;
            }
            // crashed or got killed: try again in a bit
            root.status = "failed";
            retry.start();
        }
    }

    Timer {
        id: retry
        interval: 5000
        onTriggered: if (root.wanted && !proc.running) root.start()
    }
}
