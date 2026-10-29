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
// pastel badge and a line on what it's for, grouped in cards under a search pill
// (with you at its end); the page on a rounded panel beside it. Narrow windows
// show one or the other.
LazyLoader {
    active: Panels.settingsOpen

    // a page's badge: its icon on a pastel circle in its group's color, the icon in a
    // deep shade of the same color (so it reads on the pastel and matches it)
    component Badge: Rectangle {
        id: badge
        property color tint: Theme.accent
        property string glyph
        property int size: 32
        implicitWidth: size
        implicitHeight: size
        radius: size / 2
        color: Theme.mix(tint, Qt.color("#ffffff"), Theme.dark ? 0.3 : 0.5)
        FIcon {
            anchors.centerIn: parent
            icon: badge.glyph
            size: Math.round(badge.size * 0.56)
            fill: 1
            color: Qt.darker(badge.tint, 2.6)
        }
    }

    FloatingWindow {
        id: win

        title: I18n.tr("Flamenco Settings")
        implicitWidth: 1080
        implicitHeight: 780
        color: Theme.alpha(Theme.bg, Theme.settingsOp)
        visible: true
        onVisibleChanged: if (!visible) Panels.settingsOpen = false

        readonly property var pages: [
            { id: "network", icon: "wifi", label: I18n.tr("Wi-Fi & Network"), comp: networkC },
            { id: "bluetooth", icon: "bluetooth", label: I18n.tr("Bluetooth"), comp: bluetoothC },
            { id: "displays", icon: "monitor", label: I18n.tr("Displays"), comp: displaysC },
            { id: "sound", icon: "volume_up", label: I18n.tr("Sound"), comp: soundC },
            { id: "power", icon: "battery_charging_full", label: I18n.tr("Power"), comp: powerC },
            { id: "effects", icon: "auto_awesome", label: I18n.tr("Effects"), comp: effectsC },
            { id: "appearance", icon: "palette", label: I18n.tr("Appearance"), comp: appearanceC },
            { id: "wallpaper", icon: "wallpaper", label: I18n.tr("Wallpaper"), comp: wallpaperC },
            { id: "notifications", icon: "notifications", label: I18n.tr("Notifications"), comp: notifC },
            { id: "apps", icon: "format_paint", label: I18n.tr("App Theming"), comp: appsC },
            { id: "get", icon: "download", label: I18n.tr("Get themes"), comp: getC },
            { id: "bar", icon: "toolbar", label: I18n.tr("Bar"), comp: barC },
            { id: "dock", icon: "dock_to_bottom", label: I18n.tr("Dock"), comp: dockC },
            { id: "quicksettings", icon: "tune", label: I18n.tr("Quick settings"), comp: quickC },
            { id: "launcher", icon: "apps", label: I18n.tr("Launcher"), comp: launcherC },
            { id: "desktop", icon: "widgets", label: I18n.tr("Desktop widgets"), comp: desktopC },
            { id: "overview", icon: "overview_key", label: I18n.tr("Overview"), comp: overviewC },
            { id: "edges", icon: "select_all", label: I18n.tr("Screen edges"), comp: edgesC },
            { id: "clock", icon: "schedule", label: I18n.tr("Clock & Weather"), comp: clockC },
            { id: "keyboard", icon: "keyboard", label: I18n.tr("Keyboard"), comp: keyboardC },
            { id: "pointer", icon: "mouse", label: I18n.tr("Mouse & Touchpad"), comp: pointerC },
            { id: "night", icon: "nightlight", label: I18n.tr("Night light"), comp: nightC },
            { id: "printers", icon: "print", label: I18n.tr("Printers"), comp: printersC },
            { id: "screenshots", icon: "screenshot_monitor", label: I18n.tr("Screenshots"), comp: screenshotC },
            { id: "windows", icon: "select_window", label: I18n.tr("Windows & Layout"), comp: windowsC },
            { id: "workspaces", icon: "view_carousel", label: I18n.tr("Workspaces"), comp: workspacesC },
            { id: "users", icon: "manage_accounts", label: I18n.tr("Users"), comp: usersC },
            { id: "accounts", icon: "cloud_sync", label: I18n.tr("Online Accounts"), comp: accountsC },
            { id: "sharing", icon: "screen_share", label: I18n.tr("Screen sharing & files"), comp: sharingC },
            { id: "datetime", icon: "more_time", label: I18n.tr("Date & Time"), comp: datetimeC },
            { id: "region", icon: "language", label: I18n.tr("Region & Language"), comp: regionC },
            { id: "wellbeing", icon: "self_improvement", label: I18n.tr("Digital wellbeing"), comp: wellbeingC },
            { id: "lock", icon: "lock", label: I18n.tr("Lock & Login"), comp: lockC },
            { id: "defaults", icon: "open_in_new", label: I18n.tr("Default apps"), comp: defaultsC },
            { id: "autostart", icon: "rocket_launch", label: I18n.tr("Auto-start"), comp: autostartC },
            { id: "flatpak", icon: "inventory_2", label: I18n.tr("Flatpak permissions"), comp: flatpakC },
            { id: "ai", icon: "auto_awesome", label: I18n.tr("AI"), comp: aiC },
            { id: "plugins", icon: "extension", label: I18n.tr("Plugins"), comp: pluginsC },
            { id: "thirdparty", icon: "deployed_code", label: I18n.tr("Plugins (3rd party)"), comp: thirdPartyC },
            { id: "firewall", icon: "shield", label: I18n.tr("Firewall"), comp: firewallC },
            { id: "keyring", icon: "key", label: I18n.tr("Keyring"), comp: keyringC },
            { id: "system", icon: "health_and_safety", label: I18n.tr("System check"), comp: systemC },
            { id: "about", icon: "info", label: I18n.tr("About"), comp: aboutC }
        ]
        readonly property int index: Math.max(0, pages.findIndex(p => p.id === Panels.settingsPage))
        readonly property var page: pages[index]

        // the sidebar: sections of pages, and each page's badge color. The most used come
        // first (connections and hardware, then the look, the desktop…), About last
        readonly property var sections: [
            { tint: "#6fb6ff", ids: ["network", "bluetooth", "displays", "sound", "power"] },
            { tint: "#a993ff", ids: ["appearance", "effects", "wallpaper", "notifications", "apps", "get"] },
            { tint: "#8fa6ff", ids: ["bar", "dock", "quicksettings", "launcher", "desktop", "overview", "edges", "clock"] },
            { tint: "#ff9d6e", ids: ["keyboard", "pointer", "night", "printers", "screenshots"] },
            { tint: "#5fc9c2", ids: ["windows", "workspaces"] },
            { tint: "#6fcf8f", ids: ["users", "accounts", "sharing", "datetime", "region", "wellbeing", "lock"] },
            { tint: "#e98fd0", ids: ["defaults", "autostart", "flatpak", "ai", "plugins", "thirdparty"] },
            { tint: "#b8bcc8", ids: ["firewall", "keyring", "system", "about"] }
        ]
        // one line under each page's name
        readonly property var descs: ({
                appearance: "Theme, palette, dark mode", effects: "Animations, timing, visualizer effects", wallpaper: "Pictures, live wallpapers, transitions", apps: "Qt and GTK apps, color scheme", bluetooth: "Devices, pairing", region: "Language and formats", get: "Icons, cursors, GTK themes, fonts online", lock: "Lock screen, login, session",
                bar: "Style, layout, widgets", dock: "Position, pinned apps, style", launcher: "Fuzzy search, fuzzel", quicksettings: "Tiles, sliders, layout",
                desktop: "Clocks, photos, monitors", overview: "Workspaces at a glance", edges: "Hot corners and edges", clock: "Clock, weather, calendars",
                notifications: "Popups, do not disturb, mako", wellbeing: "Screen time and app limits", sound: "Devices, sounds, app volumes", screenshots: "Capture, save, copy",
                displays: "Layout, scale, refresh rate", night: "Warmth and schedule", keyboard: "Layouts and shortcuts", pointer: "Speed, scrolling, gestures",
                power: "Profiles, sleep, battery", printers: "Printers and print jobs",
                windows: "Tiling or floating, gaps, borders", workspaces: "Names and behaviour",
                network: "Wi-Fi, wired, VPN", accounts: "Calendars from the web", sharing: "Screen sharing and the file picker",
                defaults: "Browser, files, terminal", autostart: "Apps at login", flatpak: "Flatpak permissions", ai: "The AI assistant",
                plugins: "Flamenco plugins", thirdparty: "Noctalia and DMS plugins",
                users: "Your account and others", datetime: "Time zone and clock sync", firewall: "ufw or firewalld", keyring: "Passwords and secrets",
                system: "What's installed and working", about: "This computer and Flamenco"
            })
        readonly property var tints: {
            const m = {};
            for (const sec of sections)
                for (const id of sec.ids)
                    m[id] = sec.tint;
            return m;
        }
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
                // the English and the translated words both find it
                const t = (e.title + " " + I18n.tr(e.title)).toLowerCase();
                const hay = t + " " + (e.subtitle + " " + I18n.tr(e.subtitle) + " " + e.group + " " + I18n.tr(e.group) + " " + e.label + " " + I18n.tr(e.label)).toLowerCase();
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

        Component { id: effectsC; EffectsPage {} }
        Component { id: appearanceC; AppearancePage {} }
        Component { id: appsC; AppThemingPage {} }
        Component { id: getC; GetPage {} }
        Component { id: bluetoothC; BluetoothSettingsPage {} }
        Component { id: regionC; RegionPage {} }
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
        Component { id: wellbeingC; WellbeingPage {} }
        Component { id: datetimeC; DateTimePage {} }
        Component { id: accountsC; AccountsPage {} }
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

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // ── the title bar: back / forward, "Settings" centered, maximize and close; drag it to move ──
            Item {
                id: titleBar
                Layout.fillWidth: true
                Layout.preferredHeight: 54
                DragHandler {
                    target: null
                    onActiveChanged: {
                        const w = titleBar.Window.window;
                        if (active && w && typeof w.startSystemMove === "function")
                            w.startSystemMove();
                    }
                }
                RowLayout {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    FIconButton {
                        visible: win.compact
                        icon: "menu"
                        size: 34
                        onClicked: win.listOpen = !win.listOpen
                    }
                    FIconButton { icon: "chevron_left"; size: 34; iconSize: 22; disabled: win.histPos <= 0; opacity: disabled ? 0.3 : 1; onClicked: win.step(-1) }
                    FIconButton { icon: "chevron_right"; size: 34; iconSize: 22; disabled: win.histPos >= win.history.length - 1; opacity: disabled ? 0.3 : 1; onClicked: win.step(1) }
                }
                FText {
                    anchors.centerIn: parent
                    text: I18n.tr("Settings")
                    font.pixelSize: Theme.fsLg
                    font.weight: Font.Medium
                }
                RowLayout {
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6
                    // maximize: the compositor's own (niri: the column, Hyprland: the window)
                    FIconButton {
                        icon: "fullscreen"
                        size: 34
                        iconSize: 18
                        onClicked: Niri.action(Niri.hyprland ? "fullscreen-window" : "maximize-column")
                    }
                    FIconButton {
                        icon: "close"
                        size: 34
                        iconSize: 18
                        flat: false
                        iconColor: hovered ? Theme.onAccent : Theme.text
                        activeColor: Theme.error
                        active: hovered
                        onClicked: Panels.settingsOpen = false
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                Layout.bottomMargin: 12
                spacing: 12

                // ───────────────────────────── sidebar ─────────────────────────────
                ColumnLayout {
                    id: sidebar
                    visible: win.showList
                    Layout.fillHeight: true
                    Layout.fillWidth: win.compact
                    Layout.preferredWidth: win.compact ? -1 : 312
                    spacing: 12

                    // search, with you at its end (your account)
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 56
                        radius: height / 2
                        color: Theme.alpha(Theme.surfaceHigh, Theme.settingsOp)
                        border.width: search.input.activeFocus ? 2 : 1
                        border.color: search.input.activeFocus ? Theme.accent : Theme.alpha(Theme.text, 0.12)
                        Behavior on border.color { CAnim {} }
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 6
                            anchors.rightMargin: 8
                            spacing: 4
                            FTextField {
                                id: search
                                Layout.fillWidth: true
                                implicitHeight: 44
                                radius: height / 2
                                icon: "search"
                                placeholder: I18n.tr("Search settings")
                                onEdited: t => win.query = t
                                onTextChanged: win.query = text
                                onAccepted: win.go(win.results[0])
                                Keys.onEscapePressed: text = ""
                            }
                            Avatar {
                                size: 40
                                path: Settings.data.general.avatar ? Paths.expand(Settings.data.general.avatar) : (Users.self?.avatar ?? "")
                                name: Users.fullName
                                TapHandler { onTapped: Panels.settingsPage = "users" }
                                HoverHandler { cursorShape: Qt.PointingHandCursor }
                            }
                        }
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
                            spacing: 3

                            FText {
                                visible: win.results.length === 0
                                width: parent.width
                                leftPadding: 12
                                topPadding: 8
                                text: win.searchIndex.length ? I18n.tr("Nothing matches “") + win.query.trim() + "”" : I18n.tr("Loading…")
                                dim: true
                                wrapMode: Text.Wrap
                            }

                            Repeater {
                                model: win.results
                                Rectangle {
                                    id: hit
                                    required property var modelData
                                    required property int index
                                    width: resultCol.width
                                    height: hitRow.implicitHeight + 16
                                    radius: 14
                                    color: hit.index === 0 ? Theme.alpha(Theme.accent, 0.18) : Theme.alpha(Theme.surfaceHigh, Theme.settingsOp)
                                    RowLayout {
                                        id: hitRow
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 10
                                        spacing: 12
                                        Badge {
                                            tint: win.tint(hit.modelData.page)
                                            glyph: hit.modelData.kind === "page" ? hit.modelData.icon : win.pageOf(hit.modelData.page)?.icon ?? "settings"
                                            size: 30
                                        }
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 0
                                            FText { Layout.fillWidth: true; text: I18n.tr(hit.modelData.title); font.weight: hit.modelData.kind === "row" ? Font.Normal : Font.DemiBold; elide: Text.ElideRight }
                                            FText {
                                                Layout.fillWidth: true
                                                text: hit.modelData.kind === "page" ? I18n.tr(win.descs[hit.modelData.page] ?? "") : I18n.tr(hit.modelData.label) + (hit.modelData.group && hit.modelData.kind === "row" ? " › " + I18n.tr(hit.modelData.group) : "")
                                                dim: true
                                                font.pixelSize: Theme.fsXs
                                                elide: Text.ElideRight
                                            }
                                        }
                                    }
                                    StateLayer { radius: 14; onClicked: win.go(hit.modelData) }
                                }
                            }
                        }
                    }

                    // ── the pages: grouped cards ──
                    FScroll {
                        id: navScroll
                        visible: win.query.trim() === ""
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentHeight: nav.implicitHeight + 4

                        Column {
                            id: nav
                            width: navScroll.width - navScroll.gutter
                            spacing: 10

                            Repeater {
                                model: win.sections
                                Rectangle {
                                    id: card
                                    required property var modelData
                                    width: nav.width
                                    height: cardCol.implicitHeight
                                    radius: 18
                                    color: "transparent"
                                    readonly property var items: modelData.ids.map(id => win.pageOf(id)).filter(p => p)
                                    Column {
                                        id: cardCol
                                        width: parent.width
                                        spacing: 2
                                        Repeater {
                                            model: card.items
                                            Rectangle {
                                                id: item
                                                required property var modelData
                                                required property int index
                                                readonly property bool sel: win.page.id === modelData.id
                                                readonly property bool first: index === 0
                                                readonly property bool last: index === card.items.length - 1
                                                width: cardCol.width
                                                height: 58
                                                topLeftRadius: first ? 18 : 6
                                                topRightRadius: first ? 18 : 6
                                                bottomLeftRadius: last ? 18 : 6
                                                bottomRightRadius: last ? 18 : 6
                                                color: sel ? Theme.accentContainer : Theme.alpha(Theme.surfaceHigh, Theme.settingsOp)
                                                Behavior on color { CAnim {} }
                                                RowLayout {
                                                    anchors.fill: parent
                                                    anchors.leftMargin: 14
                                                    anchors.rightMargin: 12
                                                    spacing: 14
                                                    Badge {
                                                        tint: card.modelData.tint
                                                        glyph: item.modelData.icon
                                                        scale: item.sel ? 1.06 : 1
                                                        Behavior on scale { Anim { duration: Theme.durShort; easing.bezierCurve: Theme.curves.springFast } }
                                                    }
                                                    ColumnLayout {
                                                        Layout.fillWidth: true
                                                        spacing: 0
                                                        FText {
                                                            Layout.fillWidth: true
                                                            text: item.modelData.label
                                                            elide: Text.ElideRight
                                                            font.weight: Font.Medium
                                                            color: Theme.text
                                                        }
                                                        FText {
                                                            Layout.fillWidth: true
                                                            text: I18n.tr(win.descs[item.modelData.id] ?? "")
                                                            font.pixelSize: Theme.fsXs
                                                            elide: Text.ElideRight
                                                            color: item.sel ? Theme.alpha(Theme.text, 0.8) : Theme.textDim
                                                        }
                                                    }
                                                    FIcon { visible: win.compact; icon: "chevron_right"; size: 18; color: Theme.textDim }
                                                }
                                                StateLayer {
                                                    radius: 6
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
                    }
                }

                // ───────────────────────────── the page, on its panel ─────────────────────────────
                Rectangle {
                    visible: win.showPage
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 26
                    color: Theme.alpha(Theme.surface, Theme.settingsOp)
                    border.width: 1
                    border.color: Theme.materialGlass ? Theme.surfaceStroke : Theme.alpha(Theme.text, 0.04)
                    Finish { strength: 0.25 }

                    Item {
                        anchors.fill: parent
                        anchors.margins: 1
                        clip: true

                        Loader {
                            id: loader
                            anchors.fill: parent
                            sourceComponent: win.page.comp
                            property real enter: 1
                            opacity: enter
                            transform: Translate { y: Theme.pageSlide ? (1 - loader.enter) * Theme.travel(Theme.sp4) : 0 }
                            onSourceComponentChanged: {
                                enter = 0;
                                enterAnim.restart();
                            }
                            NumberAnimation {
                                id: enterAnim
                                target: loader
                                property: "enter"
                                to: 1
                                duration: Theme.pageDuration()
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Theme.curves.emphasizedDecel
                            }
                        }
                    }
                }
            }
        }
    }
}
