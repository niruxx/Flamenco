pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

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
        set(value + delta);
    }

    function refresh() {
        if (!reader.running)
            reader.running = true;
        if (!kbdReader.running)
            kbdReader.running = true;
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
