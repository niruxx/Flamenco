pragma Singleton

import QtQuick
import Quickshell
import qs.Commons

// Low and critical battery warnings (Settings → Power → Battery warnings): a
// notification once at each level while discharging, and, if chosen, suspend,
// hibernate or shut down a few percent below the critical level, after a minute's
// warning that plugging in cancels. Plugging in (or charging back up) re-arms them.
Singleton {
    id: root

    readonly property var cfg: Settings.data.power
    readonly property bool on: (cfg.batteryWarnings ?? true) && Power.hasBattery && Settings.ready
    readonly property int pct: Power.percent
    readonly property bool draining: Power.onBattery
    readonly property int low: Math.max(5, cfg.batteryWarnLow ?? 20)
    readonly property int critical: Math.max(3, Math.min(low - 1, cfg.batteryWarnCritical ?? 10))
    readonly property string action: cfg.batteryEmptyAction || "none"
    readonly property int actAt: Math.max(2, critical - 5)

    property bool saidLow: false
    property bool saidCritical: false
    property bool acting: false

    function notify(urgency, title, body, icon) {
        Quickshell.execDetached(["notify-send", "-a", "Battery", "-u", urgency, "-i", icon, "-h", "string:x-flamenco-kind:battery", title, body]);
    }
    function check() {
        if (!on)
            return;
        // plugged in, or charged back up a little: next time it warns again
        if (!draining) {
            saidLow = saidCritical = false;
            if (acting) {
                acting = false;
                countdown.stop();
                notify("normal", "Plugged in", "Nothing will happen: the battery is charging", "battery-good-charging");
            }
            return;
        }
        if (pct > low + 3)
            saidLow = false;
        if (pct > critical + 2)
            saidCritical = false;
        const left = Power.timeLeft ? " · about " + Power.timeLeft + " left" : "";
        if (pct <= critical && !saidCritical) {
            saidCritical = saidLow = true;
            const then = action === "none" ? "Plug in soon." : "Plug in now: at " + actAt + "% it will " + ({ suspend: "suspend", hibernate: "hibernate", poweroff: "shut down" })[action] + ".";
            notify("critical", "Battery critically low", pct + "%" + left + ". " + then, "battery-empty");
        } else if (pct <= low && !saidLow) {
            saidLow = true;
            notify("normal", "Battery low", pct + "%" + left + ". Plug in, or turn on Power saver.", "battery-caution");
        }
        if (action !== "none" && pct <= actAt && !acting) {
            acting = true;
            countdown.restart();
            notify("critical", "Battery nearly empty", "The computer will " + ({ suspend: "suspend", hibernate: "hibernate", poweroff: "shut down" })[action] + " in a minute unless you plug in", "battery-empty");
        }
    }
    onPctChanged: check()
    onDrainingChanged: check()
    onOnChanged: check()

    Timer {
        id: countdown
        interval: 60000
        onTriggered: {
            if (!root.acting || !root.draining)
                return;
            root.acting = false;
            if (root.action === "suspend")
                Power.suspend();
            else if (root.action === "hibernate")
                Power.hibernate();
            else if (root.action === "poweroff")
                Power.shutdown();
        }
    }

    // for Settings → Power: shows what the warnings look like
    function test() {
        notify("normal", "Battery low", "This is how the low battery warning looks", "battery-caution");
    }
}
