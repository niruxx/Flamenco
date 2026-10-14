pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Screen and keyboard backlight via brightnessctl.
Singleton {
    id: root

    property bool available: false
    property real value: 0
    property real pending: -1

    signal changedByUser

    // keyboard backlight (an LED class device named *kbd_backlight*). Many have
    // only a few levels (off / low / high), so it steps one level at a time then.
    property string kbdDevice: ""
    property int kbdMax: 0
    property int kbdLevel: 0
    readonly property bool kbdAvailable: kbdDevice !== "" && kbdMax > 0
    readonly property real kbdValue: kbdMax > 0 ? kbdLevel / kbdMax : 0
    property int kbdLastOn: 0       // level to restore on toggle

    signal kbdChangedByUser

    function setKbdLevel(level) {
        if (!kbdAvailable)
            return;
        level = Math.max(0, Math.min(kbdMax, Math.round(level)));
        const changed = level !== kbdLevel;
        kbdLevel = level;
        if (level > 0)
            kbdLastOn = level;
        if (changed)
            Quickshell.execDetached(["brightnessctl", "-q", "-d", kbdDevice, "set", String(level)]);
        // the OSD and click also answer a key press at the end of the range
        kbdChangedByUser();
        Sounds.brightnessChanged();
    }

    function setKbd(v) {
        setKbdLevel(v * kbdMax);
    }

    function stepKbd(dir) {
        const d = kbdMax <= 10 ? 1 : Math.max(1, Math.round(kbdMax * 0.1));
        setKbdLevel(kbdLevel + (dir < 0 ? -d : d));
    }

    function toggleKbd() {
        setKbdLevel(kbdLevel > 0 ? 0 : (kbdLastOn || kbdMax));
    }

    function set(v) {
        v = Math.max(0.01, Math.min(1, v));
        value = v;
        pending = v;
        writeTimer.restart();
        changedByUser();
        Sounds.brightnessChanged();
    }

    function step(delta) {
        // no built-in screen (a desktop): the brightness keys change the focused monitor
        if (!available && ddc.length) {
            const d = ddc.find(x => x.connector === Niri.focusedOutput) ?? ddc[0];
            setDdc(d.bus, d.value / d.max + delta);
            changedByUser();
            return;
        }
        set(value + delta);
    }

    // ── external monitors over DDC/CI (ddcutil) ──
    property var ddc: []                 // [{ bus, connector, name, value, max }]
    property bool ddcInstalled: false
    property string ddcError: ""
    property bool ddcLoading: ddcLister.running
    property var ddcPending: ({})        // bus → value waiting to be written

    function refreshDdc() {
        if (!ddcLister.running)
            ddcLister.running = true;
    }

    // v: 0–1. Shown at once; written a moment later (DDC is slow), one monitor at a time
    function setDdc(bus, v) {
        v = Math.max(0, Math.min(1, v));
        ddc = ddc.map(d => d.bus === bus ? Object.assign({}, d, { value: Math.round(v * d.max) }) : d);
        const p = Object.assign({}, ddcPending);
        p[bus] = v;
        ddcPending = p;
        ddcTimer.restart();
    }

    Timer {
        id: ddcTimer
        interval: 300
        onTriggered: {
            if (ddcWriter.running) {
                restart();
                return;
            }
            const buses = Object.keys(root.ddcPending);
            if (!buses.length)
                return;
            const bus = buses[0];
            const d = root.ddc.find(x => x.bus === bus);
            const p = Object.assign({}, root.ddcPending);
            delete p[bus];
            root.ddcPending = p;
            if (!d)
                return;
            ddcWriter.command = [Paths.bin, "ddc", "set", bus, String(Math.round(d.value / d.max * 100)), String(d.max)];
            ddcWriter.running = true;
            if (Object.keys(p).length)
                restart();
        }
    }
    Process { id: ddcWriter }
    Process {
        id: ddcLister
        command: [Paths.bin, "ddc", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    root.ddcInstalled = d.installed;
                    root.ddc = d.displays ?? [];
                    root.ddcError = d.error ?? "";
                } catch (e) {}
            }
        }
    }
    // monitors come and go
    Connections {
        target: Quickshell
        function onScreensChanged() { ddcRescan.restart(); }
    }
    Timer {
        id: ddcRescan
        interval: 3000
        onTriggered: root.refreshDdc()
    }

    function refresh() {
        if (!reader.running)
            reader.running = true;
        if (!kbdReader.running)
            kbdReader.running = true;
        refreshDdc();
    }

    Process {
        id: reader
        command: ["brightnessctl", "-m", "-c", "backlight", "info"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                // name,class,current,percent,max
                const parts = text.trim().split(",");
                if (parts.length >= 5) {
                    root.available = true;
                    if (root.pending < 0)
                        root.value = parseInt(parts[2]) / parseInt(parts[4]);
                }
            }
        }
    }

    Process {
        id: kbdReader
        command: ["brightnessctl", "-m", "-l", "-c", "leds"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                // one device per line: name,class,current,percent,max
                for (const line of text.split("\n")) {
                    const parts = line.trim().split(",");
                    if (parts.length < 5 || !parts[0].includes("kbd_backlight"))
                        continue;
                    root.kbdDevice = parts[0];
                    root.kbdMax = parseInt(parts[4]) || 0;
                    root.kbdLevel = parseInt(parts[2]) || 0;
                    if (root.kbdLevel > 0)
                        root.kbdLastOn = root.kbdLevel;
                    return;
                }
            }
        }
    }

    Timer {
        id: writeTimer
        interval: 40
        onTriggered: {
            Quickshell.execDetached(["brightnessctl", "-c", "backlight", "set", Math.round(root.pending * 100) + "%"]);
            root.pending = -1;
        }
    }

    Timer {
        interval: 5000
        running: root.available || root.kbdAvailable
        repeat: true
        onTriggered: root.refresh()
    }
}
