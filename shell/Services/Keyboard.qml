pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Keyboard layout + shortcuts, kept in settings.json and written into niri's
// config (`flamenco keyboard apply`). niri reloads its config live.
Singleton {
    id: root

    readonly property var cfg: Settings.data.keyboard
    property var functions: []                 // [{ value, label }] Flamenco functions
    property var defaults: []                  // default shortcuts
    property var catalog: ({ layouts: [], variants: {}, options: [] })
    property var others: []                    // other niri bindings: [{ key, line }]
    property var replaced: []                  // bindings Flamenco commented out
    property string status: ""
    property bool busy: applier.running
    property bool pendingInput: false
    property bool pendingShortcuts: false

    // common niri actions for the shortcut editor
    readonly property var niriActions: [
        "toggle-overview", "close-window", "fullscreen-window", "maximize-column", "toggle-window-floating",
        "center-column", "switch-preset-column-width", "toggle-column-tabbed-display",
        "focus-workspace 1", "move-column-to-workspace 1", "focus-workspace-down", "focus-workspace-up",
        "focus-column-left", "focus-column-right", "focus-monitor-left", "focus-monitor-right",
        "move-column-left", "move-column-right", "screenshot", "screenshot-screen", "screenshot-window",
        "switch-layout \"next\"", "power-off-monitors", "show-hotkey-overlay", "quit"
    ]

    function norm(k) {
        const parts = String(k).trim().split("+");
        const mods = parts.slice(0, -1).map(p => p.toLowerCase()).sort();
        return mods.concat([String(parts[parts.length - 1]).toLowerCase()]).join("+");
    }

    // other bindings (incl. ones we replaced) that use this key
    function conflictFor(key) {
        const k = norm(key);
        const r = replaced.find(o => norm(o.key) === k);
        if (r)
            return r.line.replace(/^\/\/ flamenco: replaced by a Flamenco shortcut: /, "");
        return others.find(o => norm(o.key) === k)?.line ?? "";
    }

    function describe(sc) {
        if (!sc)
            return "";
        if (sc.type === "flamenco")
            return functions.find(f => f.value === sc.value)?.label ?? sc.value;
        if (sc.type === "app")
            return "Open " + (Apps.lookup(String(sc.value).replace(/\.desktop$/, ""))?.name ?? sc.value);
        if (sc.type === "command")
            return "Run: " + sc.value;
        if (sc.type === "none")
            return "Disabled (does nothing)";
        return "niri: " + sc.value;
    }

    function load() {
        if (!getter.running)
            getter.running = true;
        if (functions.length === 0 && !fnProc.running)
            fnProc.running = true;
        if (catalog.layouts.length === 0 && !catProc.running)
            catProc.running = true;
    }

    // ── edits from the settings page (each schedules a write to niri) ──
    function setInput(patch) {
        for (const k in patch)
            cfg[k] = patch[k];
        pendingInput = true;
        debounce.restart();
    }

    function setShortcuts(list) {
        cfg.shortcuts = list;
        pendingShortcuts = true;
        debounce.restart();
    }

    function resetShortcuts() {
        setShortcuts(defaults.map(d => Object.assign({}, d)));
    }

    // 0.20.1: Super+L locks the screen. Added once to existing setups; if you remove
    // it afterwards it stays removed. Skipped when Super+L is already a Flamenco shortcut.
    function addLockKey() {
        if (cfg.lockKeyAdded || !cfg.imported)
            return;
        const list = (cfg.shortcuts || []).slice();
        if (!list.some(s => norm(s.key) === norm("Mod+L")))
            list.push({ key: I18n.tr("Mod+L"), type: "flamenco", value: "lock", title: I18n.tr("Lock the screen") });
        // written either way, so it reaches the compositor config on fresh setups too
        setShortcuts(list);
        cfg.lockKeyAdded = true;
    }

    // 0.31.0: Alt+Tab / Alt+Shift+Tab open the app switcher. Added once, like Super+L,
    // and only on keys no Flamenco shortcut uses yet.
    function addSwitcherKeys() {
        if (cfg.switcherKeysAdded || !cfg.imported)
            return;
        const list = (cfg.shortcuts || []).slice();
        if (!list.some(s => norm(s.key) === norm("Alt+Tab")))
            list.push({ key: I18n.tr("Alt+Tab"), type: "flamenco", value: "switcher-next", title: I18n.tr("App switcher") });
        if (!list.some(s => norm(s.key) === norm("Alt+Shift+Tab")))
            list.push({ key: I18n.tr("Alt+Shift+Tab"), type: "flamenco", value: "switcher-prev", title: I18n.tr("App switcher (back)") });
        setShortcuts(list);
        cfg.switcherKeysAdded = true;
    }

    Timer {
        running: Settings.ready && (!root.cfg.lockKeyAdded || !root.cfg.switcherKeysAdded)
        interval: 3000
        onTriggered: {
            if (!root.cfg.imported) {
                root.load();
                return;
            }
            root.addLockKey();
            root.addSwitcherKeys();
        }
    }

    function applyNow() {
        const spec = {};
        if (pendingInput)
            spec.input = { layout: cfg.layout, variant: cfg.variant, options: cfg.options, model: cfg.model, repeatDelay: cfg.repeatDelay, repeatRate: cfg.repeatRate, numlock: cfg.numlock, trackLayout: cfg.trackLayout };
        if (pendingShortcuts)
            spec.shortcuts = cfg.shortcuts;
        pendingInput = false;
        pendingShortcuts = false;
        if (!spec.input && !spec.shortcuts)
            return;
        applier.command = [Paths.bin, "keyboard", "apply", "--json", JSON.stringify(spec)];
        applier.running = true;
    }

    Timer {
        id: debounce
        interval: 700
        onTriggered: applier.running ? restart() : root.applyNow()
    }

    Process {
        id: getter
        command: [Paths.bin, "keyboard", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                let d;
                try {
                    d = JSON.parse(text);
                } catch (e) {
                    root.status = "Couldn't read the niri config";
                    return;
                }
                root.others = d.others ?? [];
                root.replaced = d.replaced ?? [];
                // first visit: adopt what's already in the niri config
                if (!root.cfg.imported) {
                    for (const k of ["layout", "variant", "options", "model", "repeatDelay", "repeatRate", "numlock", "trackLayout"])
                        root.cfg[k] = d[k];
                    if (d.shortcuts && d.shortcuts.length)
                        root.cfg.shortcuts = d.shortcuts;
                    else if (root.defaults.length)
                        root.cfg.shortcuts = root.defaults.map(x => Object.assign({}, x));
                    root.cfg.imported = true;
                }
                root.addLockKey();
                root.addSwitcherKeys();
            }
        }
    }

    Process {
        id: fnProc
        command: [Paths.bin, "keyboard", "functions"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.functions = JSON.parse(text);
                } catch (e) {}
                defProc.running = true;
            }
        }
    }

    Process {
        id: defProc
        command: [Paths.bin, "keyboard", "defaults"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.defaults = JSON.parse(text);
                    if (root.cfg.imported && root.cfg.shortcuts.length === 0 && !root.pendingShortcuts)
                        root.cfg.shortcuts = root.defaults.map(d => Object.assign({}, d));
                } catch (e) {}
            }
        }
    }

    Process {
        id: catProc
        command: [Paths.bin, "keyboard", "layouts"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.catalog = JSON.parse(text);
                } catch (e) {}
            }
        }
    }

    Process {
        id: applier
        stdout: StdioCollector {
            onStreamFinished: if (text.trim()) root.status = text.trim()
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) root.status = text.trim().split("\n").pop().replace(/^flamenco: /, "")
        }
        onExited: code => {
            if (code === 0)
                root.status = "Saved to niri config · " + Qt.formatTime(new Date(), Time.use24h ? "HH:mm:ss" : "h:mm:ss AP");
            getter.running = true;
        }
    }
}
