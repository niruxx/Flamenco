import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services as FS

// What a Noctalia plugin gets as `pluginApi` (one per plugin), backed by Flamenco:
// its settings are kept by Flamenco, panels open in Flamenco's 3rd-party panel,
// and its translations come from its own i18n folder.
QtObject {
    id: api

    required property string key           // "noctalia/<id>"
    required property var info             // the plugin, from `flamenco compat list`
    readonly property string pluginId: key.slice(9)
    readonly property string pluginDir: info?.dir ?? ""
    property var pluginSettings: ({})
    Component.onCompleted: pluginSettings = Object.assign({}, FS.ThirdParty.data(key))
    readonly property var manifest: info?.manifest ?? ({})

    property var mainInstance: null
    property var barWidget: null
    property var desktopWidget: null
    property var launcherProvider: null
    property var controlCenterWidget: null
    property var panelOpenScreen: null
    property var ipcHandlers: ({})
    property var sharedData: ({})
    property int unreadCount: 0
    readonly property var currentScreen: Quickshell.screens.find(s => s.name === FS.Niri.focusedOutput) ?? Quickshell.screens[0] ?? null

    property var pluginTranslations: ({})
    property var pluginFallbackTranslations: ({})
    property string currentLanguage: "en"
    property int translationVersion: 0

    function saveSettings() {
        FS.ThirdParty.replaceData(key, pluginSettings);
        // a new object, so bindings on pluginSettings see the change
        pluginSettings = Object.assign({}, pluginSettings);
    }
    function openPanel(screen, buttonItem) {
        panelOpenScreen = screen ?? currentScreen;
        return FS.ThirdParty.openPanel(key, panelOpenScreen?.name ?? "", buttonItem ?? null);
    }
    function togglePanel(screen, buttonItem) {
        panelOpenScreen = screen ?? currentScreen;
        return FS.ThirdParty.togglePanel(key, panelOpenScreen?.name ?? "", buttonItem ?? null);
    }
    function closePanel(screen) {
        if (FS.ThirdParty.panelKey === key)
            FS.ThirdParty.closePanel();
        return true;
    }
    function isPanelOpen(screen) {
        return FS.ThirdParty.panelKey === key && FS.Panels.current === "thirdparty";
    }
    function openLauncher(screen) {
        FS.Panels.open("launcher", screen?.name ?? "");
    }
    function closeLauncher(screen) {
        if (FS.Panels.current === "launcher")
            FS.Panels.close();
    }
    function toggleLauncher(screen) {
        FS.Panels.toggle("launcher", screen?.name ?? "");
    }
    function withCurrentScreen(callback) {
        callback(currentScreen);
    }
    function triggerRefresh() {}

    function lookup(table, k) {
        let cur = table;
        for (const p of String(k).split(".")) {
            if (cur === undefined || cur === null)
                return undefined;
            cur = cur[p];
        }
        return cur;
    }
    function tr(k, interpolations) {
        let t = lookup(pluginTranslations, k);
        if (typeof t !== "string")
            t = lookup(pluginFallbackTranslations, k);
        if (typeof t !== "string")
            return "!!" + k + "!!";
        for (const n in (interpolations || {}))
            t = t.replace(new RegExp("\\{" + n + "\\}", "g"), interpolations[n]);
        return t;
    }
    function trp(k, count, interpolations) {
        return tr(count === 1 ? k : k + "-plural", Object.assign({ count: count }, interpolations || {}));
    }
    function hasTranslation(k) {
        return typeof lookup(pluginTranslations, k) === "string" || typeof lookup(pluginFallbackTranslations, k) === "string";
    }

    // the system language's strings, with English for anything missing
    readonly property string lang: Qt.locale().name.split("_")[0]
    property FileView fallbackFile: FileView {
        path: api.pluginDir ? api.pluginDir + "/i18n/en.json" : ""
        printErrors: false
        onLoaded: {
            try {
                api.pluginFallbackTranslations = JSON.parse(text());
                api.translationVersion++;
            } catch (e) {}
        }
    }
    property FileView langFile: FileView {
        path: api.pluginDir && api.lang !== "en" ? api.pluginDir + "/i18n/" + api.lang + ".json" : ""
        printErrors: false
        onLoaded: {
            try {
                api.pluginTranslations = JSON.parse(text());
                api.currentLanguage = api.lang;
                api.translationVersion++;
            } catch (e) {}
        }
    }

    // a plugin's settings changed elsewhere (another part of it, or Settings)
    property Connections watch: Connections {
        target: FS.ThirdParty
        function onDataChanged(changed) {
            if (changed === api.key)
                api.pluginSettings = Object.assign({}, FS.ThirdParty.data(api.key));
        }
    }
}
