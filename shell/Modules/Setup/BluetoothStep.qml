import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.Commons
import qs.Services
import qs.Widgets
import qs.Modules.Settings.Pages

// Setup step: turn Bluetooth on, find devices, pair / connect.
Page {
    id: page
    title: I18n.tr("Bluetooth")
    subtitle: BluetoothState.available ? I18n.tr("Turn Bluetooth on and connect your headphones, mouse or keyboard. You can skip this.") : I18n.tr("No Bluetooth adapter was found. You can skip this step.")

    Group {
        visible: BluetoothState.available
        SettingRow {
            title: I18n.tr("Bluetooth")
            subtitle: BluetoothState.enabled ? I18n.tr("On") : I18n.tr("Off")
            icon: BluetoothState.icon
            FSwitch {
                checked: BluetoothState.enabled
                onToggled: c => BluetoothState.setEnabled(c)
            }
        }
        SettingRow {
            visible: BluetoothState.enabled
            title: (BluetoothState.adapter?.discovering ?? false) ? I18n.tr("Looking for devices…") : I18n.tr("Find devices")
            subtitle: I18n.tr("Put your device in pairing mode first")
            icon: "radar"
            FButton {
                text: (BluetoothState.adapter?.discovering ?? false) ? I18n.tr("Stop") : I18n.tr("Scan")
                variant: "tonal"
                onClicked: BluetoothState.setDiscovering(!(BluetoothState.adapter?.discovering ?? false))
            }
        }
    }

    Group {
        visible: BluetoothState.enabled && BluetoothState.devices.length > 0
        title: I18n.tr("Devices")
        Repeater {
            model: BluetoothState.devices
            SettingRow {
                id: drow
                required property var modelData
                readonly property bool busy: modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting
                title: modelData.name || modelData.address
                subtitle: busy ? I18n.tr("Working…") : modelData.connected ? I18n.tr("Connected") : modelData.paired ? I18n.tr("Paired") : I18n.tr("Available")
                icon: modelData.icon?.includes("audio") || modelData.icon?.includes("headset") ? "headphones" : modelData.icon?.includes("input") ? "mouse" : modelData.icon?.includes("phone") ? "smartphone" : "bluetooth"
                FButton {
                    text: drow.modelData.connected ? I18n.tr("Disconnect") : I18n.tr("Connect")
                    variant: drow.modelData.connected ? "outlined" : "filled"
                    disabled: drow.busy
                    onClicked: BluetoothState.toggleDevice(drow.modelData)
                }
            }
        }
    }
}
