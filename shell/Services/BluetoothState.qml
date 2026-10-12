pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth

Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property var devices: (adapter?.devices?.values ?? []).slice().sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired))
    readonly property var connected: devices.filter(d => d.connected)
    readonly property string icon: !enabled ? "bluetooth_disabled" : connected.length > 0 ? "bluetooth_connected" : "bluetooth"
    readonly property string label: !enabled ? "Off" : connected.length > 0 ? connected[0].name : "On"

    function setEnabled(on) {
        if (adapter)
            adapter.enabled = on;
    }

    function setDiscovering(on) {
        if (adapter)
            adapter.discovering = on;
    }

    function toggleDevice(d) {
        if (d.connected)
            d.disconnect();
        else
            d.connect();
    }
}
