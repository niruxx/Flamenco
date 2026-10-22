pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// The system's date and time settings (`flamenco datetime`, i.e. timedatectl and
// systemd-timesyncd), for Settings → Date & Time. Changing them needs root: they
// run in a terminal (sudo), except the time zone once "Automatic time zone" has
// set up its polkit rule. Automatic time zone follows where you are.
Singleton {
    id: root

    property var st: ({})
    property var zones: []
    property string detected: ""
    readonly property bool busy: terminal.running
    readonly property var cfg: Settings.data.datetime

    function refresh() {
        if (!status.running)
            status.running = true;
    }
    function loadZones() {
        if (zones.length === 0 && !zoneList.running)
            zoneList.running = true;
    }
    Component.onCompleted: {
        refresh();
        if (cfg.autoTimezone)
            detectSoon.restart();
    }

    function inTerminal(args) {
        terminal.command = Paths.term(["env", "FLAMENCO_PAUSE=1", Paths.bin, "datetime"].concat(args));
        terminal.running = true;
    }
    function setTimezone(z) {
        // straight away when the polkit rule allows it, else in a terminal
        if (st.autoRule) {
            direct.command = [Paths.bin, "datetime", "timezone", z];
            direct.running = true;
        } else {
            inTerminal(["timezone", z]);
        }
    }
    function setNtp(on) {
        inTerminal(["ntp", on ? "on" : "off"]);
    }
    function setServers(hosts) {
        inTerminal(hosts.trim() ? ["server", hosts.trim()] : ["server", "--default"]);
    }
    function setTime(when) {
        inTerminal(["set", when]);
    }
    function setAuto(on) {
        cfg.autoTimezone = on;
        // the rule lets the time zone follow you without a password each time
        if (on && !st.autoRule)
            inTerminal(["auto-rule", "on"]);
        if (on)
            detectSoon.restart();
    }

    Process {
        id: terminal
        onExited: root.refresh()
    }
    Process {
        id: direct
        onExited: root.refresh()
    }
    Process {
        id: status
        command: [Paths.bin, "datetime", "status", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.st = JSON.parse(text);
                } catch (e) {}
            }
        }
    }
    Process {
        id: zoneList
        command: [Paths.bin, "datetime", "timezones"]
        stdout: StdioCollector {
            onStreamFinished: root.zones = text.split("\n").filter(z => z)
        }
    }

    // ── automatic time zone ──
    Timer {
        id: detectSoon
        interval: 8000
        onTriggered: if (root.cfg.autoTimezone && !detector.running) detector.running = true
    }
    Timer {
        running: root.cfg.autoTimezone
        interval: 3 * 3600 * 1000
        repeat: true
        onTriggered: detectSoon.restart()
    }
    Process {
        id: detector
        command: [Paths.bin, "datetime", "detect"]
        stdout: StdioCollector {
            onStreamFinished: {
                const z = text.trim();
                root.detected = z;
                // moved to another time zone: follow it (silently, with the polkit rule)
                if (z && z !== root.st.timezone && root.st.autoRule && root.cfg.autoTimezone)
                    root.setTimezone(z);
            }
        }
    }
}
