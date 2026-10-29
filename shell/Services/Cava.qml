pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Audio visualizer: cava's bar heights (0–1), read from its raw text output.
// It only runs while something plays and a visualizer is showing (users > 0).
Singleton {
    id: root

    property int users: 0
    // how finely the sound is split, and how often (Settings → Sound → Audio visualizer)
    readonly property int bars: Math.max(8, Math.min(64, Settings.data.visualizer.bars || 24))
    readonly property int fps: (Settings.data.visualizer.fps || 60) >= 60 ? 60 : 30
    property var values: []
    readonly property bool available: avail.ok
    readonly property bool running: proc.running

    readonly property string config: "[general]\nbars = " + bars + "\nframerate = " + fps + "\nautosens = 1\n[input]\nmethod = pipewire\nsource = auto\n"
        + "[output]\nmethod = raw\nraw_target = /dev/stdout\ndata_format = ascii\nascii_max_range = 100\nbar_delimiter = 59\nframe_delimiter = 10\n"
        + "[smoothing]\nnoise_reduction = 60\n"

    Process {
        id: proc
        running: Settings.data.visualizer.enabled !== false && root.users > 0 && Media.playing && root.available
        // the config goes in through a here-string; cava reads it from the path we give
        command: ["sh", "-c", 'f="$2/flamenco-cava.conf"; printf "%s" "$1" > "$f"; exec cava -p "$f"', "sh", root.config, Paths.runDir]
        stdout: SplitParser {
            onRead: line => root.values = line.split(";").filter(x => x !== "").map(x => Math.min(1, Number(x) / 100))
        }
        onRunningChanged: if (!running) root.values = []
    }
    // new bars / frame rate: start cava again with them
    onConfigChanged: if (proc.running) {
        proc.running = false;
        Qt.callLater(() => proc.running = Qt.binding(() => Settings.data.visualizer.enabled !== false && root.users > 0 && Media.playing && root.available));
    }

    // is cava installed?
    Process {
        id: avail
        property bool ok: false
        running: true
        command: ["sh", "-c", "command -v cava"]
        onExited: code => ok = code === 0
    }
}
