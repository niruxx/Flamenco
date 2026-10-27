pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import qs.Commons

// Bluetooth for the bar, quick settings and Settings → Bluetooth: the adapter and
// its devices (Quickshell, from BlueZ), scanning, and pairing. Pairing goes through
// `flamenco bluetooth pair`, which brings the agent BlueZ needs and asks here when a
// device wants its code confirmed or a PIN typed (`prompt`).
Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property var devices: (adapter?.devices?.values ?? []).slice().sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || String(a.name).localeCompare(String(b.name)))
    readonly property var connected: devices.filter(d => d.connected)
    // yours (paired before), and the ones around that you could pair (with a name, like GNOME)
    readonly property var mine: devices.filter(d => d.paired || d.bonded)
    readonly property var nearby: devices.filter(d => !d.paired && !d.bonded && (hasName(d) || (Settings.data.bluetooth.showUnnamed ?? false)))
    readonly property string icon: !enabled ? "bluetooth_disabled" : connected.length > 0 ? "bluetooth_connected" : "bluetooth"
    readonly property string label: !enabled ? "Off" : connected.length > 0 ? connected[0].name : "On"

    function hasName(d) {
        const n = String(d.name || "");
        return n !== "" && n.replace(/[-:]/g, "").toUpperCase() !== String(d.address || "").replace(/:/g, "").toUpperCase();
    }
    function kindIcon(d) {
        const i = String(d?.icon || "");
        return i.includes("audio") || i.includes("headset") || i.includes("headphone") ? "headphones"
            : i.includes("keyboard") ? "keyboard" : i.includes("mouse") || i.includes("input") ? "mouse"
            : i.includes("phone") ? "smartphone" : i.includes("computer") ? "computer" : i.includes("gaming") ? "videogame_asset" : "bluetooth";
    }

    function setEnabled(on) {
        if (!adapter)
            return;
        // turning it on also lifts an rfkill block (airplane mode, a key on the laptop)
        if (on)
            Quickshell.execDetached([Paths.bin, "bluetooth", "unblock"]);
        adapter.enabled = on;
    }

    // ── scanning: while a Bluetooth page is open, or when asked ──
    readonly property bool scanning: scanner.running || (adapter?.discovering ?? false)
    property int scanUsers: 0
    function startScan() {
        if (!enabled)
            return;
        adapter.discovering = true;
        // bluetoothctl's scan too: discovery asked over D-Bus alone can be dropped
        if (!scanner.running)
            scanner.running = true;
    }
    function stopScan() {
        scanner.running = false;
        if (adapter)
            adapter.discovering = false;
    }
    function setDiscovering(on) {
        on ? startScan() : stopScan();
    }
    // a page that lists devices: scan while it's shown
    function watch(on) {
        scanUsers = Math.max(0, scanUsers + (on ? 1 : -1));
        if (scanUsers > 0)
            startScan();
        else
            stopScan();
    }
    onEnabledChanged: {
        if (enabled && scanUsers > 0)
            startScan();
        if (enabled)
            reconnect.restart();
    }

    // ── known devices back, when Bluetooth comes on (and at startup) ──
    Timer {
        id: reconnect
        interval: 2500
        running: true
        onTriggered: {
            if (!(Settings.data.bluetooth.autoConnect ?? true) || !root.enabled)
                return;
            for (const d of root.mine)
                if (!d.connected && (d.trusted ?? true) && !(d.blocked ?? false))
                    d.connect();
        }
    }

    // ── signal strength (RSSI, dBm) while searching: address → dBm ──
    property var signals: ({})
    function bars(d) {
        const v = signals[d?.address];
        return v === undefined ? -1 : v >= -60 ? 4 : v >= -70 ? 3 : v >= -80 ? 2 : 1;
    }
    Timer {
        interval: 3000
        repeat: true
        triggeredOnStart: true
        running: root.scanning && (Settings.data.bluetooth.signal ?? true)
        onTriggered: if (!signalProc.running) signalProc.running = true
    }
    Process {
        id: signalProc
        command: [Paths.bin, "bluetooth", "signal"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.signals = JSON.parse(text);
                } catch (e) {}
            }
        }
    }
    Process {
        id: scanner
        command: [Paths.bin, "bluetooth", "scan", "60"]
        // 60 s at a time, again while a page still wants it
        onExited: if (root.scanUsers > 0 && root.enabled) again.restart()
    }
    Timer {
        id: again
        interval: 1500
        onTriggered: if (root.scanUsers > 0 && root.enabled && !scanner.running) scanner.running = true
    }

    // ── a device: connect, disconnect, pair, forget ──
    function toggleDevice(d) {
        if (d.connected)
            d.disconnect();
        else if (d.paired || d.bonded)
            d.connect();
        else
            pair(d);
    }
    function forget(d) {
        Quickshell.execDetached([Paths.bin, "bluetooth", "remove", d.address]);
    }

    // pairing: one at a time
    property string pairing: ""              // the address being paired
    property string pairName: ""
    property var prompt: null                // { kind: confirm | pin | passkey | display, passkey }
    property string pairStatus: ""           // the last word on it (an error, or "Connected")
    function pair(d) {
        if (pairer.running)
            return;
        pairing = d.address;
        pairName = d.name || d.address;
        prompt = null;
        pairStatus = "";
        pairer.command = [Paths.bin, "bluetooth", "pair", d.address];
        pairer.running = true;
    }
    function answer(text) {
        if (pairer.running)
            pairer.write(text + "\n");
        if (prompt && prompt.kind !== "display")
            prompt = null;
    }
    function cancelPair() {
        if (pairer.running) {
            pairer.write("no\n");
            pairer.running = false;
        }
        pairing = "";
        prompt = null;
    }
    Process {
        id: pairer
        stdinEnabled: true
        stdout: SplitParser {
            onRead: line => {
                let e = {};
                try {
                    e = JSON.parse(line);
                } catch (x) {
                    return;
                }
                if (e.event === "confirm" || e.event === "pin" || e.event === "passkey" || e.event === "display")
                    root.prompt = { kind: e.event, passkey: e.passkey ?? "" };
                else if (e.event === "paired")
                    root.prompt = null;
                else if (e.event === "done")
                    root.pairStatus = e.connected ? "Connected" : (e.message || "Paired");
                else if (e.event === "error")
                    root.pairStatus = e.message || "Pairing failed";
            }
        }
        onExited: {
            root.pairing = "";
            root.prompt = null;
            clearStatus.restart();
        }
    }
    Timer {
        id: clearStatus
        interval: 8000
        onTriggered: root.pairStatus = ""
    }
}
