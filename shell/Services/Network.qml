pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// NetworkManager via nmcli.
Singleton {
    id: root

    property bool wifiEnabled: true
    property bool ethernet: false
    property string ssid: ""
    property int signal: 0
    property var networks: []           // [{ ssid, signal, secure, active }]
    property bool scanning: false
    property string connecting: ""
    property string lastError: ""
    property var vpns: []               // [{ name, type, active }]  type: wireguard | vpn (OpenVPN, etc.)
    property string vpnBusy: ""
    readonly property var activeVpns: vpns.filter(v => v.active)
    readonly property bool vpnActive: activeVpns.length > 0

    readonly property bool connected: ethernet || ssid !== ""
    readonly property string icon: ethernet ? "lan" : !wifiEnabled ? "wifi_off" : ssid === "" ? "signal_wifi_statusbar_not_connected" : signal > 75 ? "signal_wifi_4_bar" : signal > 50 ? "network_wifi_3_bar" : signal > 25 ? "network_wifi_2_bar" : "network_wifi_1_bar"
    readonly property string label: ethernet ? "Ethernet" : ssid !== "" ? ssid : wifiEnabled ? "Not connected" : "Off"

    // nmcli -t escapes ':' as '\:'
    function splitTerse(line) {
        const out = [];
        let cur = "";
        for (let i = 0; i < line.length; i++) {
            const c = line[i];
            if (c === "\\" && i + 1 < line.length) {
                cur += line[++i];
            } else if (c === ":") {
                out.push(cur);
                cur = "";
            } else {
                cur += c;
            }
        }
        out.push(cur);
        return out;
    }

    function refresh() {
        if (!vpnList.running)
            vpnList.running = true;
        if (!status.running)
            status.running = true;
        if (!radio.running)
            radio.running = true;
    }

    function scan(rescan) {
        scanning = true;
        list.command = ["nmcli", "-t", "-f", "IN-USE,SIGNAL,SSID,SECURITY", "device", "wifi", "list", "--rescan", rescan ? "yes" : "no"];
        list.running = true;
    }

    function setWifi(on) {
        wifiEnabled = on;
        Quickshell.execDetached(["nmcli", "radio", "wifi", on ? "on" : "off"]);
    }

    function connect(ssid, password) {
        connecting = ssid;
        lastError = "";
        connector.command = password ? ["nmcli", "device", "wifi", "connect", ssid, "password", password] : ["nmcli", "device", "wifi", "connect", ssid];
        connector.running = true;
    }

    function setVpn(name, on) {
        vpnBusy = name;
        lastError = "";
        vpnProc.command = ["nmcli", "connection", on ? "up" : "down", "id", name];
        vpnProc.running = true;
    }

    function deleteVpn(name) {
        lastError = "";
        vpnProc.command = ["nmcli", "connection", "delete", "id", name];
        vpnProc.running = true;
    }

    // Import a WireGuard (.conf) or OpenVPN (.ovpn) file into NetworkManager.
    function importVpn(path) {
        const p = String(path).replace(/^~(?=\/)/, Quickshell.env("HOME"));
        const type = p.toLowerCase().endsWith(".ovpn") ? "openvpn" : "wireguard";
        lastError = "";
        vpnProc.command = ["nmcli", "connection", "import", "type", type, "file", p];
        vpnProc.running = true;
    }

    function disconnect() {
        Quickshell.execDetached(["sh", "-c", "nmcli -t -f DEVICE,TYPE device | awk -F: '$2==\"wifi\"{print $1; exit}' | xargs -r nmcli device disconnect"]);
    }

    Component.onCompleted: refresh()

    Process {
        id: status
        command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "device", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                let eth = false, ss = "";
                for (const line of text.trim().split("\n")) {
                    const [type, state, conn] = root.splitTerse(line);
                    if (state !== "connected")
                        continue;
                    if (type === "ethernet")
                        eth = true;
                    else if (type === "wifi")
                        ss = conn;
                }
                root.ethernet = eth;
                root.ssid = ss;
                if (ss !== "")
                    root.scan(false);
            }
        }
    }

    Process {
        id: radio
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: root.wifiEnabled = text.trim() === "enabled"
        }
    }

    Process {
        id: list
        stdout: StdioCollector {
            onStreamFinished: {
                const seen = {};
                const nets = [];
                for (const line of text.trim().split("\n")) {
                    if (!line)
                        continue;
                    const [inUse, sig, ssid, sec] = root.splitTerse(line);
                    if (!ssid || seen[ssid])
                        continue;
                    seen[ssid] = true;
                    const n = { ssid, signal: parseInt(sig) || 0, secure: !!sec && sec !== "--", active: inUse === "*" };
                    if (n.active)
                        root.signal = n.signal;
                    nets.push(n);
                }
                nets.sort((a, b) => (b.active - a.active) || (b.signal - a.signal));
                root.networks = nets;
                root.scanning = false;
            }
        }
    }

    Process {
        id: connector
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) root.lastError = text.trim()
        }
        onExited: code => {
            root.connecting = "";
            root.refresh();
        }
    }

    Process {
        id: vpnList
        command: ["nmcli", "-t", "-f", "NAME,TYPE,ACTIVE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.trim().split("\n")) {
                    if (!line)
                        continue;
                    const [name, type, active] = root.splitTerse(line);
                    if (type === "vpn" || type === "wireguard")
                        out.push({ name, type, active: active === "yes" });
                }
                root.vpns = out.sort((a, b) => (b.active - a.active) || a.name.localeCompare(b.name));
            }
        }
    }

    Process {
        id: vpnProc
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) root.lastError = text.trim().split("\n").pop()
        }
        onExited: {
            root.vpnBusy = "";
            root.refresh();
        }
    }

    // React to NetworkManager changes instead of polling.
    Process {
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: debounce.restart()
        }
    }

    Timer {
        id: debounce
        interval: 600
        onTriggered: root.refresh()
    }
}
