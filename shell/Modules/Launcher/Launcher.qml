import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services
import qs.Widgets

// App launcher. Prefixes:  =  calculator   >  run command   ;  clipboard (cliphist)
//                          :  emoji        #  colors (and the screen color picker)   /  files
// Searching apps also finds open windows, Flamenco's settings, session actions (lock,
// log out…) and offers a web search (Settings → Launcher). Alt+P (or a right-click) pins
// the app under the cursor; pinned apps come first. The grid view shows apps by category until you type.
Variants {
    model: Quickshell.screens

    OverlayPanel {
        id: panel
        name: "launcher"
        // Settings → Launcher → Position; "bar" opens next to the bar's start (where the launcher button is)
        placement: Settings.data.launcher.position
        hAlign: "left"
        exclusiveKeyboard: true
        cardWidth: Settings.data.launcher.width

        property string query: ""
        readonly property var lc: Settings.data.launcher
        readonly property string mode: query.startsWith("=") && lc.calculator ? "calc" : query.startsWith(">") ? "run" : query.startsWith(";") && lc.clipboard ? "clip"
            : query.startsWith(":") && lc.emoji ? "emoji" : query.startsWith("#") && lc.colors ? "color" : query.startsWith("/") && (lc.files ?? true) ? "files"
            : plugin ? "plugin" : "apps"
        // a plugin's launcher extension whose prefix starts the query (Settings → Plugins)
        readonly property var plugin: Plugins.launchers.find(l => query.startsWith(l.prefix)) ?? null
        property var pluginResults: []
        property var emojis: []                // [[glyph, name], …] from `flamenco emoji`
        readonly property string term: mode === "apps" ? query : mode === "plugin" ? query.slice(plugin.prefix.length).trim() : query.slice(1).trim()
        onTermChanged: {
            if (mode === "plugin")
                pluginTimer.restart();
            else if (mode === "files")
                fileTimer.restart();
        }
        property var clips: []
        property var files: []
        property var settingsIndex: []
        property string category: "all"
        readonly property bool grid: (lc.view || "list") === "grid" && mode === "apps" && query === ""
        readonly property var pinned: lc.pinned || []

        // Settings → Launcher → Web search engine
        readonly property string webUrl: ({ duckduckgo: "https://duckduckgo.com/?q=%s", google: "https://www.google.com/search?q=%s",
                bing: "https://www.bing.com/search?q=%s", brave: "https://search.brave.com/search?q=%s",
                startpage: "https://www.startpage.com/do/search?q=%s", ecosia: "https://www.ecosia.org/search?q=%s" })[lc.webEngine || "duckduckgo"]
            ?? (/^https:\/\/.*%s/.test(lc.webEngine || "") ? lc.webEngine : "https://duckduckgo.com/?q=%s")
        readonly property var sessionActions: [
            { id: "lock", title: "Lock the screen", keys: ["lock"], icon: "lock" },
            { id: "suspend", title: "Suspend", keys: ["suspend", "sleep"], icon: "bedtime" },
            { id: "hibernate", title: "Hibernate", keys: ["hibernate"], icon: "downloading" },
            { id: "logout", title: "Log out", keys: ["log out", "logout", "sign out"], icon: "logout" },
            { id: "reboot", title: "Restart", keys: ["restart", "reboot"], icon: "restart_alt" },
            { id: "shutdown", title: "Shut down", keys: ["shut down", "shutdown", "power off", "poweroff"], icon: "power_settings_new" }
        ]
        // the app grid's categories (freedesktop's main ones, folded together)
        readonly property var categories: [
            { id: "all", label: "All", cats: [] }, { id: "internet", label: "Internet", cats: ["Network", "WebBrowser", "Email", "Chat"] },
            { id: "office", label: "Office", cats: ["Office"] }, { id: "media", label: "Media", cats: ["AudioVideo", "Audio", "Video"] },
            { id: "graphics", label: "Graphics", cats: ["Graphics"] }, { id: "dev", label: "Development", cats: ["Development"] },
            { id: "games", label: "Games", cats: ["Game"] }, { id: "system", label: "System", cats: ["System", "Settings"] },
            { id: "utility", label: "Utilities", cats: ["Utility", "Accessories"] }, { id: "learn", label: "Learning", cats: ["Education", "Science"] }
        ]
        function inCategory(e, id) {
            const c = categories.find(x => x.id === id);
            if (!c || id === "all")
                return true;
            const mine = e.categories ?? [];
            return c.cats.some(x => mine.includes(x));
        }
        // apps for the grid / an empty search: pinned first, then by use
        readonly property var gridApps: {
            const all = Apps.search("");
            const pins = pinned.map(id => all.find(e => e.id === id)).filter(Boolean);
            return pins.concat(all.filter(e => !pinned.includes(e.id))).filter(e => inCategory(e, category));
        }
        function togglePin(e) {
            if (!e)
                return;
            lc.pinned = pinned.includes(e.id) ? pinned.filter(x => x !== e.id) : [e.id].concat(pinned);
        }
        function appItem(e) {
            return { kind: "app", entry: e, title: e.name, subtitle: e.genericName || e.comment || "", icon: e.icon, pinned: pinned.includes(e.id) };
        }

        readonly property var results: {
            if (mode === "calc") {
                const r = calc(term);
                return r === null ? [] : [{ kind: "calc", title: String(r), subtitle: "Enter to copy · " + term, icon: "calculate" }];
            }
            if (mode === "run")
                return term ? [{ kind: "run", title: term, subtitle: "Run in shell", icon: "terminal" }, { kind: "runterm", title: term, subtitle: "Run in " + Settings.data.general.terminal, icon: "terminal" }] : [];
            if (mode === "plugin") {
                if (pluginResults.length === 0)
                    return [{ kind: "hint", title: plugin.name, subtitle: plugin.hint || "Type to search", icon: "extension" }];
                return pluginResults.slice(0, 50).map(r => ({ kind: "plugin", title: String(r.title ?? ""), subtitle: String(r.subtitle ?? ""), icon: String(r.icon || "extension"), exec: r.exec, copy: r.copy, open: r.open }));
            }
            if (mode === "emoji") {
                const words = term.toLowerCase().split(/\s+/).filter(Boolean);
                const hits = words.length ? emojis.filter(e => words.every(w => e[1].includes(w)))
                    : (lc.recentEmoji || []).map(g => emojis.find(e => e[0] === g)).filter(Boolean).concat(emojis.filter(e => !(lc.recentEmoji || []).includes(e[0])));
                return hits.slice(0, 80).map(e => ({ kind: "emoji", glyph: e[0], title: e[1].charAt(0).toUpperCase() + e[1].slice(1), subtitle: "Enter to copy", icon: "" }));
            }
            if (mode === "color") {
                const out = [{ kind: "pickcolor", title: "Pick a color on screen", subtitle: "Copies its hex code", icon: "colorize" }];
                const c = parseColor(term);
                if (c) {
                    const hex = "#" + [c.r, c.g, c.b].map(v => v.toString(16).padStart(2, "0")).join("");
                    const hsl = toHsl(c);
                    for (const t of [hex, "rgb(" + c.r + ", " + c.g + ", " + c.b + ")", "hsl(" + hsl.h + ", " + hsl.s + "%, " + hsl.l + "%)"])
                        out.push({ kind: "copy", title: t, subtitle: "Enter to copy", icon: "palette", swatch: hex });
                }
                return out;
            }
            if (mode === "clip") {
                const q = term.toLowerCase();
                return clips.filter(c => c.toLowerCase().includes(q)).slice(0, 50).map(c => ({ kind: "clip", line: c, title: c.split("\t").slice(1).join(" ").trim(), subtitle: "Clipboard", icon: "content_paste" }));
            }
            if (mode === "files") {
                if (!term)
                    return [{ kind: "hint", title: "Search your files", subtitle: "Type a name after /", icon: "folder_open" }];
                return files.map(f => ({ kind: "file", path: f.path, title: f.name, subtitle: f.dir, icon: f.folder ? "folder" : "description" }));
            }
            if (term === "")
                return gridApps.slice(0, 50).map(e => appItem(e));
            const q = term.toLowerCase();
            const out = Apps.search(term).slice(0, 40).map(e => appItem(e));
            // open windows
            if (lc.searchWindows ?? true)
                for (const w of Niri.windows.filter(w => String(w.title).toLowerCase().includes(q) || String(w.app_id).toLowerCase().includes(q)).slice(0, 6))
                    out.push({ kind: "window", win: w, title: w.title || w.app_id, subtitle: "Open window · " + (Apps.lookup(w.app_id)?.name ?? w.app_id), icon: Apps.lookup(w.app_id)?.icon ?? w.app_id });
            // lock, log out, restart…
            if ((lc.searchSession ?? true) && q.length >= 2)
                for (const a of sessionActions.filter(a => a.keys.some(k => k.startsWith(q))))
                    out.push({ kind: "session", action: a.id, title: a.title, subtitle: ["logout", "reboot", "shutdown"].includes(a.id) ? "Opens the power menu to confirm" : "Session", icon: a.icon });
            // Flamenco's settings
            if ((lc.searchSettings ?? true) && q.length >= 2) {
                const words = q.split(/\s+/);
                const hits = settingsIndex.filter(e => words.every(w => (e.title + " " + e.label + " " + e.group).toLowerCase().includes(w)))
                    .sort((a, b) => (a.title.toLowerCase().startsWith(q) ? 0 : 1) - (b.title.toLowerCase().startsWith(q) ? 0 : 1) || (a.kind === "page" ? -1 : 0) - (b.kind === "page" ? -1 : 0));
                for (const e of hits.slice(0, 4))
                    out.push({ kind: "setting", entry: e, title: e.title, subtitle: "Settings · " + e.label + (e.group && e.group !== e.title ? " › " + e.group : ""), icon: e.icon || "settings" });
            }
            if (lc.webSearch ?? true)
                out.push({ kind: "web", title: "Search the web for “" + term + "”", subtitle: (lc.webEngine || "duckduckgo").replace(/^https?:\/\/([^/]+).*/, "$1"), icon: "travel_explore" });
            return out;
        }

        // "#abc", "abc", "#aabbcc", "aabbcc(ff)"
        function parseColor(t) {
            const h = t.replace(/^#/, "").trim();
            if (!/^([0-9a-f]{3}|[0-9a-f]{6}|[0-9a-f]{8})$/i.test(h))
                return null;
            const full = h.length === 3 ? h.split("").map(x => x + x).join("") : h.slice(0, 6);
            return { r: parseInt(full.slice(0, 2), 16), g: parseInt(full.slice(2, 4), 16), b: parseInt(full.slice(4, 6), 16) };
        }
        function toHsl(c) {
            const r = c.r / 255, g = c.g / 255, b = c.b / 255;
            const mx = Math.max(r, g, b), mn = Math.min(r, g, b), l = (mx + mn) / 2;
            let h = 0, s = 0;
            if (mx !== mn) {
                const d = mx - mn;
                s = l > 0.5 ? d / (2 - mx - mn) : d / (mx + mn);
                h = mx === r ? (g - b) / d + (g < b ? 6 : 0) : mx === g ? (b - r) / d + 2 : (r - g) / d + 4;
                h /= 6;
            }
            return { h: Math.round(h * 360), s: Math.round(s * 100), l: Math.round(l * 100) };
        }

        function calc(expr) {
            if (!expr || !/^[0-9+\-*/().,%^\s]+$/.test(expr))
                return null;
            try {
                const v = Function('"use strict"; return (' + expr.replace(/\^/g, "**").replace(/,/g, ".") + ")")();
                return typeof v === "number" && isFinite(v) ? Math.round(v * 1e10) / 1e10 : null;
            } catch (e) {
                return null;
            }
        }

        function activate(item) {
            if (!item)
                return;
            if (item.kind === "app")
                Apps.launch(item.entry);
            else if (item.kind === "window")
                Niri.focusWindow(item.win.id);
            else if (item.kind === "file")
                Quickshell.execDetached(["xdg-open", item.path]);
            else if (item.kind === "web")
                Qt.openUrlExternally(webUrl.replace("%s", encodeURIComponent(term)));
            else if (item.kind === "setting") {
                if (item.entry.kind === "page")
                    Panels.settingsPage = item.entry.page;
                else
                    Panels.findSetting(item.entry.page, item.entry.title);
                Panels.settingsOpen = true;
            } else if (item.kind === "session") {
                // the ones that end the session go through the power menu, to confirm
                if (["logout", "reboot", "shutdown"].includes(item.action)) {
                    Panels.open("power", "");
                    return;
                }
                if (item.action === "lock")
                    Quickshell.execDetached([Paths.bin, "lock"]);
                else if (item.action === "suspend")
                    Power.suspend();
                else if (item.action === "hibernate")
                    Power.hibernate();
            }
            else if (item.kind === "calc")
                Quickshell.execDetached(["wl-copy", item.title]);
            else if (item.kind === "run")
                Quickshell.execDetached(["sh", "-c", item.title]);
            else if (item.kind === "runterm")
                Quickshell.execDetached(Paths.termHold(item.title));
            else if (item.kind === "clip")
                Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | cliphist decode | wl-copy', "sh", item.line]);
            else if (item.kind === "hint")
                return;
            else if (item.kind === "plugin") {
                if (item.exec)
                    Quickshell.execDetached(["sh", "-c", String(item.exec)]);
                else if (item.copy !== undefined)
                    Quickshell.execDetached(["wl-copy", String(item.copy)]);
                else if (item.open)
                    Quickshell.execDetached(["xdg-open", String(item.open)]);
            } else if (item.kind === "emoji") {
                Quickshell.execDetached(["wl-copy", item.glyph]);
                lc.recentEmoji = [item.glyph].concat((lc.recentEmoji || []).filter(g => g !== item.glyph)).slice(0, 24);
            } else if (item.kind === "copy")
                Quickshell.execDetached(["wl-copy", item.title]);
            else if (item.kind === "pickcolor")
                // after the launcher has closed, so it isn't what gets picked
                Quickshell.execDetached(["sh", "-c", 'sleep 0.35; exec "$1" pick-color', "sh", Paths.bin]);
            Panels.close();
        }

        onModeChanged: {
            if (mode === "plugin")
                pluginTimer.restart();
            else
                pluginResults = [];
            if (mode === "clip")
                clipProc.running = true;
            if (mode !== "files")
                files = [];
            else if (mode === "emoji" && emojis.length === 0 && !emojiProc.running)
                emojiProc.running = true;
        }
        onOpened: {
            // opened for a mode (e.g. ":" from the emoji shortcut)
            query = Panels.launcherQuery;
            field.text = Panels.launcherQuery;
            Panels.launcherQuery = "";
            list.currentIndex = 0;
            appGrid.currentIndex = 0;
            category = "all";
            field.focusInput();
            if ((lc.searchSettings ?? true) && settingsIndex.length === 0 && !indexProc.running)
                indexProc.running = true;
        }

        // a plugin's script, with what's typed after its prefix; one JSON result per line
        Timer {
            id: pluginTimer
            interval: 150
            onTriggered: {
                if (panel.mode !== "plugin")
                    return;
                pluginProc.running = false;
                pluginProc.command = [panel.plugin.script, panel.term];
                pluginProc.running = true;
            }
        }
        Process {
            id: pluginProc
            stdout: StdioCollector {
                onStreamFinished: {
                    const out = [];
                    for (const line of text.split("\n")) {
                        try {
                            if (line.trim())
                                out.push(JSON.parse(line));
                        } catch (e) {}
                    }
                    panel.pluginResults = out;
                }
            }
        }
        Process {
            id: emojiProc
            command: [Paths.bin, "emoji"]
            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        panel.emojis = JSON.parse(text);
                    } catch (e) {}
                }
            }
        }

        // "/": files, a moment after the typing stops
        Timer {
            id: fileTimer
            interval: 220
            onTriggered: {
                if (panel.mode !== "files" || !panel.term)
                    return;
                fileProc.running = false;
                fileProc.command = [Paths.bin, "files", panel.term];
                fileProc.running = true;
            }
        }
        Process {
            id: fileProc
            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        panel.files = JSON.parse(text);
                    } catch (e) {
                        panel.files = [];
                    }
                }
            }
        }
        Process {
            id: indexProc
            command: [Paths.bin, "settings-index", "--json"]
            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        panel.settingsIndex = JSON.parse(text);
                    } catch (e) {}
                }
            }
        }

        Process {
            id: clipProc
            command: ["cliphist", "list"]
            stdout: StdioCollector {
                onStreamFinished: panel.clips = text.split("\n").filter(Boolean)
            }
        }

        ColumnLayout {
            width: parent.width
            spacing: Theme.sp3

            FTextField {
                id: field
                Layout.fillWidth: true
                implicitHeight: 52
                radius: Theme.rLg
                icon: panel.mode === "calc" ? "calculate" : panel.mode === "run" ? "terminal" : panel.mode === "clip" ? "content_paste" : panel.mode === "emoji" ? "mood" : panel.mode === "color" ? "palette" : panel.mode === "files" ? "folder_open" : "search"
                placeholder: "Search apps, windows, settings   ·   = calc   > run   ; clips   : emoji   # color   / files"
                fontSize: Theme.fsLg
                onEdited: t => {
                    panel.query = t;
                    list.currentIndex = 0;
                }
                onAccepted: panel.grid ? panel.activate(panel.gridApps[appGrid.currentIndex] ? panel.appItem(panel.gridApps[appGrid.currentIndex]) : null) : panel.activate(panel.results[list.currentIndex])
                onKeyPressed: event => {
                    // Alt+P: pin or unpin the app under the cursor (Ctrl+P / Ctrl+N move, as in Emacs)
                    if (event.key === Qt.Key_P && event.modifiers & Qt.AltModifier) {
                        const cur = panel.results[list.currentIndex];
                        const e = panel.grid ? panel.gridApps[appGrid.currentIndex] : cur?.kind === "app" ? cur.entry : null;
                        if (e)
                            panel.togglePin(e);
                        event.accepted = true;
                        return;
                    }
                    // the grid: arrows move around it
                    if (panel.grid && [Qt.Key_Left, Qt.Key_Right, Qt.Key_Up, Qt.Key_Down].includes(event.key)) {
                        if (event.key === Qt.Key_Left) appGrid.moveCurrentIndexLeft();
                        else if (event.key === Qt.Key_Right) appGrid.moveCurrentIndexRight();
                        else if (event.key === Qt.Key_Up) appGrid.moveCurrentIndexUp();
                        else appGrid.moveCurrentIndexDown();
                        event.accepted = true;
                        return;
                    }
                    if (event.key === Qt.Key_Down || (event.key === Qt.Key_N && event.modifiers & Qt.ControlModifier)) {
                        list.incrementCurrentIndex();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Up || (event.key === Qt.Key_P && event.modifiers & Qt.ControlModifier)) {
                        list.decrementCurrentIndex();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Escape) {
                        Panels.close();
                        event.accepted = true;
                    }
                }
            }

            ListView {
                id: list
                Layout.fillWidth: true
                implicitHeight: Math.min(count, Settings.data.launcher.maxResults) * 58
                clip: true
                model: panel.results
                keyNavigationWraps: true
                boundsBehavior: Flickable.OvershootBounds

                SmoothWheel {
                    view: list
                }
                highlightMoveDuration: Theme.durMed
                highlightResizeDuration: 0
                highlightFollowsCurrentItem: true
                visible: count > 0 && !panel.grid

                Behavior on implicitHeight { Anim { easing.bezierCurve: Theme.curves.emphasizedDecel } }

                highlight: Rectangle {
                    radius: Theme.rMd
                    color: Theme.alpha(Theme.accent, 0.16)
                    border.width: 1
                    border.color: Theme.alpha(Theme.accent, 0.4)
                }

                delegate: Item {
                    id: row
                    required property var modelData
                    required property int index
                    width: list.width
                    height: 58

                    // staggered entrance
                    opacity: 0
                    Component.onCompleted: appear.start()
                    NumberAnimation {
                        id: appear
                        target: row
                        property: "opacity"
                        to: 1
                        duration: Theme.durA("launcher", 280)
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 14

                        Item {
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 36
                            AppIcon {
                                anchors.centerIn: parent
                                visible: row.modelData.kind === "app" || row.modelData.kind === "window"
                                implicitSize: 34
                                name: row.modelData.kind === "app" || row.modelData.kind === "window" ? row.modelData.icon : ""
                                scale: list.currentIndex === row.index && Theme.hoverZoom ? 1.1 : 1
                                Behavior on scale { Anim { easing.bezierCurve: Theme.curves.springFast } }
                            }
                            FIcon {
                                anchors.centerIn: parent
                                visible: row.modelData.kind !== "app" && row.modelData.kind !== "window" && row.modelData.kind !== "emoji" && !row.modelData.swatch
                                icon: row.modelData.icon
                                size: 26
                                color: Theme.accent
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: row.modelData.kind === "emoji"
                                text: row.modelData.glyph ?? ""
                                font.pixelSize: 28
                            }
                            Rectangle {
                                anchors.centerIn: parent
                                visible: !!row.modelData.swatch
                                width: 30
                                height: 30
                                radius: 15
                                color: row.modelData.swatch ?? "transparent"
                                border.width: 1
                                border.color: Theme.border
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            FText {
                                Layout.fillWidth: true
                                text: row.modelData.title
                                font.weight: Font.DemiBold
                                font.pixelSize: row.modelData.kind === "calc" ? Theme.fsXl : Theme.fsMd
                                elide: Text.ElideRight
                            }
                            FText {
                                Layout.fillWidth: true
                                visible: text !== ""
                                text: row.modelData.subtitle
                                dim: true
                                font.pixelSize: Theme.fsSm
                                elide: Text.ElideRight
                            }
                        }

                        FIcon {
                            visible: !!row.modelData.pinned
                            icon: "keep"
                            size: 16
                            color: Theme.accent
                        }
                        FIcon {
                            icon: "keyboard_return"
                            size: 18
                            color: Theme.textDim
                            opacity: list.currentIndex === row.index ? 1 : 0
                            Behavior on opacity { Anim {} }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onEntered: list.currentIndex = row.index
                        // right-click pins or unpins an app
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                if (row.modelData.kind === "app")
                                    panel.togglePin(row.modelData.entry);
                            } else {
                                panel.activate(row.modelData);
                            }
                        }
                    }
                }
            }

            // ── the grid: apps by category, until you type ──
            Flow {
                visible: panel.grid
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: panel.categories.filter(c => c.id === "all" || Apps.all.some(e => panel.inCategory(e, c.id)))
                    Rectangle {
                        id: chip
                        required property var modelData
                        readonly property bool on: panel.category === modelData.id
                        implicitWidth: chipText.implicitWidth + 24
                        implicitHeight: 30
                        radius: 15
                        color: on ? Theme.accent : Theme.alpha(Theme.text, 0.07)
                        FText {
                            id: chipText
                            anchors.centerIn: parent
                            text: chip.modelData.label
                            font.pixelSize: Theme.fsSm
                            font.weight: Font.DemiBold
                            color: chip.on ? Theme.onAccent : Theme.text
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                panel.category = chip.modelData.id;
                                appGrid.currentIndex = 0;
                            }
                        }
                    }
                }
            }
            GridView {
                id: appGrid
                visible: panel.grid
                Layout.fillWidth: true
                readonly property int cols: Math.max(3, Math.floor(width / 112))
                cellWidth: Math.floor(width / cols)
                cellHeight: 108
                Layout.preferredHeight: Math.min(Math.ceil(count / cols), 4) * cellHeight
                clip: true
                model: panel.grid ? panel.gridApps : []
                keyNavigationWraps: true
                boundsBehavior: Flickable.OvershootBounds
                highlightMoveDuration: Theme.durShort
                highlight: Rectangle {
                    radius: Theme.rLg
                    color: Theme.alpha(Theme.accent, 0.16)
                    border.width: 1
                    border.color: Theme.alpha(Theme.accent, 0.4)
                }
                SmoothWheel { view: appGrid }
                delegate: Item {
                    id: cell
                    required property var modelData
                    required property int index
                    readonly property bool pin: panel.pinned.includes(modelData.id)
                    width: appGrid.cellWidth
                    height: appGrid.cellHeight
                    ColumnLayout {
                        anchors.centerIn: parent
                        width: parent.width - 12
                        spacing: 6
                        AppIcon {
                            Layout.alignment: Qt.AlignHCenter
                            implicitSize: 48
                            name: cell.modelData.icon
                            scale: appGrid.currentIndex === cell.index && Theme.hoverZoom ? 1.08 : 1
                            Behavior on scale { Anim { easing.bezierCurve: Theme.curves.springFast } }
                            FIcon {
                                visible: cell.pin
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: -4
                                icon: "keep"
                                size: 14
                                fill: 1
                                color: Theme.accent
                            }
                        }
                        FText {
                            Layout.fillWidth: true
                            text: cell.modelData.name
                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: Theme.fsSm
                            elide: Text.ElideRight
                            maximumLineCount: 2
                            wrapMode: Text.Wrap
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onEntered: appGrid.currentIndex = cell.index
                        // right-click pins or unpins it
                        onClicked: mouse => mouse.button === Qt.RightButton ? panel.togglePin(cell.modelData) : panel.activate(panel.appItem(cell.modelData))
                    }
                }
            }

            FText {
                visible: list.count === 0 && panel.query !== ""
                Layout.alignment: Qt.AlignHCenter
                Layout.margins: Theme.sp4
                text: "No results"
                dim: true
            }
        }
    }
}
