import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services
import qs.Widgets
import "Pages"

// The Flamenco Settings app: a regular toplevel window (app-id org.quickshell,
// title "Flamenco Settings") so niri can tile/float it like any other app.
//
// Laid out like GNOME Settings / macOS System Settings: a sidebar with your
// profile card on top and the pages sorted into a few sections, each with a
// colored badge; the page on the right under a header with back / forward,
// centered, its settings in rounded lists. Narrow windows show one or the other.
LazyLoader {
    active: Panels.settingsOpen

    // a page's badge: its icon, white on a colored rounded square (macOS style)
    component Badge: Rectangle {
        property color tint: Theme.accent
        property string glyph
        property int size: 26
        implicitWidth: size
        implicitHeight: size
        radius: Math.round(size * 0.28)
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.lighter(tint, 1.18) }
            GradientStop { position: 1; color: tint }
        }
        FIcon {
            anchors.centerIn: parent
            icon: parent.glyph
            size: Math.round(parent.size * 0.62)
            fill: 1
            color: "#ffffff"
        }
    }

    FloatingWindow {
        id: win

        title: "Flamenco Settings"
        implicitWidth: 1080
        implicitHeight: 780
        color: Theme.alpha(Theme.bg, Theme.settingsOp)
        visible: true
        onVisibleChanged: if (!visible) Panels.settingsOpen = false

        readonly property var pages: [
            { id: "appearance", icon: "palette", label: "Appearance", comp: appearanceC },
            { id: "apps", icon: "format_paint", label: "App Theming", comp: appsC },
            { id: "bar", icon: "toolbar", label: "Bar", comp: barC },
            { id: "dock", icon: "dock_to_bottom", label: "Dock", comp: dockC },
            { id: "quicksettings", icon: "tune", label: "Quick settings", comp: quickC },
            { id: "windows", icon: "select_window", label: "Windows & Layout", comp: windowsC },
            { id: "workspaces", icon: "view_carousel", label: "Workspaces", comp: workspacesC },
            { id: "edges", icon: "select_all", label: "Screen edges", comp: edgesC },
            { id: "desktop", icon: "widgets", label: "Desktop widgets", comp: desktopC },
            { id: "displays", icon: "monitor", label: "Displays", comp: displaysC },
            { id: "night", icon: "nightlight", label: "Night light", comp: nightC },
            { id: "keyboard", icon: "keyboard", label: "Keyboard", comp: keyboardC },
            { id: "pointer", icon: "mouse", label: "Mouse & Touchpad", comp: pointerC },
            { id: "network", icon: "wifi", label: "Network", comp: networkC },
            { id: "ai", icon: "auto_awesome", label: "AI", comp: aiC },
            { id: "plugins", icon: "extension", label: "Plugins", comp: pluginsC },
            { id: "thirdparty", icon: "deployed_code", label: "Plugins (3rd party)", comp: thirdPartyC },
            { id: "sharing", icon: "screen_share", label: "Screen sharing & files", comp: sharingC },
            { id: "sound", icon: "volume_up", label: "Sound", comp: soundC },
            { id: "screenshots", icon: "screenshot_monitor", label: "Screenshots", comp: screenshotC },
            { id: "power", icon: "battery_charging_full", label: "Power", comp: powerC },
            { id: "firewall", icon: "shield", label: "Firewall", comp: firewallC },
            { id: "keyring", icon: "key", label: "Keyring", comp: keyringC },
            { id: "printers", icon: "print", label: "Printers", comp: printersC },
            { id: "wallpaper", icon: "wallpaper", label: "Wallpaper", comp: wallpaperC },
            { id: "notifications", icon: "notifications", label: "Notifications", comp: notifC },
            { id: "launcher", icon: "apps", label: "Launcher", comp: launcherC },
            { id: "overview", icon: "overview_key", label: "Overview", comp: overviewC },
            { id: "defaults", icon: "open_in_new", label: "Default apps", comp: defaultsC },
            { id: "autostart", icon: "rocket_launch", label: "Auto-start", comp: autostartC },
            { id: "flatpak", icon: "inventory_2", label: "Flatpak permissions", comp: flatpakC },
            { id: "lock", icon: "lock", label: "Lock & Login", comp: lockC },
            { id: "clock", icon: "schedule", label: "Clock & Weather", comp: clockC },
            { id: "users", icon: "manage_accounts", label: "Users", comp: usersC },
            { id: "system", icon: "health_and_safety", label: "System check", comp: systemC },
            { id: "about", icon: "info", label: "About", comp: aboutC }
        ]
        readonly property int index: Math.max(0, pages.findIndex(p => p.id === Panels.settingsPage))
        readonly property var page: pages[index]

        // the sidebar: sections of pages, and each page's badge color
        readonly property var sections: [
            { title: "Personalize", ids: ["appearance", "wallpaper", "bar", "dock", "desktop", "clock", "lock", "apps"] },
            { title: "Desktop & windows", ids: ["windows", "workspaces", "overview", "launcher", "quicksettings", "notifications", "edges", "screenshots"] },
            { title: "Devices", ids: ["displays", "night", "sound", "keyboard", "pointer", "printers", "power"] },
            { title: "Network & sharing", ids: ["network", "sharing"] },
            { title: "Apps", ids: ["defaults", "autostart", "flatpak", "ai", "plugins", "thirdparty"] },
            { title: "Privacy & security", ids: ["firewall", "keyring"] },
            { title: "System", ids: ["users", "system", "about"] }
        ]
        readonly property var tints: ({
                appearance: "#8e6cf0", wallpaper: "#36b3e8", bar: "#5b6cf0", dock: "#3d8ef0", desktop: "#e86fbf", clock: "#f0a03d", lock: "#6d7280", apps: "#d9668a",
                windows: "#4f7cf0", workspaces: "#2fb0a0", overview: "#7b61e0", launcher: "#f06b4f", quicksettings: "#5f6b7a", notifications: "#ef4f5f", edges: "#8b8f99", screenshots: "#47a3d6",
                displays: "#3d7cf0", night: "#f08a3d", sound: "#f0544f", keyboard: "#7d8592", pointer: "#7d8592", printers: "#6b7380", power: "#3fb855",
                network: "#2f8ff0", sharing: "#35b5c9", defaults: "#7a6cf0", autostart: "#f08a3d", flatpak: "#4a90d9", ai: "#d4783a", plugins: "#9a5bd9", thirdparty: "#b45bd9",
                firewall: "#4a5568", keyring: "#c9a227", users: "#5b7cf0", system: "#3fb855", about: "#6b7380"
            })
        function tint(id) {
            return tints[id] ?? Theme.accent;
        }
        function pageOf(id) {
            return pages.find(p => p.id === id) ?? null;
        }

        // back / forward through the pages you've visited
        property var history: []
        property int histPos: -1
        property bool navigating: false
        function remember(id) {
            if (navigating || history[histPos] === id)
                return;
            history = history.slice(0, histPos + 1).concat([id]).slice(-50);
            histPos = history.length - 1;
        }
        function step(d) {
            const i = histPos + d;
            if (i < 0 || i >= history.length)
                return;
            navigating = true;
            histPos = i;
            Panels.settingsPage = history[i];
            navigating = false;
        }
        Connections {
            target: Panels
            function onSettingsPageChanged() {
                win.remember(win.page.id);
                win.listOpen = false;
            }
        }
        Component.onCompleted: remember(page.id)

        // narrow: the sidebar and the page take turns
        readonly property bool compact: width < 820
        property bool listOpen: false
        readonly property bool showList: !compact || listOpen
        readonly property bool showPage: !compact || !listOpen

        // ── search: every page, section and setting (`flamenco settings-index`) ──
        property var searchIndex: []
        property string query: ""
        readonly property var results: {
            const q = query.trim().toLowerCase();
            if (q === "")
                return [];
            const words = q.split(/\s+/);
            const order = pages.map(p => p.id);
            const hits = [];
            for (const e of searchIndex) {
                const t = e.title.toLowerCase();
                const hay = t + " " + e.subtitle.toLowerCase() + " " + e.group.toLowerCase() + " " + e.label.toLowerCase();
                if (!words.every(w => hay.includes(w)))
                    continue;
                // titles that start with it first, then titles containing it, then the rest
                const score = (t.startsWith(q) ? 0 : t.includes(q) ? 1 : words.every(w => t.includes(w)) ? 2 : 3) + (e.kind === "page" ? -0.5 : e.kind === "group" ? -0.2 : 0);
                hits.push({ e, score, page: order.indexOf(e.page) });
            }
            hits.sort((a, b) => a.score - b.score || a.page - b.page);
            return hits.slice(0, 60).map(h => h.e);
        }

        function go(e) {
            if (!e)
                return;
            if (e.kind === "page")
                Panels.settingsPage = e.page;
            else
                Panels.findSetting(e.page, e.title);
        }

        Process {
            running: true
            command: [Paths.bin, "settings-index", "--json"]
            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        win.searchIndex = JSON.parse(text);
                    } catch (e) {}
                }
            }
        }

        Shortcut {
            sequences: [StandardKey.Find, "Ctrl+K"]
            onActivated: {
                win.listOpen = true;
                search.input.forceActiveFocus();
            }
        }
        Shortcut { sequences: [StandardKey.Back, "Alt+Left"]; onActivated: win.step(-1) }
        Shortcut { sequences: [StandardKey.Forward, "Alt+Right"]; onActivated: win.step(1) }

        Component { id: appearanceC; AppearancePage {} }
        Component { id: appsC; AppThemingPage {} }
        Component { id: barC; BarPage {} }
        Component { id: dockC; DockPage {} }
        Component { id: quickC; QuickSettingsPage {} }
        Component { id: desktopC; DesktopPage {} }
        Component { id: displaysC; DisplaysPage {} }
        Component { id: nightC; NightLightPage {} }
        Component { id: keyboardC; KeyboardPage {} }
        Component { id: pointerC; PointerPage {} }
        Component { id: networkC; NetworkPage {} }
        Component { id: aiC; AiPage {} }
        Component { id: pluginsC; PluginsPage {} }
        Component { id: thirdPartyC; ThirdPartyPage {} }
        Component { id: sharingC; ScreenSharingPage {} }
        Component { id: soundC; SoundPage {} }
        Component { id: firewallC; FirewallPage {} }
        Component { id: keyringC; KeyringPage {} }
        Component { id: powerC; PowerSettingsPage {} }
        Component { id: printersC; PrintersPage {} }
        Component { id: systemC; SystemCheckPage {} }
        Component { id: usersC; UsersPage {} }
        Component { id: wallpaperC; WallpaperPage {} }
        Component { id: notifC; NotificationsPage {} }
        Component { id: launcherC; LauncherPage {} }
        Component { id: overviewC; OverviewPage {} }
        Component { id: lockC; LockPage {} }
        Component { id: clockC; ClockPage {} }
        Component { id: aboutC; AboutPage {} }
        Component { id: windowsC; WindowsPage {} }
        Component { id: workspacesC; WorkspacesPage {} }
        Component { id: edgesC; EdgesPage {} }
        Component { id: screenshotC; ScreenshotPage {} }
        Component { id: defaultsC; DefaultAppsPage {} }
        Component { id: autostartC; AutostartPage {} }
        Component { id: flatpakC; FlatpakPage {} }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // ───────────────────────────── sidebar ─────────────────────────────
            Rectangle {
                id: sidebar
                visible: win.showList
                Layout.fillHeight: true
                Layout.fillWidth: win.compact
                Layout.preferredWidth: win.compact ? -1 : 288
                color: Theme.alpha(Theme.surface, Theme.settingsOp)

                // drag the window from the sidebar's top (Super+drag also works)
                Item {
                    id: dragTop
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 56
                    DragHandler {
                        target: null
                        onActiveChanged: {
                            const w = dragTop.Window.window;
                            if (active && w && typeof w.startSystemMove === "function")
                                w.startSystemMove();
                        }
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    anchors.topMargin: 14
                    spacing: 10

                    // window title and close (the close button is here while the page is hidden)
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 4
                        spacing: 8
                        FText {
                            Layout.fillWidth: true
                            text: "Settings"
                            font.pixelSize: Theme.fsXl
                            font.weight: Font.Bold
                        }
                        FIconButton {
                            visible: win.compact
                            icon: "close"
                            size: 32
                            iconSize: 18
                            onClicked: Panels.settingsOpen = false
                        }
                    }

                    FTextField {
                        id: search
                        Layout.fillWidth: true
                        implicitHeight: 40
                        radius: 12
                        icon: "search"
                        placeholder: "Search settings"
                        onEdited: t => win.query = t
                        onTextChanged: win.query = text
                        onAccepted: win.go(win.results[0])
                        Keys.onEscapePressed: text = ""
                    }

                    // ── search results, in place of the list while there's a query ──
                    FScroll {
                        id: resultScroll
                        visible: win.query.trim() !== ""
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentHeight: resultCol.implicitHeight

                        Column {
                            id: resultCol
                            width: resultScroll.width - resultScroll.gutter
                            spacing: 2

                            FText {
                                visible: win.results.length === 0
                                width: parent.width
                                leftPadding: 8
                                topPadding: 8
                                text: win.searchIndex.length ? "Nothing matches “" + win.query.trim() + "”" : "Loading…"
                                dim: true
                                wrapMode: Text.Wrap
                            }

                            Repeater {
                                model: win.results
                                Item {
                                    id: hit
                                    required property var modelData
                                    required property int index
                                    width: resultCol.width
                                    height: hitRow.implicitHeight + 14

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 10
                                        color: Theme.alpha(Theme.accent, 0.14)
                                        visible: hit.index === 0
                                    }
                                    RowLayout {
                                        id: hitRow
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        spacing: 10
                                        Badge {
                                            tint: win.tint(hit.modelData.page)
                                            glyph: hit.modelData.kind === "page" ? hit.modelData.icon : win.pageOf(hit.modelData.page)?.icon ?? "settings"
                                            size: 24
                                        }
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 0
                                            FText {
                                                Layout.fillWidth: true
                                                text: hit.modelData.title
                                                font.weight: hit.modelData.kind === "row" ? Font.Normal : Font.DemiBold
                                                elide: Text.ElideRight
                                            }
                                            FText {
                                                Layout.fillWidth: true
                                                visible: hit.modelData.kind !== "page"
                                                text: hit.modelData.label + (hit.modelData.group && hit.modelData.kind === "row" ? " › " + hit.modelData.group : "")
                                                dim: true
                                                font.pixelSize: Theme.fsXs
                                                elide: Text.ElideRight
                                            }
                                        }
                                    }
                                    StateLayer {
                                        radius: 10
                                        onClicked: win.go(hit.modelData)
                                    }
                                }
                            }
                        }
                    }

                    // ── profile card, then the sections ──
                    FScroll {
                        id: navScroll
                        visible: win.query.trim() === ""
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentHeight: nav.implicitHeight + 8

                        Column {
                            id: nav
                            width: navScroll.width - navScroll.gutter
                            spacing: 2

                            // you: your picture and name → Users
                            Rectangle {
                                id: me
                                width: nav.width
                                height: 64
                                radius: 14
                                readonly property bool sel: win.page.id === "users"
                                color: sel ? Theme.alpha(Theme.accent, 0.16) : Theme.alpha(Theme.text, 0.04)
                                Behavior on color { CAnim {} }
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 12
                                    Avatar {
                                        size: 44
                                        path: Settings.data.general.avatar ? Paths.expand(Settings.data.general.avatar) : (Users.self?.avatar ?? "")
                                        name: Users.fullName
                                    }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0
                                        FText {
                                            Layout.fillWidth: true
                                            text: Users.fullName
                                            font.weight: Font.Bold
                                            elide: Text.ElideRight
                                        }
                                        FText {
                                            Layout.fillWidth: true
                                            text: "@" + Users.me + " · your account"
                                            dim: true
                                            font.pixelSize: Theme.fsXs
                                            elide: Text.ElideRight
                                        }
                                    }
                                    FIcon { icon: "chevron_right"; size: 18; color: Theme.textDim }
                                }
                                StateLayer {
                                    radius: 14
                                    onClicked: Panels.settingsPage = "users"
                                }
                            }

                            Repeater {
                                model: win.sections
                                Column {
                                    id: sect
                                    required property var modelData
                                    width: nav.width
                                    spacing: 1
                                    topPadding: 14

                                    FText {
                                        leftPadding: 10
                                        bottomPadding: 4
                                        text: sect.modelData.title
                                        dim: true
                                        font.pixelSize: Theme.fsXs
                                        font.weight: Font.DemiBold
                                    }
                                    Repeater {
                                        model: sect.modelData.ids.map(id => win.pageOf(id)).filter(p => p)
                                        Item {
                                            id: item
                                            required property var modelData
                                            readonly property bool sel: win.page.id === modelData.id
                                            width: sect.width
                                            height: 38

                                            Rectangle {
                                                anchors.fill: parent
                                                radius: 10
                                                color: item.sel ? Theme.alpha(Theme.accent, 0.16) : "transparent"
                                                Behavior on color { CAnim {} }
                                            }
                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 8
                                                anchors.rightMargin: 10
                                                spacing: 11
                                                Badge {
                                                    tint: win.tint(item.modelData.id)
                                                    glyph: item.modelData.icon
                                                    scale: item.sel ? 1.06 : 1
                                                    Behavior on scale { Anim { duration: Theme.durShort; easing.bezierCurve: Theme.curves.springFast } }
                                                }
                                                FText {
                                                    Layout.fillWidth: true
                                                    text: item.modelData.label
                                                    elide: Text.ElideRight
                                                    font.weight: item.sel ? Font.DemiBold : Font.Normal
                                                }
                                                FIcon {
                                                    visible: win.compact
                                                    icon: "chevron_right"
                                                    size: 18
                                                    color: Theme.textDim
                                                }
                                            }
                                            StateLayer {
                                                radius: 10
                                                onClicked: {
                                                    Panels.settingsPage = item.modelData.id;
                                                    win.listOpen = false;
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    FText {
                        Layout.leftMargin: 6
                        text: "Changes apply right away"
                        dim: true
                        font.pixelSize: Theme.fsXs
                    }
                }

                // the line between the sidebar and the page
                Rectangle {
                    visible: !win.compact
                    anchors.right: parent.right
                    width: 1
                    height: parent.height
                    color: Theme.alpha(Theme.border, 0.6)
                }
            }

            // ───────────────────────────── page ─────────────────────────────
            ColumnLayout {
                visible: win.showPage
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                // header: back / forward, the page's name, close; drag it to move the window
                Item {
                    id: header
                    Layout.fillWidth: true
                    Layout.preferredHeight: 56

                    DragHandler {
                        target: null
                        cursorShape: Qt.ClosedHandCursor
                        onActiveChanged: {
                            const w = header.Window.window;
                            if (active && w && typeof w.startSystemMove === "function")
                                w.startSystemMove();
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 4

                        FIconButton {
                            visible: win.compact
                            icon: "menu"
                            size: 34
                            iconSize: 20
                            onClicked: win.listOpen = true
                        }
                        FIconButton {
                            icon: "chevron_left"
                            size: 34
                            iconSize: 22
                            disabled: win.histPos <= 0
                            opacity: disabled ? 0.35 : 1
                            onClicked: win.step(-1)
                        }
                        FIconButton {
                            icon: "chevron_right"
                            size: 34
                            iconSize: 22
                            disabled: win.histPos >= win.history.length - 1
                            opacity: disabled ? 0.35 : 1
                            onClicked: win.step(1)
                        }
                        // the page's name, cross-fading on change
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.leftMargin: 8
                            FText {
                                id: crumb
                                anchors.verticalCenter: parent.verticalCenter
                                text: win.page.label
                                font.pixelSize: Theme.fsLg
                                font.weight: Font.Bold
                                Behavior on text {
                                    SequentialAnimation {
                                        NumberAnimation { target: crumb; property: "opacity"; to: 0; duration: Theme.durShort }
                                        PropertyAction {}
                                        NumberAnimation { target: crumb; property: "opacity"; to: 1; duration: Theme.durShort }
                                    }
                                }
                            }
                        }
                        FIconButton {
                            icon: "close"
                            size: 32
                            iconSize: 18
                            iconColor: hovered ? Theme.onAccent : Theme.text
                            activeColor: Theme.error
                            active: hovered
                            onClicked: Panels.settingsOpen = false
                        }
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 1
                        color: Theme.alpha(Theme.border, 0.6)
                        opacity: loader.item && loader.item.contentY > 4 ? 1 : 0
                        Behavior on opacity { Anim { duration: Theme.durShort } }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    Loader {
                        id: loader
                        anchors.fill: parent
                        sourceComponent: win.page.comp
                        property real enter: 1
                        opacity: enter
                        transform: Translate { x: (1 - loader.enter) * 28 * loader.dir }
                        property int dir: 1
                        onLoaded: {
                            // the page's hero: its badge, from the sidebar
                            if (item.pageIcon !== undefined) {
                                item.pageIcon = win.page.icon;
                                item.pageTint = win.tint(win.page.id);
                            }
                        }
                        onSourceComponentChanged: {
                            enter = 0;
                            enterAnim.restart();
                        }
                        NumberAnimation {
                            id: enterAnim
                            target: loader
                            property: "enter"
                            to: 1
                            duration: Theme.durLong
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Theme.curves.emphasizedDecel
                        }
                    }
                }
            }
        }
    }
}
