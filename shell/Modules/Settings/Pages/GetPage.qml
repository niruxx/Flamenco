import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services
import qs.Widgets

// Settings → Get themes: KDE's "Get New…" in one place. Search the KDE Store
// (icon and cursor themes, GTK themes, color schemes, wallpapers) and Fontsource
// (fonts), install with one click, then use it. `flamenco get` does the work:
// downloads over https only, unpacks in a private folder first and installs into
// your home folder (never the system), and remembers what it put there so
// Remove takes away only that.
Page {
    id: page
    title: I18n.tr("Get themes")
    subtitle: I18n.tr("Find icon and cursor themes, GTK themes, color schemes and wallpapers on the KDE Store, and fonts on Fontsource. They install into your home folder only.")

    property string kind: "icons"
    property string query: ""
    property string sort: "rating"            // store: rating | downloads | new
    property string category: "all"           // fonts: all | sans-serif | serif | monospace | display | handwriting
    property int pageNo: 1
    property var results: []
    property bool more: false
    property int total: 0
    property string error: ""
    property bool loading: false
    property int seq: 0                       // the newest search; older answers are dropped
    property var busy: ({})                   // id → "install" | "remove"
    property var chosen: ({})                 // id → which of its files (0: the best match)
    property var changed: ({})                // id → { installed, ours, names } since the search
    property string status: ""

    readonly property bool fonts: kind === "fonts"
    readonly property var kinds: [
        { value: "icons", label: I18n.tr("Icons"), icon: "category" },
        { value: "cursors", label: I18n.tr("Cursors"), icon: "arrow_selector_tool" },
        { value: "gtk", label: I18n.tr("GTK"), icon: "web_asset" },
        { value: "colors", label: I18n.tr("Colors"), icon: "palette" },
        { value: "wallpapers", label: I18n.tr("Wallpapers"), icon: "wallpaper" },
        { value: "fonts", label: I18n.tr("Fonts"), icon: "font_download" },
        { value: "palettes", label: I18n.tr("Palettes"), icon: "palette" }
    ]
    readonly property string source: fonts ? "Fontsource (fontsource.org)" : kind === "palettes" ? "the DMS theme registry" : "the KDE Store (store.kde.org)"

    function search(again) {
        pageNo = again ? pageNo + 1 : 1;
        if (!again) {
            results = [];
            changed = {};
            error = "";
        }
        seq++;
        loading = true;
        searcher.createObject(page, { tag: seq, append: !!again, command: [Paths.bin, "get", "search", kind, query, String(pageNo), fonts ? category : sort] }).running = true;
    }
    Component.onCompleted: search(false)
    onKindChanged: search(false)
    onSortChanged: search(false)
    onCategoryChanged: search(false)

    function setBusy(id, what) {
        const b = Object.assign({}, busy);
        if (what)
            b[id] = what;
        else
            delete b[id];
        busy = b;
    }
    // installs change a card in place (the list itself stays, so nothing is rebuilt)
    function update(id, change) {
        const c = Object.assign({}, changed);
        c[id] = change;
        changed = c;
    }
    function install(r) {
        setBusy(r.id, "install");
        status = "Installing " + r.name + "…";
        runner.createObject(page, { item: r, remove: false, command: [Paths.bin, "get", "install", kind, r.id, String(chosen[r.id] ?? 0)] }).running = true;
    }
    function uninstall(r) {
        setBusy(r.id, "remove");
        runner.createObject(page, { item: r, remove: true, command: [Paths.bin, "get", "remove", kind, r.id] }).running = true;
    }
    // GTK themes come in variants: the one that matches light or dark mode
    function variant(names) {
        const dark = names.filter(n => /dark/i.test(n));
        const light = names.filter(n => !/dark/i.test(n));
        const pool = (Theme.dark ? dark : light).length ? (Theme.dark ? dark : light) : names;
        return pool.slice().sort((a, b) => a.length - b.length)[0] ?? "";
    }
    function usable(r) {
        return r.installed && kind !== "colors" && (fonts || (kind === "wallpapers" ? r.paths || [] : r.names || []).length > 0);
    }
    function inUse(r) {
        const n = r.names || [];
        switch (kind) {
        case "icons": return n.includes(Settings.data.apps.iconTheme);
        case "cursors": return n.includes(Settings.data.apps.cursorTheme);
        case "gtk": return n.includes(Settings.data.apps.gtkTheme);
        case "fonts": return r.name === Settings.data.appearance.fontFamily || r.name === Settings.data.appearance.monoFamily;
        case "wallpapers": return (r.paths || []).length > 0 && Wallpapers.current === r.paths[0];
        case "palettes": return n.includes(Settings.data.appearance.palette);
        }
        return false;
    }
    function use(r) {
        const n = r.names || [];
        switch (kind) {
        case "icons": Settings.data.apps.iconTheme = n[0]; break;
        case "cursors": Settings.data.apps.cursorTheme = n[0]; break;
        case "gtk": Settings.data.apps.gtkTheme = variant(n); break;
        case "fonts":
            if (r.category === "monospace")
                Settings.data.appearance.monoFamily = r.name;
            else
                Settings.data.appearance.fontFamily = r.name;
            break;
        case "wallpapers": Wallpapers.set(r.paths[0], ""); break;
        case "palettes": Settings.data.appearance.palette = n[0]; break;
        }
        status = kind === "fonts" ? r.name + " is now the shell's " + (r.category === "monospace" ? "monospace font" : "font")
            : kind === "wallpapers" ? "Wallpaper set" : kind === "palettes" ? r.name + " is the palette now (Appearance has it too)" : "Applied to apps (Settings → App Theming)";
    }
    function fmtCount(v) {
        return v >= 1e6 ? (v / 1e6).toFixed(1) + "M" : v >= 1e3 ? Math.round(v / 1e3) + "k" : String(v);
    }

    // ── what to look for ──
    FSegmented {
        Layout.fillWidth: true
        options: page.kinds
        current: page.kind
        onSelected: v => page.kind = v
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.sp2
        FTextField {
            id: field
            Layout.fillWidth: true
            icon: "search"
            placeholder: I18n.tr("Search ") + (page.kinds.find(k => k.value === page.kind)?.label ?? "").toLowerCase() + " on " + page.source
            onAccepted: {
                page.query = text.trim();
                page.search(false);
            }
        }
        FDropdown {
            implicitWidth: 170
            visible: !page.fonts && page.kind !== "palettes"
            options: [{ value: "rating", label: I18n.tr("Best rated") }, { value: "downloads", label: I18n.tr("Most downloaded") }, { value: "new", label: I18n.tr("Newest") }]
            current: page.sort
            onSelected: v => page.sort = v
        }
        FDropdown {
            implicitWidth: 170
            visible: page.fonts
            options: [{ value: "all", label: I18n.tr("All fonts") }, { value: "sans-serif", label: I18n.tr("Sans serif") }, { value: "serif", label: I18n.tr("Serif") }, { value: "monospace", label: I18n.tr("Monospace") }, { value: "display", label: I18n.tr("Display") }, { value: "handwriting", label: I18n.tr("Handwriting") }]
            current: page.category
            onSelected: v => page.category = v
        }
    }
    FText {
        Layout.fillWidth: true
        visible: text !== ""
        text: page.error !== "" ? page.error : page.status !== "" ? page.status
            : page.total > 0 ? page.total.toLocaleString(Qt.locale(), "f", 0) + " found on " + page.source : ""
        color: page.error !== "" ? Theme.error : Theme.textDim
        font.pixelSize: Theme.fsSm
        wrapMode: Text.Wrap
    }

    // ── what was found ──
    Item {
        Layout.fillWidth: true
        implicitHeight: grid.implicitHeight
        Flow {
            id: grid
            width: parent.width
            spacing: Theme.sp3
            readonly property int cols: width > 700 ? 3 : 2
            readonly property real cardW: Math.floor((width - spacing * (cols - 1)) / cols)
            Repeater {
                model: ScriptModel { values: page.results }
                Rectangle {
                    id: card
                    required property var modelData
                    readonly property var r: Object.assign({}, modelData, page.changed[modelData.id] || {})
                    readonly property string doing: page.busy[r.id] ?? ""
                    readonly property bool current: page.inUse(r)
                    width: grid.cardW
                    height: body.implicitHeight + Theme.sp3 * 2
                    radius: Math.max(12, Theme.rLg)
                    color: Theme.alpha(Theme.surface, Math.min(1, Theme.settingsOp + 0.04))
                    border.width: current ? 2 : 1
                    border.color: current ? Theme.accent : Theme.alpha(Theme.text, 0.06)
                    opacity: 0
                    scale: 0.97
                    Component.onCompleted: {
                        opacity = 1;
                        scale = 1;
                    }
                    Behavior on opacity { Anim {} }
                    Behavior on scale { Anim {} }

                    ColumnLayout {
                        id: body
                        x: Theme.sp3
                        y: Theme.sp3
                        width: parent.width - Theme.sp3 * 2
                        spacing: Theme.sp2

                        // the preview: the store's picture, or the font itself
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.round(width * (page.fonts ? 0.42 : 0.6))
                            radius: Theme.rMd
                            color: Theme.alpha(Theme.text, 0.05)
                            clip: true
                            SafeImage {
                                id: pic
                                visible: !page.fonts
                                anchors.fill: parent
                                path: page.fonts ? "" : (card.r.thumb || card.r.preview || "")
                                fillMode: Image.PreserveAspectCrop
                                sourceSize.width: 480
                                opacity: pic.status === Image.Ready ? 1 : 0
                                Behavior on opacity { Anim {} }
                            }
                            // palettes: their colors, under the preview (or instead of it)
                            Row {
                                visible: page.kind === "palettes" && pic.status !== Image.Ready
                                anchors.fill: parent
                                Repeater {
                                    model: card.r.swatch || []
                                    Rectangle {
                                        required property string modelData
                                        width: parent.width / Math.max(1, (card.r.swatch || []).length)
                                        height: parent.height
                                        color: modelData
                                    }
                                }
                            }
                            FIcon {
                                visible: !page.fonts && page.kind !== "palettes" && pic.status !== Image.Ready
                                anchors.centerIn: parent
                                icon: pic.status === Image.Error || !(card.r.thumb || card.r.preview) ? "image_not_supported" : "hourglass_empty"
                                size: 28
                                color: Theme.textDim
                            }
                            FText {
                                visible: page.fonts
                                anchors.fill: parent
                                anchors.margins: Theme.sp3
                                text: I18n.tr("Aa Bb Cc 123\nThe quick brown fox")
                                font.family: card.r.installed ? card.r.name : Theme.fontFamily
                                font.pixelSize: Theme.fsLg
                                wrapMode: Text.Wrap
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                                opacity: card.r.installed ? 1 : 0.5
                            }
                            // in use / installed
                            Rectangle {
                                visible: card.r.installed
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 6
                                height: 22
                                width: tag.implicitWidth + 16
                                radius: 11
                                color: card.current ? Theme.accent : Theme.alpha(Theme.bg, 0.8)
                                FText {
                                    id: tag
                                    anchors.centerIn: parent
                                    text: card.current ? I18n.tr("In use") : I18n.tr("Installed")
                                    font.pixelSize: Theme.fsXs
                                    font.weight: Font.DemiBold
                                    color: card.current ? Theme.onAccent : Theme.text
                                }
                            }
                        }

                        FText {
                            Layout.fillWidth: true
                            text: card.r.name
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }
                        FText {
                            Layout.fillWidth: true
                            text: page.fonts ? [card.r.category, (card.r.weights || []).length + " weights" + (card.r.italic ? " + italics" : ""), card.r.author].filter(s => s).join(" · ")
                                : page.kind === "palettes" ? (card.r.author ? "by " + card.r.author : "")
                                : ["by " + card.r.author, "★ " + card.r.score, page.fmtCount(card.r.downloads) + " downloads"].join(" · ")
                            dim: true
                            font.pixelSize: Theme.fsXs
                            elide: Text.ElideRight
                        }
                        FText {
                            Layout.fillWidth: true
                            visible: !page.fonts && text !== ""
                            text: card.r.summary || ""
                            dim: true
                            font.pixelSize: Theme.fsXs
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }
                        // more than one file (variants, sizes): which one
                        FDropdown {
                            Layout.fillWidth: true
                            implicitHeight: 34
                            visible: !card.r.installed && (card.r.files || []).length > 1
                            options: [{ value: 0, label: I18n.tr("Best match") }].concat((card.r.files || []).map(f => ({ value: f.n, label: f.name + (f.size ? "  (" + Math.max(1, Math.round(f.size / 1048576)) + " MB)" : "") })))
                            current: page.chosen[card.r.id] ?? 0
                            onSelected: v => {
                                const c = Object.assign({}, page.chosen);
                                c[card.r.id] = v;
                                page.chosen = c;
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.sp1
                            FButton {
                                visible: !card.r.installed || card.doing !== ""
                                text: card.doing === "install" ? I18n.tr("Installing…") : card.doing === "remove" ? I18n.tr("Removing…") : I18n.tr("Install")
                                icon: card.doing === "" ? "download" : ""
                                disabled: card.doing !== ""
                                onClicked: page.install(card.r)
                            }
                            FButton {
                                visible: card.doing === "" && page.usable(card.r) && !card.current
                                text: I18n.tr("Use")
                                icon: "check"
                                onClicked: page.use(card.r)
                            }
                            FButton {
                                visible: card.doing === "" && card.r.ours
                                text: I18n.tr("Remove")
                                variant: "text"
                                onClicked: page.uninstall(card.r)
                            }
                            Item { Layout.fillWidth: true }
                            FIconButton {
                                visible: !!card.r.page
                                icon: "open_in_new"
                                onClicked: Qt.openUrlExternally(card.r.page)
                            }
                        }
                        FText {
                            Layout.fillWidth: true
                            visible: page.kind === "colors" && card.r.installed
                            text: I18n.tr("For KDE apps: choose it in System Settings → Colors, or in an app's color settings")
                            dim: true
                            font.pixelSize: Theme.fsXs
                            wrapMode: Text.Wrap
                        }
                    }
                }
            }
        }
    }

    // ── nothing / loading / more ──
    ColumnLayout {
        Layout.fillWidth: true
        visible: page.loading || page.results.length === 0
        spacing: Theme.sp2
        FIcon {
            Layout.alignment: Qt.AlignHCenter
            icon: page.loading ? "travel_explore" : "search_off"
            size: 36
            color: Theme.textDim
        }
        FText {
            Layout.alignment: Qt.AlignHCenter
            text: page.loading ? I18n.tr("Searching ") + page.source + "…" : page.error !== "" ? I18n.tr("Couldn't reach ") + page.source : I18n.tr("Nothing found")
            dim: true
        }
    }
    FButton {
        Layout.alignment: Qt.AlignHCenter
        visible: page.more && !page.loading
        text: I18n.tr("Show more")
        icon: "expand_more"
        variant: "tonal"
        onClicked: page.search(true)
    }
    FText {
        Layout.fillWidth: true
        text: I18n.tr("Themes made by the community: look at what you install. Icon and cursor themes go to ~/.local/share/icons, GTK themes to ~/.local/share/themes, color schemes to ~/.local/share/color-schemes, fonts to ~/.local/share/fonts/flamenco and wallpapers to kde-store in your wallpaper folder.")
        dim: true
        font.pixelSize: Theme.fsXs
        wrapMode: Text.Wrap
    }

    Component {
        id: searcher
        Process {
            id: sp
            property int tag
            property bool append
            stdout: StdioCollector {
                onStreamFinished: {
                    if (sp.tag !== page.seq)
                        return;
                    try {
                        const d = JSON.parse(text);
                        page.results = sp.append ? page.results.concat(d.results || []) : (d.results || []);
                        page.more = !!d.more;
                        page.total = d.total || 0;
                        page.error = d.error || "";
                    } catch (e) {
                        page.error = "The search failed";
                    }
                }
            }
            onExited: {
                if (sp.tag === page.seq)
                    page.loading = false;
                sp.destroy();
            }
        }
    }
    Component {
        id: runner
        Process {
            id: rp
            property var item
            property bool remove
            stdout: StdioCollector { id: rout }
            stderr: StdioCollector { id: rerr }
            onExited: code => {
                const r = rp.item;
                page.setBusy(r.id, "");
                if (code === 0) {
                    let d = {};
                    try {
                        d = JSON.parse(rout.text);
                    } catch (e) {}
                    if (rp.remove) {
                        page.update(r.id, { installed: false, ours: false, names: [], paths: [] });
                        page.status = r.name + " removed";
                    } else {
                        page.update(r.id, { installed: true, ours: true, names: d.names || [], paths: d.paths || [] });
                        page.status = r.name + " installed" + ((d.skipped || []).length ? " (left alone, already there: " + d.skipped.join(", ") + ")" : "");
                    }
                    AppTheming.refreshInstalled();
                    if (page.kind === "palettes")
                        Palettes.refresh();
                    if (page.kind === "icons")
                        UiIcons.load();                 // a pack the shell uses may have changed
                    if (page.kind === "wallpapers")
                        Wallpapers.rescan();
                } else {
                    page.status = "";
                    page.error = (rerr.text.trim().split("\n").pop() || "It didn't work").replace(/^flamenco: /, "");
                }
                rp.destroy();
            }
        }
    }
}
