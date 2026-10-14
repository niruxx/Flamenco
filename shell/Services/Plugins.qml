pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Plugins from ~/.config/flamenco/plugins (`flamenco plugins list`): bar widgets
// and launcher extensions. Only the ones turned on in Settings → Plugins load.
Singleton {
    id: root

    property var all: []                       // every plugin found, with problems reported
    property string dir: ""
    readonly property var enabledIds: Settings.data.plugins.enabled || []
    readonly property var active: all.filter(p => p.ok && enabledIds.includes(p.id))
    // bar widgets: "plugin:<id>" → { file, label }
    readonly property var barWidgets: {
        const out = {};
        for (const p of active)
            if (p.bar)
                out["plugin:" + p.id] = { file: p.bar, label: p.barLabel || p.name, id: p.id };
        return out;
    }
    // launcher extensions: [{ id, name, prefix, script, hint }]
    readonly property var launchers: active.filter(p => p.launcher).map(p => Object.assign({ id: p.id, name: p.name }, p.launcher))

    function refresh() {
        if (!lister.running)
            lister.running = true;
    }
    function setEnabled(id, on) {
        const l = enabledIds.filter(x => x !== id);
        Settings.data.plugins.enabled = on ? l.concat([id]) : l;
    }
    function find(id) {
        return all.find(p => p.id === id) ?? null;
    }

    Component.onCompleted: refresh()

    Process {
        id: lister
        command: [Paths.bin, "plugins", "list", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    root.all = d.plugins ?? [];
                    root.dir = d.dir ?? "";
                } catch (e) {}
            }
        }
    }
}
