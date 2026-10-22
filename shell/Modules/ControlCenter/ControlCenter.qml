import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.Commons
import qs.Services
import qs.Widgets

Variants {
    model: Quickshell.screens

    OverlayPanel {
        id: panel
        name: "control"
        hAlign: Settings.data.control.align === "auto" ? "right" : Settings.data.control.align
        followOrigin: Settings.data.control.align === "auto"
        cardWidth: Math.max(340, Settings.data.control.width)

        readonly property string detail: Panels.controlDetail
        readonly property var qs: Settings.data.control
        // the grid: pill tiles, editable by pressing and holding (TileGrid)
        readonly property bool grid: (qs.style || "grid") === "grid"
        readonly property var allTiles: ["wifi", "bluetooth", "dnd", "night", "caffeine", "power", "vpn", "dark", "record", "widgets", "wallpaper"]
        readonly property var tileIds: (qs.tiles && qs.tiles.length ? qs.tiles : allTiles).filter(t => allTiles.includes(t))
        readonly property var tileComps: ({ wifi: tile_wifi, bluetooth: tile_bluetooth, dnd: tile_dnd, night: tile_night, caffeine: tile_caffeine, power: tile_power, vpn: tile_vpn, dark: tile_dark, record: tile_record, widgets: tile_widgets, wallpaper: tile_wallpaper })

        ColumnLayout {
            width: parent.width
            spacing: Theme.sp4

            Header { Layout.fillWidth: true; visible: !panel.grid && panel.qs.sections.header !== false }

            // ── pager: main page ⇄ detail page ──
            Item {
                id: pager
                Layout.fillWidth: true
                implicitHeight: panel.detail !== "" ? Math.max(main.implicitHeight, 380) : main.implicitHeight
                clip: true

                property real slide: panel.detail !== "" ? 1 : 0
                Behavior on slide { Anim { duration: Theme.durLong; easing.bezierCurve: Theme.curves.emphasized } }

                ColumnLayout {
                    id: main
                    width: parent.width
                    x: -pager.slide * pager.width * 0.3
                    opacity: 1 - pager.slide
                    visible: opacity > 0
                    spacing: Theme.sp4

                    TileGrid {
                        visible: panel.grid
                        Layout.fillWidth: true
                        screenName: panel.modelData.name
                        onOpenDetail: d => Panels.controlDetail = d
                    }

                    SlidersCard {
                        Layout.fillWidth: true
                        visible: !panel.grid && panel.qs.sections.sliders !== false
                        onOpenDetail: d => Panels.controlDetail = d
                    }

                    GridLayout {
                        visible: !panel.grid && panel.qs.sections.tiles !== false
                        Layout.fillWidth: true
                        columns: Math.max(1, panel.qs.columns || 2)
                        rowSpacing: Theme.gap
                        columnSpacing: Theme.gap

                        // tiles in the order chosen in Settings → Quick settings
                        Repeater {
                            model: panel.tileIds
                            Loader {
                                required property string modelData
                                Layout.fillWidth: true
                                sourceComponent: panel.tileComps[modelData] ?? null
                            }
                        }
                    }

                    MediaCard {
                        Layout.fillWidth: true
                        visible: !panel.grid && Media.active && panel.qs.sections.media !== false
                    }
                }

                Loader {
                    width: parent.width
                    height: pager.height
                    x: (1 - pager.slide) * pager.width * 0.4
                    opacity: pager.slide
                    visible: opacity > 0
                    active: panel.detail !== "" || opacity > 0
                    sourceComponent: panel.detail === "wifi" ? wifiC : panel.detail === "bluetooth" ? btC : panel.detail === "audio" ? audioC : panel.detail === "mic" ? micC : panel.detail === "mixer" ? mixerC : panel.detail === "night" ? nightC : panel.detail === "vpn" ? vpnC : panel.detail === "power" ? powerC : null
                }
            }
        }

        Component {
            id: tile_wifi
                    FTile {
                        Layout.fillWidth: true
                        tint: Theme.accent
                        icon: Network.icon
                        title: "Wi-Fi"
                        subtitle: Network.label
                        active: Network.wifiEnabled
                        hasDetails: true
                        onClicked: Network.setWifi(!Network.wifiEnabled)
                        onDetailsClicked: {
                            Panels.controlDetail = "wifi";
                            Network.scan(true);
                        }
                    }
        }

        Component {
            id: tile_bluetooth
                    FTile {
                        Layout.fillWidth: true
                        tint: Theme.accent2
                        icon: BluetoothState.icon
                        title: "Bluetooth"
                        subtitle: BluetoothState.label
                        active: BluetoothState.enabled
                        hasDetails: BluetoothState.available
                        onClicked: BluetoothState.setEnabled(!BluetoothState.enabled)
                        onDetailsClicked: Panels.controlDetail = "bluetooth"
                    }
        }

        Component {
            id: tile_dnd
                    FTile {
                        Layout.fillWidth: true
                        tint: Theme.accent3
                        icon: "do_not_disturb_on"
                        title: "Do not disturb"
                        subtitle: Notifs.dnd ? "On" : "Off"
                        active: Notifs.dnd
                        onClicked: Notifs.setDnd(!Notifs.dnd)
                    }
        }

        Component {
            id: tile_night
                    FTile {
                        Layout.fillWidth: true
                        tint: Theme.warning
                        icon: "nightlight"
                        title: "Night light"
                        subtitle: Toggles.status
                        active: Toggles.nightLight
                        hasDetails: true
                        onClicked: Toggles.setNightLight(!Toggles.nightLight)
                        onDetailsClicked: Panels.controlDetail = "night"
                    }
        }

        Component {
            id: tile_caffeine
                    FTile {
                        Layout.fillWidth: true
                        tint: Theme.accent2
                        icon: "coffee"
                        title: "Caffeine"
                        subtitle: Toggles.caffeine ? "Staying awake" : "Off"
                        active: Toggles.caffeine
                        onClicked: Toggles.caffeine = !Toggles.caffeine
                    }
        }

        Component {
            id: tile_power
                    FTile {
                        Layout.fillWidth: true
                        tint: Theme.accent
                        icon: Power.profileIcon
                        title: "Power"
                        subtitle: Power.profileName
                        active: Power.profileName !== "Balanced"
                        hasDetails: true
                        onClicked: Power.cycleProfile()
                        onDetailsClicked: Panels.controlDetail = "power"
                    }
        }

        Component {
            id: tile_vpn
                    FTile {
                        Layout.fillWidth: true
                        tint: Theme.accent3
                        icon: Network.vpnActive ? "vpn_lock" : "vpn_key"
                        title: "VPN"
                        subtitle: Network.vpnActive ? Network.activeVpns.map(v => v.name).join(", ") : Network.vpns.length ? "Off" : "Not set up"
                        active: Network.vpnActive
                        hasDetails: true
                        onClicked: {
                            if (Network.vpnActive)
                                Network.activeVpns.forEach(v => Network.setVpn(v.name, false));
                            else if (Network.vpns.length === 1)
                                Network.setVpn(Network.vpns[0].name, true);
                            else
                                Panels.controlDetail = "vpn";
                        }
                        onDetailsClicked: Panels.controlDetail = "vpn"
                    }
        }

        Component {
            id: tile_dark
                    FTile {
                        Layout.fillWidth: true
                        tint: Theme.accent2
                        icon: Theme.dark ? "dark_mode" : "light_mode"
                        title: "Dark mode"
                        subtitle: Theme.dark ? "On" : "Off"
                        active: Theme.dark
                        onClicked: Settings.data.appearance.mode = Theme.dark ? "light" : "dark"
                    }
        }

        Component {
            id: tile_record
                    FTile {
                        Layout.fillWidth: true
                        tint: Theme.error
                        icon: Recorder.recording ? "stop_circle" : "screen_record"
                        title: Recorder.recording ? "Stop recording" : "Record screen"
                        subtitle: Recorder.recording ? Recorder.clock : "This screen · ⋯ for an area"
                        active: Recorder.recording
                        hasDetails: !Recorder.recording
                        onClicked: {
                            Panels.close();
                            Recorder.toggle("screen", panel.modelData.name);
                        }
                        onDetailsClicked: {
                            Panels.close();
                            Recorder.start("region", "");
                        }
                    }
        }

        Component {
            id: tile_widgets
                    FTile {
                        Layout.fillWidth: true
                        tint: Theme.accent3
                        icon: "widgets"
                        title: "Desktop widgets"
                        subtitle: Settings.data.desktop.enabled ? (Settings.data.desktop.widgets.length ? Settings.data.desktop.widgets.length + " on the desktop" : "Add some") : "Off"
                        active: Settings.data.desktop.enabled && Settings.data.desktop.widgets.length > 0
                        onClicked: {
                            Settings.data.desktop.enabled = true;
                            Panels.editWidgets(panel.modelData.name);
                        }
                    }
        }

        Component {
            id: tile_wallpaper
                    FTile {
                        Layout.fillWidth: true
                        tint: Theme.accent
                        icon: "wallpaper"
                        title: "Wallpaper"
                        subtitle: Paths.fileName(Wallpapers.current) || "None"
                        onClicked: Panels.toggle("wallpaper", panel.modelData.name)
                    }
        }

        Component { id: wifiC; WifiPage { onBack: Panels.controlDetail = "" } }
        Component { id: btC; BluetoothPage { onBack: Panels.controlDetail = "" } }
        Component { id: audioC; AudioDevicesPage { onBack: Panels.controlDetail = ""; input: false } }
        Component { id: vpnC; VpnPage { onBack: Panels.controlDetail = "" } }
        Component { id: powerC; PowerPage { onBack: Panels.controlDetail = "" } }
        Component { id: micC; AudioDevicesPage { onBack: Panels.controlDetail = ""; input: true } }
        Component { id: mixerC; MixerPage { onBack: Panels.controlDetail = "" } }
        Component { id: nightC; NightPage { onBack: Panels.controlDetail = "" } }
    }
}
