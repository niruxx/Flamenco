pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Plugins made for Noctalia Shell (v4) and DankMaterialShell, run through the
// compatibility layer in shell/Compat (Settings → Plugins (3rd party)).
// `flamenco compat list` finds them and makes the copies the shell loads; only
// the ones turned on here load. Their settings are kept per plugin in
// ~/.config/flamenco/compat/settings.json.
Singleton {
    id: root

    property var plugins: []                     // `flamenco compat list --json`
    property var errors: ({})                    // key → what failed to load
    property bool loading: lister.running
    readonly property var cfg: Settings.data.thirdParty
    readonly property var enabledKeys: cfg.enabled || []
    readonly property var active: plugins.filter(p => enabledKeys.includes(p.key) && p.status !== "unsupported")

    // bar widgets: "tp:<key>" → { key, label, kind, file }
    readonly property var barWidgets: {
        const out = {};
        for (const p of active) {
            const file = p.kind === "noctalia" ? p.entries.barWidget : p.entries.widget;
            if (file)
                out["tp:" + p.key] = { key: p.key, kind: p.kind, file: file, label: p.name + (p.kind === "noctalia" ? " (Noctalia)" : " (DMS)") };
        }
        return out;
    }

    function find(key) {
        return plugins.find(p => p.key === key) ?? null;
    }
    function isEnabled(key) {
        return enabledKeys.includes(key);
    }
    function setEnabled(key, on) {
        const l = enabledKeys.filter(k => k !== key);
        cfg.enabled = on ? l.concat([key]) : l;
    }
    function refresh() {
        if (!lister.running)
            lister.running = true;
    }
    // load a plugin's code again (after updating it)
    function reload(key) {
        stop(key);
        const e = Object.assign({}, errors);
        delete e[key];
        errors = e;
        Qt.callLater(sync);
    }
    function fail(key, part, message) {
        const e = Object.assign({}, errors);
        e[key] = part + ": " + String(message).trim().split("\n").slice(0, 3).join(" · ");
        errors = e;
        console.warn("3rd-party plugin " + key + " (" + part + "):", message);
    }

    Component.onCompleted: refresh()

    // ── updates: once a day (and on request), a notification when there are new ones ──
    property var updates: []                     // [{ key, name, from, to }]
    property bool checking: updater.running
    function checkUpdates() {
        if (!updater.running && plugins.length > 0)
            updater.running = true;
    }
    function updateAll() {
        updates = [];
        upgrader.running = true;
    }
    Process {
        id: upgrader
        command: [Paths.bin, "compat", "update", "all"]
        // the turned-on ones load their new version
        onExited: {
            root.refresh();
            for (const k of root.enabledKeys)
                root.reload(k);
        }
    }
    Timer {
        // a while after starting, then every day
        interval: 120000
        running: (root.cfg.checkUpdates ?? true) && root.plugins.length > 0
        repeat: true
        onTriggered: {
            interval = 24 * 3600 * 1000;
            root.checkUpdates();
        }
    }
    Process {
        id: updater
        command: [Paths.bin, "compat", "updates", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.updates = JSON.parse(text);
                } catch (e) {
                    return;
                }
                const sig = root.updates.map(u => u.key + "@" + u.to).join(",");
                if (sig && sig !== (root.cfg.notified || "")) {
                    root.cfg.notified = sig;
                    Quickshell.execDetached(["notify-send", "-a", "Flamenco", "-i", "system-software-update",
                        root.updates.length === 1 ? "A plugin update" : root.updates.length + " plugin updates",
                        root.updates.map(u => u.name + (u.to ? " " + u.to : "")).join(", ") + ". Update them in Settings → Plugins (3rd party)"]);
                }
            }
        }
    }

    Process {
        id: lister
        command: [Paths.bin, "compat", "list", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.plugins = JSON.parse(text).plugins ?? [];
                } catch (e) {}
                root.sync();
            }
        }
    }

    // ── settings and state, per plugin ──
    property var store: ({})
    property var stateStore: ({})
    signal dataChanged(string key)
    signal stateChanged(string key)

    function data(key) {
        return store[key] ?? {};
    }
    // DMS's SettingsData.pluginSettings: every DMS plugin's settings by id
    readonly property var dmsAll: {
        const out = {};
        for (const k in store)
            if (k.startsWith("dms/"))
                out[k.slice(4)] = store[k];
        return out;
    }
    function setData(key, field, value) {
        const all = Object.assign({}, store);
        all[key] = Object.assign({}, all[key] || {}, { [field]: value });
        store = all;
        saveStore.restart();
        dataChanged(key);
    }
    function replaceData(key, obj) {
        const all = Object.assign({}, store);
        all[key] = JSON.parse(JSON.stringify(obj || {}));
        store = all;
        saveStore.restart();
        dataChanged(key);
    }
    function clearData(key) {
        const all = Object.assign({}, store);
        delete all[key];
        store = all;
        saveStore.restart();
        dataChanged(key);
    }
    function state(key) {
        return stateStore[key] ?? {};
    }
    function setState(key, field, value) {
        const all = Object.assign({}, stateStore);
        all[key] = Object.assign({}, all[key] || {}, { [field]: value });
        stateStore = all;
        saveState.restart();
        stateChanged(key);
    }
    function clearState(key) {
        const all = Object.assign({}, stateStore);
        delete all[key];
        stateStore = all;
        saveState.restart();
        stateChanged(key);
    }

    FileView {
        id: storeFile
        path: Paths.configDir + "/compat/settings.json"
        printErrors: false
        onLoaded: {
            try {
                root.store = JSON.parse(text()) || {};
            } catch (e) {}
            for (const k in root.store)
                root.dataChanged(k);
        }
    }
    FileView {
        id: stateFile
        path: Paths.stateDir + "/compat-state.json"
        printErrors: false
        onLoaded: {
            try {
                root.stateStore = JSON.parse(text()) || {};
            } catch (e) {}
        }
    }
    Timer {
        id: saveStore
        interval: 400
        onTriggered: {
            Quickshell.execDetached(["mkdir", "-p", Paths.configDir + "/compat"]);
            storeFile.setText(JSON.stringify(root.store, null, 2) + "\n");
        }
    }
    Timer {
        id: saveState
        interval: 800
        onTriggered: stateFile.setText(JSON.stringify(root.stateStore) + "\n")
    }

    // ── what plugins get: Noctalia's pluginApi, DMS's pluginService ──
    // Made from files in shell/Compat at runtime: those import Flamenco's
    // modules, so Flamenco doesn't import theirs.
    property var apis: ({})
    readonly property Component apiComponent: Qt.createComponent("file://" + Quickshell.shellDir + "/Compat/Noctalia/PluginApi.qml")
    // made the first time a DMS plugin needs it
    property var dmsHost: null
    function dms() {
        if (!dmsHost) {
            const c = Qt.createComponent("file://" + Quickshell.shellDir + "/Compat/Dms/Host.qml");
            if (c.status !== Component.Ready) {
                console.warn("DMS compatibility:", c.errorString());
                return null;
            }
            dmsHost = c.createObject(root);
        }
        return dmsHost?.pluginService ?? null;
    }

    function noctaliaApi(idOrKey) {
        const key = String(idOrKey).startsWith("noctalia/") ? String(idOrKey) : "noctalia/" + idOrKey;
        if (apis[key])
            return apis[key];
        const info = find(key);
        if (!info)
            return null;
        if (apiComponent.status !== Component.Ready) {
            fail(key, "pluginApi", apiComponent.errorString());
            return null;
        }
        const api = apiComponent.createObject(root, { key: key, info: info });
        const all = Object.assign({}, apis);
        all[key] = api;
        apis = all;
        return api;
    }

    // ── background parts: Noctalia's Main.qml, DMS daemons ──
    property var mains: ({})
    onActiveChanged: Qt.callLater(sync)

    function sync() {
        const want = active.filter(p => p.kind === "noctalia" ? !!p.entries.main : !!p.entries.daemon).map(p => p.key);
        for (const k of Object.keys(mains))
            if (!want.includes(k))
                stop(k);
        for (const k of want)
            if (!mains[k] && !errors[k])
                start(find(k));
    }
    function start(p) {
        const file = p.kind === "noctalia" ? p.entries.main : p.entries.daemon;
        const comp = Qt.createComponent("file://" + file);
        const make = () => {
            if (comp.status === Component.Error) {
                fail(p.key, p.kind === "noctalia" ? "Main.qml" : "daemon", comp.errorString());
                return;
            }
            const props = p.kind === "noctalia" ? { pluginApi: noctaliaApi(p.key) } : { pluginId: p.id, pluginService: dms() };
            const obj = comp.createObject(root, props);
            if (!obj) {
                fail(p.key, "start", "couldn't create it");
                return;
            }
            if (p.kind === "noctalia" && apis[p.key])
                apis[p.key].mainInstance = obj;
            const all = Object.assign({}, mains);
            all[p.key] = obj;
            mains = all;
        };
        if (comp.status === Component.Loading)
            comp.statusChanged.connect(make);
        else
            make();
    }
    function stop(key) {
        if (mains[key]) {
            mains[key].destroy();
            const all = Object.assign({}, mains);
            delete all[key];
            mains = all;
        }
        if (apis[key]) {
            apis[key].destroy();
            const a = Object.assign({}, apis);
            delete a[key];
            apis = a;
        }
        if (panelKey === key)
            closePanel();
    }

    // ── the panel (one, shared): a Noctalia plugin's Panel.qml or a DMS popout ──
    property string panelKey: ""
    property var popoutOwner: null              // DMS: the bar widget whose popout is showing

    function openPanel(key, screenName, item) {
        panelKey = key;
        popoutOwner = null;
        Panels.open("thirdparty", screenName || "", item || null);
        return true;
    }
    function togglePanel(key, screenName, item) {
        if (Panels.current === "thirdparty" && panelKey === key)
            closePanel();
        else
            openPanel(key, screenName, item);
        return true;
    }
    function togglePopout(owner, item) {
        if (Panels.current === "thirdparty" && popoutOwner === owner) {
            closePanel();
            return;
        }
        panelKey = "dms/" + owner.pluginId;
        popoutOwner = owner;
        Panels.open("thirdparty", owner.parentScreen?.name ?? "", item || null);
    }
    function closePanel() {
        if (Panels.current === "thirdparty")
            Panels.close();
    }
    // Noctalia's PanelService.getPanel("pluginPanel1") stands for this
    readonly property QtObject panelProxy: QtObject {
        readonly property string currentPluginId: root.panelKey.startsWith("noctalia/") ? root.panelKey.slice(9) : ""
        readonly property bool isPanelOpen: Panels.current === "thirdparty"
        function close() {
            root.closePanel();
        }
    }

    // a plugin's settings, in Settings → Plugins (3rd party)
    property string settingsKey: ""
    function openSettings(key) {
        settingsKey = key;
        Panels.close();
        Panels.openSettings("thirdparty");
    }
}
