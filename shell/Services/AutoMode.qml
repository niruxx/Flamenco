pragma Singleton

import QtQuick
import Quickshell
import qs.Commons

// Switches between dark and light by itself (Settings → Appearance → Mode):
// at sunset and sunrise (from the weather service's location), or at set times.
// It only acts when a switch time passes, so flipping the mode by hand sticks
// until the next one.
Singleton {
    id: root

    readonly property var a: Settings.data.appearance
    readonly property bool on: a.autoMode === "sun" || a.autoMode === "schedule"
    // sun times are only known with weather on (it has the location)
    readonly property bool sunKnown: Weather.sunrise !== "" && Weather.sunset !== ""
    readonly property bool usingSun: a.autoMode === "sun" && sunKnown

    // minutes after midnight
    function minutes(hhmm) {
        const m = String(hhmm).match(/(\d{1,2}):(\d{2})/);
        return m ? (Number(m[1]) % 24) * 60 + Math.min(59, Number(m[2])) : -1;
    }
    readonly property int lightMin: usingSun ? minutes(Weather.sunrise.split("T")[1] ?? "") : minutes(a.lightAt)
    readonly property int darkMin: usingSun ? minutes(Weather.sunset.split("T")[1] ?? "") : minutes(a.darkAt)
    readonly property bool valid: lightMin >= 0 && darkMin >= 0 && lightMin !== darkMin

    property int now: 0                     // minutes after midnight, updated each minute
    // light between lightMin and darkMin (wrapping past midnight if needed)
    readonly property string wanted: !on || !valid ? "" : (lightMin < darkMin ? (now >= lightMin && now < darkMin) : (now >= lightMin || now < darkMin)) ? "light" : "dark"
    readonly property string nextSwitch: !on || !valid ? "" : (wanted === "light" ? "Dark at " + fmt(darkMin) : "Light at " + fmt(lightMin))

    function fmt(m) {
        const two = n => (n < 10 ? "0" : "") + n;
        return two(Math.floor(m / 60)) + ":" + two(m % 60);
    }
    function tick() {
        const d = new Date();
        now = d.getHours() * 60 + d.getMinutes();
    }

    property string lastWanted: ""
    // a switch time passed (or it was just turned on): apply; otherwise leave manual changes alone
    function sync() {
        if (wanted === "") {
            lastWanted = "";
            return;
        }
        if (!Settings.ready || wanted === lastWanted)
            return;
        a.mode = wanted;
        lastWanted = wanted;
    }
    onWantedChanged: sync()
    Connections {
        target: Settings
        function onReadyChanged() { root.sync(); }
    }

    Component.onCompleted: tick()
    Timer {
        running: root.on
        interval: 30000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.tick()
    }
}
