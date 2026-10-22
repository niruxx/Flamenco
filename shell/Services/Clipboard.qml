pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Clipboard history (cliphist): what the clipboard panel and the launcher's ";"
// show. Flamenco keeps the history itself, with `wl-paste --watch cliphist store`
// for text and images, unless something else (the compositor config) already
// does (Settings → Launcher → Clipboard history).
Singleton {
    id: root

    readonly property var cfg: Settings.data.clipboard
    property bool available: false               // cliphist and wl-paste are installed
    property bool othersWatching: false           // a wl-paste … cliphist store started elsewhere
    readonly property bool watching: othersWatching || (textWatch.running && imageWatch.running)
    // [{ id, line, text, image, kind, size }]: newest first
    property var entries: []
    property bool loading: lister.running
    readonly property string previewDir: Paths.runDir + "/flamenco-clipboard"
    property var previews: ({})                   // id → image file, once decoded

    function parse(text) {
        const out = [];
        for (const line of text.split("\n")) {
            const tab = line.indexOf("\t");
            if (tab < 0)
                continue;
            const id = line.slice(0, tab);
            const body = line.slice(tab + 1);
            // images: "[[ binary data 37 KiB png 640x480 ]]"
            const m = body.match(/^\[\[ binary data (.+?) (\w+) (\d+x\d+) \]\]$/);
            out.push({ id: id, line: line, text: m ? "" : body, image: !!m, kind: m ? m[2] : "", size: m ? m[1] + " · " + m[3] : "" });
        }
        return out;
    }

    function refresh() {
        if (available && !lister.running)
            lister.running = true;
    }
    // back on the clipboard (the newest entry again, so it's on top)
    function copy(e) {
        Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | cliphist decode | wl-copy', "sh", e.line]);
        refreshSoon.restart();
    }
    function remove(e) {
        entries = entries.filter(x => x.id !== e.id);
        Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | cliphist delete', "sh", e.line]);
    }
    function wipe() {
        entries = [];
        previews = {};
        Quickshell.execDetached(["sh", "-c", 'cliphist wipe; rm -rf "$1"', "sh", previewDir]);
    }
    // an image entry as a file the panel can show
    function preview(e) {
        if (!e.image || previews[e.id] !== undefined)
            return;
        const all = Object.assign({}, previews);
        all[e.id] = "";
        previews = all;
        const file = previewDir + "/" + e.id + "." + (e.kind || "png");
        const p = decoder.createObject(root, { command: ["sh", "-c", 'mkdir -p -m 700 "$1" && printf "%s" "$2" | cliphist decode > "$3"', "sh", previewDir, e.line, file], entryId: e.id, file: file });
        p.running = true;
    }

    property Component decoder: Component {
        Process {
            id: proc
            property string entryId
            property string file
            onExited: code => {
                const all = Object.assign({}, root.previews);
                all[proc.entryId] = code === 0 ? proc.file : "";
                root.previews = all;
                proc.destroy();
            }
        }
    }

    Timer {
        id: refreshSoon
        interval: 300
        onTriggered: root.refresh()
    }

    Process {
        id: lister
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: root.entries = root.parse(text)
        }
    }

    // are cliphist and wl-paste installed, and does something else already record?
    Process {
        id: probe
        running: true
        command: ["sh", "-c", "command -v cliphist >/dev/null && command -v wl-paste >/dev/null && echo ok; "
            + "for p in $(pgrep -x wl-paste); do tr '\\0' ' ' < /proc/$p/cmdline | grep -q 'cliphist.* store' && { echo others; break; }; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.available = text.includes("ok");
                root.othersWatching = text.includes("others");
                root.refresh();
            }
        }
    }

    readonly property bool shouldWatch: available && !othersWatching && (cfg.watch ?? true)
    readonly property string maxItems: String(Math.max(10, cfg.maxItems || 500))
    Process {
        id: textWatch
        running: root.shouldWatch
        command: ["wl-paste", "--type", "text", "--watch", "cliphist", "-max-items", root.maxItems, "store"]
    }
    Process {
        id: imageWatch
        running: root.shouldWatch
        command: ["wl-paste", "--type", "image", "--watch", "cliphist", "-max-items", root.maxItems, "store"]
    }
}
