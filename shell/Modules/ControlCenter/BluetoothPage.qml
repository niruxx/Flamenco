import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.Commons
import qs.Services
import qs.Widgets

DetailPage {
    title: "Bluetooth"

    headerExtra: [
        FIconButton {
            icon: "radar"
            active: BluetoothState.adapter?.discovering ?? false
            onClicked: BluetoothState.setDiscovering(!(BluetoothState.adapter?.discovering ?? false))
        },
        FSwitch {
            anchors.verticalCenter: parent.verticalCenter
            checked: BluetoothState.enabled
            onToggled: c => BluetoothState.setEnabled(c)
        }
    ]

    Repeater {
        model: BluetoothState.devices

        ListRow {
            required property var modelData
            icon: modelData.icon?.includes("audio") || modelData.icon?.includes("headset") ? "headphones" : modelData.icon?.includes("input") ? "mouse" : modelData.icon?.includes("phone") ? "smartphone" : "bluetooth"
            title: modelData.name || modelData.address
            subtitle: (modelData.connected ? "Connected" : modelData.paired ? "Paired" : "Available") + (modelData.batteryAvailable ? " · " + Math.round(modelData.battery * 100) + "%" : "")
            selected: modelData.connected
            busy: modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting
            onClicked: BluetoothState.toggleDevice(modelData)
        }
    }
}
