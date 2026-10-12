import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

// The dashboard, opened from the bar clock: Overview · Media · Wallpapers · Weather · Settings.
// (Panel name stays "calendar" so `flamenco calendar` and existing binds keep working.)
Variants {
    model: Quickshell.screens

    OverlayPanel {
        id: panel
        name: "calendar"
        cardWidth: 560

        readonly property var tabs: [
            { value: "overview", label: "Overview", icon: "dashboard" },
            { value: "media", label: "Media", icon: "music_note" },
            { value: "wallpapers", label: "Wallpapers", icon: "wallpaper" },
            { value: "weather", label: "Weather", icon: "partly_cloudy_day" },
            { value: "settings", label: "Settings", icon: "settings" }
        ]
        property string tab: Settings.data.dashboard.defaultTab
        readonly property int tabIndex: Math.max(0, tabs.findIndex(t => t.value === tab))
        property int lastIndex: 0

        onOpened: tab = Settings.data.dashboard.defaultTab || "overview"

        function select(t) {
            if (t === "settings") {
                Panels.openSettings("clock");
                return;
            }
            lastIndex = tabIndex;
            tab = t;
        }

        function openSettings(page) {
            Panels.openSettings(page);
        }

        ColumnLayout {
            width: parent.width
            spacing: Theme.sp4

            // ── tab bar ──
            Rectangle {
                id: tabBar
                Layout.fillWidth: true
                implicitHeight: 46
                radius: height / 2
                color: Theme.surfaceHigh

                readonly property real seg: (width - 8) / panel.tabs.length

                Rectangle {
                    y: 4
                    x: 4 + panel.tabIndex * parent.seg
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
                        model: panel.tabs
                        Item {
                            required property var modelData
                            required property int index
                            readonly property bool sel: index === panel.tabIndex
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
                implicitHeight: current ? current.implicitHeight : 0
                clip: true

                readonly property Item current: [overview, media, walls, weather][Math.min(3, panel.tabIndex)] ?? null

                Behavior on implicitHeight { Anim { easing.bezierCurve: Theme.curves.emphasizedDecel } }

                DashboardPage {
                    width: pages.width
                    currentIndex: panel.tabIndex
                    id: overview
                    index: 0
                    OverviewTab {
                        width: pages.width
                        onOpenTab: t => panel.select(t)
                    }
                }
                DashboardPage {
                    width: pages.width
                    currentIndex: panel.tabIndex
                    id: media
                    index: 1
                    MediaTab { width: pages.width }
                }
                DashboardPage {
                    width: pages.width
                    currentIndex: panel.tabIndex
                    id: walls
                    index: 2
                    WallpapersTab {
                        width: pages.width
                        onOpenSettings: p => panel.openSettings(p)
                    }
                }
                DashboardPage {
                    width: pages.width
                    currentIndex: panel.tabIndex
                    id: weather
                    index: 3
                    WeatherTab {
                        width: pages.width
                        onOpenSettings: p => panel.openSettings(p)
                    }
                }
            }
        }
    }
}
