pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Screen recording: `flamenco record` runs the recorder; its state file in the
// runtime folder says what's recording, so this follows it even across a
// shell restart.
Singleton {
    id: root

    property bool recording: false
    property string file: ""
    property real started: 0
    property int elapsed: 0               // seconds
    readonly property string clock: {
        const h = Math.floor(elapsed / 3600), m = Math.floor(elapsed / 60) % 60, s = elapsed % 60;
        const two = n => (n < 10 ? "0" : "") + n;
        return (h ? h + ":" + two(m) : m) + ":" + two(s);
    }
    readonly property bool available: true

    function start(mode, output) {
        Quickshell.execDetached([Paths.bin, "record", "start", mode || "screen"].concat(output ? [output] : []));
    }
    function stop() {
        Quickshell.execDetached([Paths.bin, "record", "stop"]);
    }
    function toggle(mode, output) {
        recording ? stop() : start(mode, output);
    }

    FileView {
        path: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/flamenco-record.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                const st = JSON.parse(text());
                root.file = st.file ?? "";
                root.started = st.started ?? 0;
                root.recording = true;
                root.elapsed = Math.max(0, Math.floor(Date.now() / 1000 - root.started));
            } catch (e) {
                root.recording = false;
            }
        }
        onLoadFailed: root.recording = false
    }

    // the state file goes away when recording stops; a removed file doesn't
    // always fire a change, so check now and then while recording
    Timer {
        running: root.recording
        interval: 1000
        repeat: true
        onTriggered: {
            root.elapsed = Math.max(0, Math.floor(Date.now() / 1000 - root.started));
            checker.running = true;
        }
    }
    Process {
        id: checker
        command: ["sh", "-c", "test -e \"$1\"", "sh", (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/flamenco-record.json"]
        onExited: code => {
            if (code !== 0)
                root.recording = false;
        }
    }
}
