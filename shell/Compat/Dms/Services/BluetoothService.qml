pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth

// Flamenco shim for DMS's BluetoothService.
Singleton {
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property bool discovering: adapter?.discovering ?? false
    readonly property var devices: adapter?.devices?.values ?? []
    function setBluetoothEnabled(on) {
        if (adapter)
            adapter.enabled = on;
    }
    function isDeviceBusy(device) {
        return device?.pairing || device?.state === BluetoothDeviceState.Connecting || device?.state === BluetoothDeviceState.Disconnecting;
    }
    function getDeviceIcon(device) {
        return "bluetooth";
    }
}
