pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// The notepad's notes, in ~/.local/share/flamenco/notes.json, saved as you type.
Singleton {
    id: root

    readonly property string path: (Quickshell.env("XDG_DATA_HOME") || Paths.home + "/.local/share") + "/flamenco/notes.json"
    property var notes: []                  // [{ id, text, updated }]
    property bool loaded: false

    function title(n) {
        const first = String(n?.text ?? "").split("\n").find(l => l.trim() !== "") ?? "";
        return first.replace(/^#+\s*/, "").trim().slice(0, 40) || "Empty note";
    }

    function add() {
        const n = { id: Date.now().toString(36), text: "", updated: Date.now() };
        notes = [n].concat(notes);
        save.restart();
        return n.id;
    }
    function setText(id, text) {
        notes = notes.map(n => n.id === id ? Object.assign({}, n, { text, updated: Date.now() }) : n);
        save.restart();
    }
    function remove(id) {
        notes = notes.filter(n => n.id !== id);
        save.restart();
    }

    FileView {
        id: file
        path: root.path
        printErrors: false
        onLoaded: {
            try {
                root.notes = JSON.parse(text()).notes ?? [];
            } catch (e) {
                root.notes = [];
            }
            root.loaded = true;
        }
        onLoadFailed: root.loaded = true
    }

    Timer {
        id: save
        interval: 600
        onTriggered: mkdir.running = true
    }
    // the folder may not exist yet
    Process {
        id: mkdir
        command: ["mkdir", "-p", root.path.replace(/\/[^/]*$/, "")]
        onExited: file.setText(JSON.stringify({ notes: root.notes }, null, 1))
    }
}
