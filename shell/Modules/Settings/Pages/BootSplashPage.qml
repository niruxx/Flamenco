import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services
import qs.Widgets

// Settings → Boot splash: Plymouth themes. The installed ones with a picture of
// each (the theme's own preview, background or logo), a test run, and more from
// the KDE Store's "Plymouth Themes". Themes live in /usr/share/plymouth/themes,
// so `flamenco plymouth …` runs in a terminal with one sudo prompt (switching also
// rebuilds the initramfs), like the login screen's Apply.
Page {
    id: page
    title: I18n.tr("Boot splash")
    subtitle: I18n.tr("The animation you see while the computer starts and shuts down (Plymouth). Pick a theme, try it, or get more from the KDE Store.")

    property var st: ({ installed: false, themes: [], current: "" })
    property bool loaded: false
    property string tab: "installed"           // installed | store
    property var selected: null                // the card shown big: { name, picture, store }

    // the store
    property string query: ""
    property string sort: "rating"
    property int pageNo: 1
    property var results: []
    property bool more: false
    property int total: 0
    property string error: ""
    property bool loading: false
    property int seq: 0
    property bool searched: false

    function refresh() {
        if (!getter.running)
            getter.running = true;
    }
    function inTerminal(args) {
        runner.command = Paths.termHold(Paths.shellQuote(Paths.bin) + " plymouth " + args);
        runner.running = true;
    }
    function search(again) {
        pageNo = again ? pageNo + 1 : 1;
        if (!again) {
            results = [];
            error = "";
        }
        seq++;
        loading = true;
        searched = true;
        searcher.createObject(page, { tag: seq, append: !!again, command: [Paths.bin, "get", "search", "plymouth", query, String(pageNo), sort] }).running = true;
    }
    function installedFromStore(id) {
        return st.themes.some(t => t.storeId === id);
    }
    function fmtCount(v) {
        return v >= 1e6 ? (v / 1e6).toFixed(1) + "M" : v >= 1e3 ? Math.round(v / 1e3) + "k" : String(v);
    }

    Component.onCompleted: refresh()
    onTabChanged: if (tab === "store" && !searched) search(false)
    onSortChanged: if (searched) search(false)

    Process {
        id: getter
        command: [Paths.bin, "plymouth", "status", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    page.st = JSON.parse(text);
                    page.loaded = true;
                    if (!page.selected) {
                        const cur = page.st.themes.find(t => t.id === page.st.current);
                        if (cur)
                            page.selected = { name: cur.name, picture: cur.picture, store: false };
                    }
                } catch (e) {}
            }
        }
    }
    // the terminal: look again once it's closed
    Process {
        id: runner
        onExited: page.refresh()
    }

    // ── Plymouth itself ──
    Group {
        SettingRow {
            title: !page.loaded ? I18n.tr("Checking…")
                : !page.st.installed ? I18n.tr("Plymouth isn't installed")
                : page.st.current ? I18n.tr("Boot splash: ") + ((page.st.themes.find(t => t.id === page.st.current) || {}).name || page.st.current)
                : I18n.tr("Plymouth is installed")
            subtitle: !page.loaded ? ""
                : !page.st.installed ? I18n.tr("Install it to get a boot splash: ") + page.st.installHint
                : page.st.themes.length + I18n.tr(" themes in ") + page.st.dir
            icon: page.st.installed ? "check_circle" : "info"
            Row {
                spacing: 8
                FButton {
                    visible: page.loaded && !page.st.installed
                    text: I18n.tr("Install Plymouth")
                    variant: "tonal"
                    onClicked: {
                        runner.command = Paths.termHold(page.st.installHint);
                        runner.running = true;
                    }
                }
                FIconButton {
                    icon: "refresh"
                    size: 32
                    onClicked: page.refresh()
                }
            }
        }
        SettingRow {
            visible: page.loaded && page.st.installed && page.st.hook === false
            title: I18n.tr("Not in the initramfs yet")
            subtitle: I18n.tr("Add plymouth to HOOKS in /etc/mkinitcpio.conf (after systemd or udev), then pick a theme here so the initramfs is rebuilt")
            icon: "warning"
        }
        SettingRow {
            visible: page.loaded && page.st.installed && !page.st.splashArg
            title: I18n.tr("The kernel isn't asked for a splash")
            subtitle: I18n.tr("Add \"splash\" (and \"quiet\") to your kernel command line in your boot loader's config, or the theme won't show")
            icon: "warning"
        }
    }

    // ── the big preview ──
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.round(width * 9 / 16)
        visible: !!page.selected
        radius: Math.max(12, Theme.rLg)
        color: "black"                      // what Plymouth draws on
        clip: true
        SafeImage {
            id: big
            anchors.fill: parent
            anchors.margins: page.selected && page.selected.store ? 0 : parent.height * 0.18
            path: page.selected ? Paths.toUrl(page.selected.picture) : ""
            fillMode: page.selected && page.selected.store ? Image.PreserveAspectCrop : Image.PreserveAspectFit
            sourceSize.width: 1280
            opacity: status === Image.Ready ? 1 : 0
            Behavior on opacity { Anim {} }
        }
        FIcon {
            visible: big.status !== Image.Ready
            anchors.centerIn: parent
            icon: big.status === Image.Loading ? "hourglass_empty" : "image_not_supported"
            size: 36
            color: "#888"
        }
        Rectangle {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: Theme.sp3
            height: 26
            width: cap.implicitWidth + 20
            radius: 13
            color: Qt.rgba(0, 0, 0, 0.6)
            FText {
                id: cap
                anchors.centerIn: parent
                text: (page.selected ? page.selected.name : "") + (page.selected && !page.selected.store ? I18n.tr(" · a picture from the theme; Test shows it moving") : "")
                color: "white"
                font.pixelSize: Theme.fsXs
            }
        }
    }

    FSegmented {
        Layout.fillWidth: true
        options: [{ value: "installed", label: I18n.tr("Installed"), icon: "check_circle" }, { value: "store", label: I18n.tr("Get more"), icon: "download" }]
        current: page.tab
        onSelected: v => page.tab = v
    }

    // ── installed themes ──
    Item {
        Layout.fillWidth: true
        visible: page.tab === "installed"
        implicitHeight: mine.implicitHeight
        Flow {
            id: mine
            width: parent.width
            spacing: Theme.sp3
            readonly property int cols: width > 700 ? 3 : 2
            readonly property real cardW: Math.floor((width - spacing * (cols - 1)) / cols)
            Repeater {
                model: ScriptModel { values: page.st.themes }
                Rectangle {
                    id: card
                    required property var modelData
                    readonly property bool current: modelData.id === page.st.current
                    readonly property bool shown: !!page.selected && !page.selected.store && page.selected.picture === modelData.picture && page.selected.name === modelData.name
                    width: mine.cardW
                    height: body.implicitHeight + Theme.sp3 * 2
                    radius: Math.max(12, Theme.rLg)
                    color: Theme.alpha(Theme.surface, Math.min(1, Theme.settingsOp + 0.04))
                    border.width: current || shown ? 2 : 1
                    border.color: current ? Theme.accent : shown ? Theme.alpha(Theme.accent, 0.5) : Theme.alpha(Theme.text, 0.06)

                    ColumnLayout {
                        id: body
                        x: Theme.sp3
                        y: Theme.sp3
                        width: parent.width - Theme.sp3 * 2
                        spacing: Theme.sp2

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.round(width * 0.56)
                            radius: Theme.rMd
                            color: "black"
                            clip: true
                            SafeImage {
                                id: pic
                                anchors.fill: parent
                                anchors.margins: parent.height * 0.15
                                path: Paths.toUrl(card.modelData.picture)
                                fillMode: Image.PreserveAspectFit
                                sourceSize.width: 480
                                opacity: status === Image.Ready ? 1 : 0
                                Behavior on opacity { Anim {} }
                            }
                            FIcon {
                                visible: pic.status !== Image.Ready
                                anchors.centerIn: parent
                                icon: card.modelData.picture ? "hourglass_empty" : "image_not_supported"
                                size: 28
                                color: "#888"
                            }
                            Rectangle {
                                visible: card.current
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 6
                                height: 22
                                width: tag.implicitWidth + 16
                                radius: 11
                                color: Theme.accent
                                FText {
                                    id: tag
                                    anchors.centerIn: parent
                                    text: I18n.tr("In use")
                                    font.pixelSize: Theme.fsXs
                                    font.weight: Font.DemiBold
                                    color: Theme.onAccent
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: page.selected = { name: card.modelData.name, picture: card.modelData.picture, store: false }
                            }
                        }
                        FText {
                            Layout.fillWidth: true
                            text: card.modelData.name
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }
                        FText {
                            Layout.fillWidth: true
                            text: [card.modelData.id !== card.modelData.name ? card.modelData.id : "", card.modelData.module, card.modelData.storeId ? I18n.tr("from Flamenco") : ""].filter(s => s).join(" · ") || " "
                            dim: true
                            font.pixelSize: Theme.fsXs
                            elide: Text.ElideRight
                        }
                        FText {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: card.modelData.description
                            dim: true
                            font.pixelSize: Theme.fsXs
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.sp1
                            FButton {
                                visible: !card.current
                                text: I18n.tr("Use")
                                icon: "check"
                                disabled: runner.running || !page.st.canSet
                                onClicked: page.inTerminal("set " + Paths.shellQuote(card.modelData.id))
                            }
                            FButton {
                                text: I18n.tr("Test")
                                icon: "play_arrow"
                                variant: "tonal"
                                disabled: runner.running
                                onClicked: page.inTerminal("test " + Paths.shellQuote(card.modelData.id) + " 6")
                            }
                            Item { Layout.fillWidth: true }
                            FButton {
                                visible: !!card.modelData.storeId && !card.current
                                text: I18n.tr("Remove")
                                variant: "text"
                                disabled: runner.running
                                onClicked: page.inTerminal("remove " + Paths.shellQuote(card.modelData.id))
                            }
                        }
                    }
                }
            }
        }
    }
    FText {
        Layout.fillWidth: true
        visible: page.tab === "installed" && page.loaded && page.st.themes.length === 0
        text: I18n.tr("No themes found in /usr/share/plymouth/themes")
        dim: true
    }
    Group {
        visible: page.tab === "installed"
        title: I18n.tr("Install from a file")
        SettingRow {
            title: I18n.tr("Theme archive")
            subtitle: I18n.tr("A .tar.gz, .tar.xz or .zip with a folder holding a .plymouth file")
            icon: "folder_zip"
            Row {
                spacing: 8
                FTextField {
                    id: archive
                    implicitWidth: 240
                    icon: "draft"
                    placeholder: "~/Downloads/theme.tar.gz"
                    onAccepted: if (text.trim()) page.inTerminal("install " + Paths.shellQuote(Paths.expand(text.trim())))
                }
                FButton {
                    text: I18n.tr("Install")
                    icon: "download"
                    variant: "tonal"
                    implicitHeight: 38
                    disabled: runner.running || archive.text.trim() === ""
                    onClicked: page.inTerminal("install " + Paths.shellQuote(Paths.expand(archive.text.trim())))
                }
            }
        }
    }

    // ── the KDE Store ──
    RowLayout {
        Layout.fillWidth: true
        visible: page.tab === "store"
        spacing: Theme.sp2
        FTextField {
            Layout.fillWidth: true
            icon: "search"
            placeholder: I18n.tr("Search boot splashes on the KDE Store")
            onAccepted: {
                page.query = text.trim();
                page.search(false);
            }
        }
        FDropdown {
            implicitWidth: 170
            options: [{ value: "rating", label: I18n.tr("Best rated") }, { value: "downloads", label: I18n.tr("Most downloaded") }, { value: "new", label: I18n.tr("Newest") }]
            current: page.sort
            onSelected: v => page.sort = v
        }
    }
    FText {
        Layout.fillWidth: true
        visible: page.tab === "store" && text !== ""
        text: page.error !== "" ? page.error : page.total > 0 ? page.total.toLocaleString(Qt.locale(), "f", 0) + I18n.tr(" found on the KDE Store (store.kde.org)") : ""
        color: page.error !== "" ? Theme.error : Theme.textDim
        font.pixelSize: Theme.fsSm
        wrapMode: Text.Wrap
    }
    Item {
        Layout.fillWidth: true
        visible: page.tab === "store"
        implicitHeight: store.implicitHeight
        Flow {
            id: store
            width: parent.width
            spacing: Theme.sp3
            readonly property int cols: width > 700 ? 3 : 2
            readonly property real cardW: Math.floor((width - spacing * (cols - 1)) / cols)
            Repeater {
                model: ScriptModel { values: page.results }
                Rectangle {
                    id: sc
                    required property var modelData
                    readonly property bool have: page.installedFromStore(modelData.id)
                    width: store.cardW
                    height: sbody.implicitHeight + Theme.sp3 * 2
                    radius: Math.max(12, Theme.rLg)
                    color: Theme.alpha(Theme.surface, Math.min(1, Theme.settingsOp + 0.04))
                    border.width: 1
                    border.color: Theme.alpha(Theme.text, 0.06)

                    ColumnLayout {
                        id: sbody
                        x: Theme.sp3
                        y: Theme.sp3
                        width: parent.width - Theme.sp3 * 2
                        spacing: Theme.sp2
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.round(width * 0.56)
                            radius: Theme.rMd
                            color: "black"
                            clip: true
                            SafeImage {
                                id: spic
                                anchors.fill: parent
                                path: sc.modelData.thumb || sc.modelData.preview || ""
                                fillMode: Image.PreserveAspectCrop
                                sourceSize.width: 480
                                opacity: status === Image.Ready ? 1 : 0
                                Behavior on opacity { Anim {} }
                            }
                            FIcon {
                                visible: spic.status !== Image.Ready
                                anchors.centerIn: parent
                                icon: spic.status === Image.Error || !(sc.modelData.thumb || sc.modelData.preview) ? "image_not_supported" : "hourglass_empty"
                                size: 28
                                color: "#888"
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: page.selected = { name: sc.modelData.name, picture: sc.modelData.preview || sc.modelData.thumb, store: true }
                            }
                        }
                        FText {
                            Layout.fillWidth: true
                            text: sc.modelData.name
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }
                        FText {
                            Layout.fillWidth: true
                            text: ["★ " + sc.modelData.score, page.fmtCount(sc.modelData.downloads) + I18n.tr(" downloads"), sc.modelData.updated].filter(s => s).join(" · ")
                            dim: true
                            font.pixelSize: Theme.fsXs
                            elide: Text.ElideRight
                        }
                        FText {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: sc.modelData.summary || ""
                            dim: true
                            font.pixelSize: Theme.fsXs
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.sp1
                            FButton {
                                text: sc.have ? I18n.tr("Installed") : I18n.tr("Install")
                                icon: sc.have ? "check" : "download"
                                disabled: sc.have || runner.running || !page.st.installed
                                onClicked: page.inTerminal("get " + Paths.shellQuote(sc.modelData.id))
                            }
                            Item { Layout.fillWidth: true }
                            FIconButton {
                                visible: !!sc.modelData.page
                                icon: "open_in_new"
                                onClicked: Qt.openUrlExternally(sc.modelData.page)
                            }
                        }
                    }
                }
            }
        }
    }
    FText {
        Layout.alignment: Qt.AlignHCenter
        visible: page.tab === "store" && (page.loading || page.results.length === 0)
        text: page.loading ? I18n.tr("Searching the KDE Store…") : page.error !== "" ? I18n.tr("Couldn't reach the KDE Store") : I18n.tr("Nothing found")
        dim: true
    }
    FButton {
        Layout.alignment: Qt.AlignHCenter
        visible: page.tab === "store" && page.more && !page.loading
        text: I18n.tr("Show more")
        icon: "expand_more"
        variant: "tonal"
        onClicked: page.search(true)
    }
    FText {
        Layout.fillWidth: true
        visible: page.tab === "store"
        text: I18n.tr("Themes made by the community: look at what you install. They're unpacked in your home folder first, then copied into /usr/share/plymouth/themes (that asks for your password). Install, then Use, to see one at boot.")
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
                        page.error = I18n.tr("The search failed");
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
}
