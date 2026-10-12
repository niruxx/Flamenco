import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: "Network"
    subtitle: "Wi-Fi and VPN connections, through NetworkManager."

    Component.onCompleted: Network.refresh()

    Group {
        title: "Wi-Fi"
        SettingRow {
            title: "Wi-Fi"
            subtitle: Network.label
            icon: Network.icon
            FSwitch {
                checked: Network.wifiEnabled
                onToggled: c => Network.setWifi(c)
            }
        }
        SettingRow {
            title: "Networks"
            subtitle: "Pick a network from the control center"
            icon: "wifi_find"
            FButton {
                text: "Show networks"
                variant: "tonal"
                onClicked: Panels.openControl("wifi", "")
            }
        }
    }

    Group {
        title: "VPN"

        SettingRow {
            visible: Network.vpns.length === 0
            title: "No VPN connections yet"
            subtitle: "Import one below, or create it with nm-connection-editor"
            icon: "vpn_key_off"
        }

        Repeater {
            model: Network.vpns
            SettingRow {
                id: vrow
                required property var modelData
                title: modelData.name
                subtitle: (modelData.type === "wireguard" ? "WireGuard" : "VPN") + " · " + (Network.vpnBusy === modelData.name ? "working…" : modelData.active ? "Connected" : "Disconnected")
                icon: modelData.active ? "vpn_lock" : "vpn_key"
                Row {
                    spacing: 6
                    FSwitch {
                        anchors.verticalCenter: parent.verticalCenter
                        checked: vrow.modelData.active
                        onToggled: c => Network.setVpn(vrow.modelData.name, c)
                    }
                    FIconButton {
                        icon: "delete"
                        size: 32
                        iconColor: Theme.error
                        onClicked: Network.deleteVpn(vrow.modelData.name)
                    }
                }
            }
        }

        SettingRow {
            title: "Import"
            subtitle: "WireGuard .conf or OpenVPN .ovpn file. OpenVPN needs networkmanager-openvpn."
            icon: "upload_file"
            Row {
                spacing: 8
                FTextField {
                    id: importPath
                    implicitWidth: 240
                    icon: "description"
                    placeholder: "~/Downloads/wg0.conf"
                    onAccepted: if (text) Network.importVpn(text)
                }
                FButton {
                    text: "Import"
                    disabled: importPath.text === ""
                    onClicked: Network.importVpn(importPath.text)
                }
            }
        }

        SettingRow {
            visible: Network.lastError !== ""
            title: "Last error"
            subtitle: Network.lastError
            icon: "error"
        }

        SettingRow {
            title: "Advanced"
            subtitle: "Edit every NetworkManager connection (needs nm-connection-editor)"
            icon: "settings_ethernet"
            FButton {
                text: "Connection editor"
                variant: "tonal"
                onClicked: Quickshell.execDetached(["nm-connection-editor"])
            }
        }
    }
}
