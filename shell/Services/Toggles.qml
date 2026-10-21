pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Small stateful toggles: caffeine and night light.
//
// Night light (Settings → Night light, and the quick settings tile's page) runs
// gammastep. By hand it's one fixed warmth (-O). On a schedule (sunset → sunrise,
// or set times) gammastep gets a config of its own with dawn / dusk times and
// fades between neutral and the warmth itself, smoothly, over the fade minutes.
// Toggling the tile during a schedule holds that until the next scheduled change.
Singleton {
    id: root

    property bool caffeine: false

    // ── night light ──
    readonly property var n: Settings.data.night
    readonly property string schedule: ["sun", "custom"].includes(n.schedule) ? n.schedule : "off"
    property int now: 0                      // minutes after midnight
    function minutes(hhmm) {
        const m = String(hhmm ?? "").match(/(\d{1,2}):(\d{2})/);
        return m ? (Number(m[1]) % 24) * 60 + Math.min(59, Number(m[2])) : -1;
    }
    function fmt(m) {
        const two = v => (v < 10 ? "0" : "") + v;
        m = ((m % 1440) + 1440) % 1440;
        return two(Math.floor(m / 60)) + ":" + two(m % 60);
    }
    readonly property bool sunKnown: Weather.sunrise !== "" && Weather.sunset !== ""
    readonly property int onMin: schedule === "sun" ? (sunKnown ? minutes(Weather.sunset.split("T")[1]) : -1) : minutes(n.from)
    readonly property int offMin: schedule === "sun" ? (sunKnown ? minutes(Weather.sunrise.split("T")[1]) : -1) : minutes(n.to)
    readonly property bool scheduled: schedule !== "off" && onMin >= 0 && offMin >= 0 && onMin !== offMin
    readonly property bool inWindow: scheduled && (onMin < offMin ? now >= onMin && now < offMin : now >= onMin || now < offMin)
    // the tile toggled against the schedule: null = following it
    property var override: null
    onInWindowChanged: override = null

    readonly property bool nightLight: scheduled ? (override !== null ? override : inWindow) : n.enabled
    readonly property int temperature: Math.max(1500, Math.min(6500, n.temperature || 4000))
    readonly property real dim: Math.max(0.5, Math.min(1, n.brightness ?? 1))
    // for the tile and page: what happens next
    readonly property string status: {
        if (schedule === "sun" && !sunKnown)
            return nightLight ? temperature + "K" : "Waiting for sunset times";
        if (!scheduled)
            return nightLight ? temperature + "K" : "Off";
        if (override !== null)
            return (override ? "On" : "Off") + " until " + fmt(inWindow ? offMin : onMin);
        return inWindow ? "On until " + fmt(offMin) : "From " + fmt(onMin);
    }

    function setNightLight(on) {
        if (scheduled)
            override = on === inWindow ? null : on;
        else
            n.enabled = on;
    }

    function tick() {
        const d = new Date();
        now = d.getHours() * 60 + d.getMinutes();
    }
    Component.onCompleted: {
        tick();
        restartSoon.restart();
    }
    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.tick()
    }

    // ── gammastep ──
    readonly property string confPath: Paths.configDir + "/gammastep.ini"
    // following a schedule: gammastep's own dawn / dusk fades; else one fixed warmth
    readonly property bool followSchedule: scheduled && override === null
    readonly property string conf: {
        const f = Math.max(0, Math.min(120, n.fade ?? 30));
        return ["; Written by Flamenco (Settings → Night light); changes here are replaced.",
            "[general]",
            "adjustment-method=wayland",
            "temp-day=6500",
            "temp-night=" + temperature,
            "brightness-day=1.0",
            "brightness-night=" + dim.toFixed(2),
            "fade=1",
            // warming up from the on time, cooling down before the off time
            "dusk-time=" + fmt(onMin) + "-" + fmt(onMin + Math.max(1, f)),
            "dawn-time=" + fmt(offMin - Math.max(1, f)) + "-" + fmt(offMin),
            ""].join("\n");
    }
    readonly property var gammaCmd: followSchedule ? ["gammastep", "-P", "-c", confPath]
        : nightLight ? ["gammastep", "-P", "-O", String(temperature), "-b", dim.toFixed(2)] : []

    FileView {
        id: confFile
        path: root.confPath
        atomicWrites: true
        blockLoading: true
        printErrors: false
    }

    // restarted (after a moment, so dragging a slider doesn't restart it on every step)
    // whenever what it should do changes
    onGammaCmdChanged: restartSoon.restart()
    onConfChanged: if (followSchedule) restartSoon.restart()
    Timer {
        id: restartSoon
        interval: 350
        onTriggered: {
            if (root.followSchedule)
                confFile.setText(root.conf);
            gamma.running = false;
            if (root.gammaCmd.length) {
                gamma.command = root.gammaCmd;
                Qt.callLater(() => gamma.running = true);
            }
        }
    }
    Process {
        id: gamma
    }
}
