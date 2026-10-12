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
    title: "Bluetooth"
    subtitle: BluetoothState.available ? "Turn Bluetooth on and connect your headphones, mouse or keyboard. You can skip this." : "No Bluetooth adapter was found. You can skip this step."

    Group {
        visible: BluetoothState.available
        SettingRow {
            title: "Bluetooth"
            subtitle: BluetoothState.enabled ? "On" : "Off"
            icon: BluetoothState.icon
            FSwitch {
                checked: BluetoothState.enabled
                onToggled: c => BluetoothState.setEnabled(c)
            }
        }
        SettingRow {
            visible: BluetoothState.enabled
            title: (BluetoothState.adapter?.discovering ?? false) ? "Looking for devices…" : "Find devices"
            subtitle: "Put your device in pairing mode first"
            icon: "radar"
            FButton {
                text: (BluetoothState.adapter?.discovering ?? false) ? "Stop" : "Scan"
                variant: "tonal"
                onClicked: BluetoothState.setDiscovering(!(BluetoothState.adapter?.discovering ?? false))
            }
        }
    }

    Group {
        visible: BluetoothState.enabled && BluetoothState.devices.length > 0
        title: "Devices"
        Repeater {
            model: BluetoothState.devices
            SettingRow {
                id: drow
                required property var modelData
                readonly property bool busy: modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting
                title: modelData.name || modelData.address
                subtitle: busy ? "Working…" : modelData.connected ? "Connected" : modelData.paired ? "Paired" : "Available"
                icon: modelData.icon?.includes("audio") || modelData.icon?.includes("headset") ? "headphones" : modelData.icon?.includes("input") ? "mouse" : modelData.icon?.includes("phone") ? "smartphone" : "bluetooth"
                FButton {
                    text: drow.modelData.connected ? "Disconnect" : "Connect"
                    variant: drow.modelData.connected ? "outlined" : "filled"
                    disabled: drow.busy
                    onClicked: BluetoothState.toggleDevice(drow.modelData)
                }
            }
        }
    }
}
