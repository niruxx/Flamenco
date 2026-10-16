import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

// The dashboard, opened from the bar clock. Two layouts (Settings → Clock & Weather):
//   hub   a wide hub with a rail on the left: Home · Media · Calendar · Weather ·
//         Wallpapers, and System / Settings, which open those
//   tabs  the compact one: Overview · Media · Wallpapers · Weather · Settings
// (Panel name stays "calendar" so `flamenco calendar` and existing binds keep working.)
Variants {
    model: Quickshell.screens

    OverlayPanel {
        id: panel
        name: "calendar"

        readonly property bool hub: (Settings.data.dashboard.style || "hub") === "hub"
        cardWidth: hub ? Math.min(1260, Math.round(modelData.width * 0.92)) : 560
        followOrigin: !hub
        exclusiveKeyboard: hub

        // tabs with `action` open something else instead of a page
        readonly property var tabs: hub ? [
            { value: "home", label: "Home", icon: "space_dashboard" },
            { value: "media", label: "Media", icon: "music_note" },
            { value: "calendar", label: "Calendar", icon: "calendar_month" },
            { value: "weather", label: "Weather", icon: "partly_cloudy_day" },
            { value: "wallpapers", label: "Wallpaper", icon: "wallpaper" },
            { value: "system", label: "System", icon: "monitoring" },
            { value: "settings", label: "Settings", icon: "settings", action: true }
        ] : [
            { value: "overview", label: "Overview", icon: "dashboard" },
            { value: "media", label: "Media", icon: "music_note" },
            { value: "wallpapers", label: "Wallpapers", icon: "wallpaper" },
            { value: "weather", label: "Weather", icon: "partly_cloudy_day" },
            { value: "settings", label: "Settings", icon: "settings", action: true }
        ]
        readonly property var pageTabs: tabs.filter(t => !t.action)
        property string tab: "overview"
        readonly property int tabIndex: Math.max(0, pageTabs.findIndex(t => t.value === tab))
        function indexOf(v) {
            return pageTabs.findIndex(t => t.value === v);
        }
        // the hub's Calendar page stands in for the tabs layout's Overview, and back
        function page(v) {
            return hub && v === "overview" ? "calendar" : !hub && v === "calendar" ? "overview" : v;
        }

        onOpened: {
            Events.refresh(false);
            const want = page(Panels.dashboardTab || (hub ? "home" : Settings.data.dashboard.defaultTab || "overview"));
            tab = indexOf(want) >= 0 ? want : pageTabs[0].value;
            Panels.dashboardTab = "";
        }
        onTabChanged: if (shouldShow) Panels.dashboardShown = tab
        // separate Connections so OverlayPanel's own shouldShow handler keeps running
        Connections {
            target: panel
            function onShouldShowChanged() {
                Panels.dashboardShown = panel.shouldShow ? panel.tab : "";
            }
        }

        // switching tabs while already open (e.g. clicking the bar's media chip)
        Connections {
            target: Panels
            function onDashboardTabChanged() {
                if (panel.shouldShow && Panels.dashboardTab) {
                    panel.select(Panels.dashboardTab);
                    Panels.dashboardTab = "";
                }
            }
        }

        function select(t) {
            if (t === "settings") {
                Panels.openSettings("clock");
                return;
            }
            if (indexOf(page(t)) >= 0)
                tab = page(t);
        }
        function cycle(step) {
            const n = pageTabs.length;
            tab = pageTabs[(tabIndex + step + n) % n].value;
        }

        function openSettings(page) {
            Panels.openSettings(page);
        }

        Shortcut {
            enabled: panel.shouldShow
            sequences: ["Ctrl+Tab"]
            onActivated: panel.cycle(1)
        }
        Shortcut {
            enabled: panel.shouldShow
            sequences: ["Ctrl+Shift+Tab", "Ctrl+Backtab"]
            onActivated: panel.cycle(-1)
        }

        RowLayout {
            width: parent.width
            spacing: Theme.sp4

            // ── hub: the rail ──
            Rectangle {
                id: rail
                visible: panel.hub
                Layout.preferredWidth: 84
                Layout.fillHeight: true
                radius: Theme.rXl
                color: Theme.alpha(Theme.bg, 0.45)
                // tall enough for every entry and the hint under them
                Layout.minimumHeight: railItems.implicitHeight + 50

                Column {
                    id: railItems
                    anchors.top: parent.top
                    anchors.topMargin: 10
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 6

                    Repeater {
                        model: panel.hub ? panel.tabs : []
                        Rectangle {
                            id: item
                            required property var modelData
                            readonly property bool sel: !modelData.action && panel.tab === modelData.value
                            width: 68
                            height: 64
                            radius: Theme.rLg
                            gradient: Gradient {
                                GradientStop { position: 0; color: item.sel ? Theme.accent : "transparent" }
                                GradientStop { position: 1; color: item.sel ? Theme.accent2 : "transparent" }
                            }
                            // a separator before the actions
                            Rectangle {
                                visible: item.modelData.value === "system"
                                anchors.bottom: parent.top
                                anchors.bottomMargin: 2
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 32
                                height: 1
                                color: Theme.alpha(Theme.text, 0.15)
                            }
                            Column {
                                anchors.centerIn: parent
                                spacing: 3
                                FIcon {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    icon: item.modelData.icon
                                    size: 22
                                    fill: item.sel ? 1 : 0
                                    color: item.sel ? Theme.onAccent : Theme.text
                                }
                                FText {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: item.modelData.label
                                    font.pixelSize: Theme.fsXs
                                    font.weight: item.sel ? Font.Bold : Font.DemiBold
                                    color: item.sel ? Theme.onAccent : Theme.textDim
                                }
                            }
                            StateLayer {
                                radius: parent.radius
                                tint: item.sel ? Theme.onAccent : Theme.text
                                onClicked: panel.select(item.modelData.value)
                            }
                        }
                    }
                }

                FText {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 10
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Ctrl+Tab"
                    dim: true
                    font.pixelSize: Theme.fsXs
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.sp4

                // ── tabs layout: the tab bar ──
                Rectangle {
                    id: tabBar
                    visible: !panel.hub
                    Layout.fillWidth: true
                    implicitHeight: 46
                    radius: height / 2
                    color: Theme.surfaceHigh

                    readonly property real seg: (width - 8) / panel.tabs.length
                    readonly property int selIndex: Math.max(0, panel.tabs.findIndex(t => t.value === panel.tab))

                    Rectangle {
                        y: 4
                        x: 4 + tabBar.selIndex * parent.seg
                        width: parent.seg
                        height: parent.height - 8
                        radius: height / 2
                        color: Theme.accent
                        Behavior on x { Anim { duration: Theme.durLong; easing.bezierCurve: Theme.curves.spring } }
                    }

                    Row {
                        x: 4
                        y: 4
                        Repeater {
                            model: panel.hub ? [] : panel.tabs
                            Item {
                                required property var modelData
                                required property int index
                                readonly property bool sel: index === tabBar.selIndex
                                width: tabBar.seg
                                height: tabBar.height - 8

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    FIcon {
                                        anchors.verticalCenter: parent.verticalCenter
                                        icon: modelData.icon
                                        size: 18
                                        fill: sel ? 1 : 0
                                        color: sel ? Theme.onAccent : Theme.text
                                    }
                                    FText {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.label
                                        font.pixelSize: Theme.fsSm
                                        font.weight: sel ? Font.Bold : Font.Medium
                                        color: sel ? Theme.onAccent : Theme.text
                                    }
                                }
                                StateLayer {
                                    radius: height / 2
                                    tint: sel ? Theme.onAccent : Theme.text
                                    onClicked: panel.select(modelData.value)
                                }
                            }
                        }
                    }
                }

                // ── pages ──
                Item {
                    id: pages
                    Layout.fillWidth: true
                    // hub: one steady height (Home's, or the rail's if taller), so moving between
                    // pages doesn't shrink the panel and cut the rail off; tabs: each page's own
                    implicitHeight: panel.hub ? Math.max(hubH, current ? current.implicitHeight : 0)
                        : current ? current.implicitHeight : 0
                    clip: true

                    // Home's height, kept from when it last showed (a hidden page can report 0)
                    property real homeH: 0
                    readonly property var byTab: ({ home: home, calendar: calendar, overview: overview, media: panel.hub ? hubMedia : media, wallpapers: panel.hub ? hubWalls : walls, weather: panel.hub ? hubWeather : weather, system: system })
                    // the height the hub's full pages fill: Home's (or the rail's), but never
                    // more than fits on this screen under the bar
                    readonly property real fitH: panel.modelData.height - Theme.barHeight - Theme.gap * 6 - panel.cardPadding * 2
                    readonly property real hubH: Math.min(Math.max(homeH, railItems.implicitHeight + 50), Math.max(420, fitH))
                    readonly property Item current: byTab[panel.tab] ?? null

                    Behavior on implicitHeight { Anim { easing.bezierCurve: Theme.curves.emphasizedDecel } }

                    DashboardPage {
                        id: home
                        width: pages.width
                        currentIndex: panel.tabIndex
                        index: panel.indexOf("home")
                        onImplicitHeightChanged: if (active && implicitHeight > 0) pages.homeH = implicitHeight
                        onActiveChanged: if (active && implicitHeight > 0) pages.homeH = implicitHeight
                        HubHome {
                            width: pages.width
                            screenName: panel.modelData.name
                            live: panel.shouldShow && panel.tab === "home"
                            onOpenTab: t => panel.select(t)
                        }
                    }
                    // the hub's own Media and System pages
                    DashboardPage {
                        id: hubMedia
                        width: pages.width
                        currentIndex: panel.tabIndex
                        index: panel.hub ? panel.indexOf("media") : -1
                        HubMedia {
                            width: pages.width
                            fillHeight: pages.hubH
                            live: panel.shouldShow && panel.hub && panel.tab === "media"
                        }
                    }
                    DashboardPage {
                        id: system
                        width: pages.width
                        currentIndex: panel.tabIndex
                        index: panel.indexOf("system")
                        HubSystem {
                            width: pages.width
                            live: panel.shouldShow && panel.tab === "system"
                        }
                    }
                    DashboardPage {
                        id: calendar
                        width: pages.width
                        currentIndex: panel.tabIndex
                        index: panel.indexOf("calendar")
                        HubCalendar {
                            width: pages.width
                            fillHeight: pages.hubH
                        }
                    }
                    DashboardPage {
                        id: hubWeather
                        width: pages.width
                        currentIndex: panel.tabIndex
                        index: panel.hub ? panel.indexOf("weather") : -1
                        HubWeather {
                            width: pages.width
                            fillHeight: pages.hubH
                            onOpenSettings: p => panel.openSettings(p)
                        }
                    }
                    DashboardPage {
                        id: hubWalls
                        width: pages.width
                        currentIndex: panel.tabIndex
                        index: panel.hub ? panel.indexOf("wallpapers") : -1
                        HubWallpaper {
                            width: pages.width
                            fillHeight: pages.hubH
                            screenName: panel.modelData.name
                            onOpenSettings: p => panel.openSettings(p)
                        }
                    }
                    DashboardPage {
                        id: overview
                        width: pages.width
                        currentIndex: panel.tabIndex
                        index: panel.indexOf("overview")
                        OverviewTab {
                            width: pages.width
                            onOpenTab: t => panel.select(t)
                        }
                    }
                    DashboardPage {
                        id: media
                        width: pages.width
                        currentIndex: panel.tabIndex
                        index: panel.hub ? -1 : panel.indexOf("media")
                        MediaTab { width: pages.width }
                    }
                    DashboardPage {
                        id: walls
                        width: pages.width
                        currentIndex: panel.tabIndex
                        index: panel.hub ? -1 : panel.indexOf("wallpapers")
                        WallpapersTab {
                            width: pages.width
                            screenName: panel.modelData.name
                            onOpenSettings: p => panel.openSettings(p)
                        }
                    }
                    DashboardPage {
                        id: weather
                        width: pages.width
                        currentIndex: panel.tabIndex
                        index: panel.hub ? -1 : panel.indexOf("weather")
                        WeatherTab {
                            width: pages.width
                            onOpenSettings: p => panel.openSettings(p)
                        }
                    }
                }
            }
        }
    }
}
