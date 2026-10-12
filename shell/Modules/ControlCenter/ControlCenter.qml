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
        hAlign: "right"
        cardWidth: 440

        readonly property string detail: Panels.controlDetail

        ColumnLayout {
            width: parent.width
            spacing: Theme.sp4

            Header {}

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

                    SlidersCard {
                        Layout.fillWidth: true
                        onOpenDetail: d => Panels.controlDetail = d
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: Theme.gap
                        columnSpacing: Theme.gap

                        FTile {
                            Layout.fillWidth: true
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
                        FTile {
                            Layout.fillWidth: true
                            icon: BluetoothState.icon
                            title: "Bluetooth"
                            subtitle: BluetoothState.label
                            active: BluetoothState.enabled
                            hasDetails: BluetoothState.available
                            onClicked: BluetoothState.setEnabled(!BluetoothState.enabled)
                            onDetailsClicked: Panels.controlDetail = "bluetooth"
                        }
                        FTile {
                            Layout.fillWidth: true
                            icon: "do_not_disturb_on"
                            title: "Do not disturb"
                            subtitle: Notifs.dnd ? "On" : "Off"
                            active: Notifs.dnd
                            onClicked: Notifs.setDnd(!Notifs.dnd)
                        }
                        FTile {
                            Layout.fillWidth: true
                            icon: "nightlight"
                            title: "Night light"
                            subtitle: Toggles.nightLight ? Settings.data.night.temperature + "K" : "Off"
                            active: Toggles.nightLight
                            onClicked: Toggles.setNightLight(!Toggles.nightLight)
                        }
                        FTile {
                            Layout.fillWidth: true
                            icon: "coffee"
                            title: "Caffeine"
                            subtitle: Toggles.caffeine ? "Staying awake" : "Off"
                            active: Toggles.caffeine
                            onClicked: Toggles.caffeine = !Toggles.caffeine
                        }
                        FTile {
                            Layout.fillWidth: true
                            icon: Power.profileIcon
                            title: "Power"
                            subtitle: Power.profileName
                            active: Power.profileName !== "Balanced"
                            hasDetails: true
                            onClicked: Power.cycleProfile()
                            onDetailsClicked: Panels.controlDetail = "power"
                        }
                        FTile {
                            Layout.fillWidth: true
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
                        FTile {
                            Layout.fillWidth: true
                            icon: Theme.dark ? "dark_mode" : "light_mode"
                            title: "Dark mode"
                            subtitle: Theme.dark ? "On" : "Off"
                            active: Theme.dark
                            onClicked: Settings.data.appearance.mode = Theme.dark ? "light" : "dark"
                        }
                        FTile {
                            Layout.fillWidth: true
                            icon: "wallpaper"
                            title: "Wallpaper"
                            subtitle: Paths.fileName(Wallpapers.current) || "None"
                            onClicked: Panels.toggle("wallpaper", panel.modelData.name)
                        }
                    }

                    MediaCard {
                        Layout.fillWidth: true
                        visible: Media.active
                    }
                }

                Loader {
                    width: parent.width
                    height: pager.height
                    x: (1 - pager.slide) * pager.width * 0.4
                    opacity: pager.slide
                    visible: opacity > 0
                    active: panel.detail !== "" || opacity > 0
                    sourceComponent: panel.detail === "wifi" ? wifiC : panel.detail === "bluetooth" ? btC : panel.detail === "audio" ? audioC : panel.detail === "mic" ? micC : panel.detail === "vpn" ? vpnC : panel.detail === "power" ? powerC : null
                }
            }
        }

        Component { id: wifiC; WifiPage { onBack: Panels.controlDetail = "" } }
        Component { id: btC; BluetoothPage { onBack: Panels.controlDetail = "" } }
        Component { id: audioC; AudioDevicesPage { onBack: Panels.controlDetail = ""; input: false } }
        Component { id: vpnC; VpnPage { onBack: Panels.controlDetail = "" } }
        Component { id: powerC; PowerPage { onBack: Panels.controlDetail = "" } }
        Component { id: micC; AudioDevicesPage { onBack: Panels.controlDetail = ""; input: true } }
    }
}
