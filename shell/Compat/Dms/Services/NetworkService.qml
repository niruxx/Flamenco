pragma Singleton

import QtQuick
import Quickshell
import qs.Services as FS

// Flamenco shim for DMS's NetworkService.
Singleton {
    readonly property bool wifiEnabled: FS.Network.wifiEnabled ?? true
    readonly property bool wifiConnected: FS.Network.connected && !FS.Network.ethernet
    readonly property bool ethernetConnected: !!FS.Network.ethernet
    readonly property string currentWifiSSID: FS.Network.ssid ?? ""
    readonly property int wifiSignalStrength: FS.Network.signal ?? 0
    readonly property string networkStatus: ethernetConnected ? "ethernet" : wifiConnected ? "wifi" : "disconnected"
    function addRef() {}
    function removeRef() {}
    function scanWifi() {}
    function toggleWifiRadio() {
        Quickshell.execDetached(["nmcli", "radio", "wifi", wifiEnabled ? "off" : "on"]);
    }
}
