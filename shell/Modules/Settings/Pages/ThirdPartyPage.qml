import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services
import qs.Widgets

// Noctalia (v4) and DankMaterialShell plugins, run through Flamenco's
// compatibility layer (shell/Compat). Installing, the catalogs, turning them on,
// their settings, and what of each Flamenco can and can't run.
Page {
    id: page
    title: "Plugins (3rd party)"
    subtitle: "Run plugins made for Noctalia Shell and DankMaterialShell. Flamenco runs their bar widgets, panels, settings and background parts with its own look; it checks each one and says what won't work. Plugins run with your permissions, so only turn on ones you trust."

    property string status: ""
    property string source: "noctalia"
    property var catalog: []
    property string catalogFor: ""
    property string query: ""
    property int shown: 30
    readonly property var matches: {
        const q = query.trim().toLowerCase();
        return catalog.filter(p => !q || [p.name, p.id, p.description, p.author, (p.tags || []).join(" ")].join(" ").toLowerCase().includes(q));
    }

    Component.onCompleted: ThirdParty.refresh()

    function cli(args) {
        status = "Working…";
        runner.command = [Paths.bin, "compat"].concat(args);
        runner.running = true;
    }
    function loadCatalog(refresh) {
        catalogFor = source;
        catalog = [];
        catalogProc.command = [Paths.bin, "compat", "catalog", source, "--json"].concat(refresh ? ["--refresh"] : []);
        catalogProc.running = true;
    }
    function statusText(p) {
        if (ThirdParty.errors[p.key])
            return "⚠ Didn't load: " + ThirdParty.errors[p.key];
        if (p.status === "ok")
            return "Should work fully";
        if (p.status === "partial")
            return "Partly works: " + p.issues.concat(p.notes).slice(0, 2).join("; ") + (p.issues.length + p.notes.length > 2 ? "; …" : "");
        return "Won't run: " + p.issues.concat(p.notes).slice(0, 2).join("; ");
    }

    Process {
        id: runner
        stdout: StdioCollector { id: out }
        stderr: StdioCollector { id: err }
        onExited: code => {
            page.status = (code === 0 ? out.text.trim() : err.text.trim() || out.text.trim()).replace(/^(flamenco|compat): /, "");
            ThirdParty.refresh();
            if (page.catalogFor !== "")
                page.loadCatalog(false);
        }
    }
    Process {
        id: catalogProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    page.catalog = JSON.parse(text);
                } catch (e) {
                    page.catalog = [];
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) page.status = text.trim().split("\n").pop().replace(/^flamenco: /, "")
        }
    }

    // ── a plugin's own settings ──
    Group {
        id: settingsGroup
        visible: plugin !== null
        readonly property var plugin: ThirdParty.find(ThirdParty.settingsKey)
        title: plugin ? plugin.name + " settings" : "Settings"
        property var item: null
        property string error: ""

        function build() {
            if (item) {
                item.destroy();
                item = null;
            }
            error = "";
            const file = plugin?.entries?.settings;
            if (!file)
                return;
            const comp = Qt.createComponent("file://" + file);
            const make = () => {
                if (comp.status === Component.Error) {
                    error = comp.errorString().trim().split("\n")[0];
                    return;
                }
                const props = plugin.kind === "noctalia" ? { pluginApi: ThirdParty.noctaliaApi(plugin.key) } : { pluginId: plugin.id, pluginService: ThirdParty.dms() };
                item = comp.createObject(settingsHost, props);
                if (!item)
                    error = "couldn't create it";
            };
            if (comp.status === Component.Loading)
                comp.statusChanged.connect(make);
            else
                make();
        }
        onPluginChanged: Qt.callLater(build)
        Component.onDestruction: if (item) item.destroy()

        Item {
            id: settingsHost
            Layout.fillWidth: true
            Layout.margins: Theme.sp4
            implicitHeight: settingsGroup.item ? Math.max(settingsGroup.item.implicitHeight, settingsGroup.item.height) : 0
            Binding {
                when: settingsGroup.item !== null
                target: settingsGroup.item
                property: "width"
                value: settingsHost.width
            }
        }
        SettingRow {
            visible: settingsGroup.error !== ""
            title: "Its settings didn't load"
            subtitle: settingsGroup.error
            icon: "error"
        }
        SettingRow {
            title: settingsGroup.plugin?.kind === "noctalia" ? "Save" : "Done"
            subtitle: settingsGroup.plugin?.kind === "noctalia" ? "Noctalia plugins keep changes when you save" : "Changes are kept as you make them"
            icon: "save"
            Row {
                spacing: 8
                FButton {
                    visible: settingsGroup.plugin?.kind === "noctalia" && typeof settingsGroup.item?.saveSettings === "function"
                    text: "Save"
                    onClicked: {
                        settingsGroup.item.saveSettings();
                        page.status = settingsGroup.plugin.name + ": saved";
                    }
                }
                FButton {
                    text: "Close"
                    variant: "tonal"
                    onClicked: ThirdParty.settingsKey = ""
                }
            }
        }
    }

    Group {
        title: "Installed"
        SettingRow {
            visible: ThirdParty.plugins.length === 0
            title: ThirdParty.loading ? "Looking…" : "None yet"
            subtitle: "Get some from the catalogs below, or install one from its address"
            icon: "extension"
        }
        Repeater {
            model: ThirdParty.plugins
            SettingRow {
                id: row
                required property var modelData
                readonly property bool on: ThirdParty.isEnabled(modelData.key)
                readonly property bool runs: modelData.status !== "unsupported"
                title: modelData.name + (modelData.version ? " " + modelData.version : "") + "  ·  " + (modelData.kind === "noctalia" ? "Noctalia" : "DMS")
                subtitle: page.statusText(modelData) + (modelData.description ? "\n" + modelData.description : "") + (modelData.author ? " · by " + modelData.author : "")
                icon: ThirdParty.errors[modelData.key] || !runs ? "extension_off" : modelData.status === "ok" ? "extension" : "warning"
                Row {
                    spacing: 4
                    FIconButton {
                        visible: !!row.modelData.entries.settings
                        icon: "settings"
                        size: 32
                        onClicked: ThirdParty.settingsKey = ThirdParty.settingsKey === row.modelData.key ? "" : row.modelData.key
                    }
                    FIconButton {
                        visible: row.on && row.modelData.kind === "noctalia" && !!row.modelData.entries.panel
                        icon: "open_in_new"
                        size: 32
                        onClicked: {
                            Panels.settingsOpen = false;
                            ThirdParty.openPanel(row.modelData.key, "", null);
                        }
                    }
                    FIconButton {
                        icon: "info"
                        size: 32
                        onClicked: page.status = row.modelData.name + ": " + (row.modelData.issues.concat(row.modelData.notes).join("; ") || "nothing missing")
                    }
                    FIconButton {
                        visible: row.modelData.origin !== ""
                        icon: "update"
                        size: 32
                        onClicked: {
                            page.cli(["update", row.modelData.key]);
                            ThirdParty.reload(row.modelData.key);
                        }
                    }
                    FIconButton {
                        icon: "folder_open"
                        size: 32
                        onClicked: Quickshell.execDetached(["xdg-open", row.modelData.source])
                    }
                    FIconButton {
                        icon: "delete"
                        size: 32
                        iconColor: Theme.error
                        onClicked: {
                            ThirdParty.setEnabled(row.modelData.key, false);
                            ThirdParty.clearData(row.modelData.key);
                            page.cli(["remove", row.modelData.key]);
                        }
                    }
                    FSwitch {
                        anchors.verticalCenter: parent.verticalCenter
                        enabled: row.runs
                        checked: row.on
                        onToggled: c => {
                            ThirdParty.setEnabled(row.modelData.key, c);
                            if (c)
                                ThirdParty.reload(row.modelData.key);
                        }
                    }
                }
            }
        }
        SettingRow {
            visible: Object.keys(ThirdParty.barWidgets).length > 0
            title: "Their bar widgets"
            subtitle: "Turned-on plugins with a bar widget are listed in Bar → Widgets, as \"name (Noctalia)\" or \"name (DMS)\""
            icon: "toolbar"
            FButton {
                text: "Bar settings"
                variant: "text"
                onClicked: Panels.settingsPage = "bar"
            }
        }
        SettingRow {
            title: "Reload"
            subtitle: "After editing a plugin's files, or updating one"
            icon: "refresh"
            FButton {
                text: "Reload"
                variant: "tonal"
                onClicked: {
                    for (const p of ThirdParty.plugins)
                        ThirdParty.reload(p.key);
                    ThirdParty.refresh();
                    page.cli(["list"]);
                }
            }
        }
    }

    Group {
        title: "Get plugins"
        SettingRow {
            title: "Catalog"
            subtitle: page.source === "noctalia" ? "Noctalia's plugin repository (noctalia-plugins). Each is checked once downloaded."
                : "DMS's plugin registry. Plugins come from their authors' repositories; each is checked once installed."
            icon: "storefront"
            Row {
                spacing: 8
                FSegmented {
                    implicitWidth: 240
                    options: [{ value: "noctalia", label: "Noctalia" }, { value: "dms", label: "DMS" }]
                    current: page.source
                    onSelected: v => {
                        page.source = v;
                        page.shown = 30;
                        if (page.catalogFor !== "")
                            page.loadCatalog(false);
                    }
                }
                FButton {
                    text: page.catalogFor === "" ? "Show" : "Refresh"
                    variant: "tonal"
                    disabled: catalogProc.running
                    onClicked: page.loadCatalog(page.catalogFor !== "")
                }
            }
        }
        SettingRow {
            visible: page.catalogFor !== ""
            title: catalogProc.running ? "Downloading the list…" : page.matches.length + " plugins"
            icon: "search"
            FTextField {
                implicitWidth: 280
                placeholder: "Search"
                onEdited: t => {
                    page.query = t;
                    page.shown = 30;
                }
            }
        }
        Repeater {
            model: page.catalogFor !== "" ? page.matches.slice(0, page.shown) : []
            SettingRow {
                id: cat
                required property var modelData
                title: modelData.name + (modelData.version ? " " + modelData.version : "") + (modelData.official ? "  ·  official" : "")
                subtitle: (modelData.status === "ok" ? "Should work fully" : modelData.status === "partial" ? "Partly works: " + modelData.issues.concat(modelData.notes).slice(0, 2).join("; ")
                    : modelData.status === "unknown" ? "Checked once installed" : "Won't run: " + modelData.issues.concat(modelData.notes).slice(0, 2).join("; "))
                    + (modelData.description ? "\n" + modelData.description : "") + (modelData.author ? " · by " + modelData.author : "")
                icon: modelData.status === "unsupported" ? "extension_off" : modelData.status === "ok" ? "extension" : "help"
                FButton {
                    text: cat.modelData.installed ? "Installed" : "Install"
                    variant: cat.modelData.installed ? "text" : "filled"
                    disabled: cat.modelData.installed || runner.running || cat.modelData.status === "unsupported"
                    onClicked: page.cli(["install", cat.modelData.spec])
                }
            }
        }
        SettingRow {
            visible: page.catalogFor !== "" && page.matches.length > page.shown
            title: (page.matches.length - page.shown) + " more"
            icon: "expand_more"
            FButton {
                text: "Show more"
                variant: "tonal"
                onClicked: page.shown += 30
            }
        }
        SettingRow {
            title: "Install from an address"
            subtitle: "A git address (a GitHub folder link works too; add #ID when a repository has several plugins) or a folder"
            icon: "download"
            Row {
                spacing: 8
                FTextField { id: src; implicitWidth: 300; placeholder: "https://github.com/someone/dms-plugins#myPlugin" }
                FButton {
                    text: "Install"
                    disabled: src.text.trim() === "" || runner.running
                    onClicked: {
                        page.cli(["install", src.text.trim()]);
                        src.text = "";
                    }
                }
            }
        }
        SettingRow {
            visible: page.status !== ""
            title: page.status
            icon: runner.running ? "hourglass_top" : "info"
        }
    }

    Group {
        title: "What works"
        SettingRow {
            title: "Noctalia plugins"
            subtitle: "Plugins for Noctalia 4 (QML): bar widgets, panels, settings and Main.qml. Not yet: desktop widgets, control center buttons and launcher providers. Noctalia 5's plugins (Luau) can't run."
            icon: "check_circle"
        }
        SettingRow {
            title: "DMS plugins"
            subtitle: "Plugins for DankMaterialShell 1.x: bar widgets with their popouts, settings, and daemons. Not yet: launcher, desktop and control center plugins, or ones that talk to DMS's own backend (dms)."
            icon: "check_circle"
        }
        SettingRow {
            title: "How it works"
            subtitle: "Flamenco keeps a copy of each plugin with its imports pointed at a compatibility layer: Noctalia's and DMS's widgets (both MIT licensed) colored by Flamenco's theme, and their services backed by Flamenco's. From a terminal: flamenco compat list | catalog | install | update | remove"
            icon: "info"
        }
    }
}
