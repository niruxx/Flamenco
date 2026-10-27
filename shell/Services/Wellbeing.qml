pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons

// Digital wellbeing: how long each app is in front of you (the focused window),
// counted while you're active (it stops when you've been idle for a while, or the
// screen is locked), per day. Kept only on this computer, in
// ~/.local/state/flamenco/wellbeing.json (the last 120 days). App limits notify
// you once a day when an app's time is up; break reminders after a stretch of use.
Singleton {
    id: root

    readonly property var cfg: Settings.data.wellbeing
    readonly property bool enabled: cfg.enabled ?? true
    property var days: ({})                  // "YYYY-MM-DD" → { appId: seconds }
    property bool loaded: false
    readonly property int step: 15            // seconds per tick
    readonly property string today: key(Time.now)
    readonly property var todayApps: days[today] ?? {}
    readonly property int todayTotal: total(todayApps)
    property int stretch: 0                   // seconds of use without a break
    property var notified: ({})               // today's limits already announced

    function key(d) {
        return d.getFullYear() + "-" + String(d.getMonth() + 1).padStart(2, "0") + "-" + String(d.getDate()).padStart(2, "0");
    }
    function total(apps) {
        let t = 0;
        for (const k in apps)
            t += apps[k];
        return t;
    }
    // "47h 20m", "35m", "40s"
    function fmt(s) {
        s = Math.round(s || 0);
        const h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60);
        return h > 0 ? h + "h " + m + "m" : m > 0 ? m + "m" : s + "s";
    }
    function dayTotal(k) {
        return total(days[k] ?? {});
    }
    // the days of the week that `offset` weeks ago started (Sunday first, like the locale's start)
    function weekKeys(offset) {
        const d = new Date(Time.now);
        const first = Time.firstDay;
        d.setDate(d.getDate() - ((d.getDay() - first + 7) % 7) - 7 * offset);
        const out = [];
        for (let i = 0; i < 7; i++) {
            out.push(key(d));
            d.setDate(d.getDate() + 1);
        }
        return out;
    }
    // apps used over some days, most first: [{ id, seconds }]
    function appsOver(keys) {
        const sum = {};
        for (const k of keys)
            for (const a in (days[k] ?? {}))
                sum[a] = (sum[a] ?? 0) + days[k][a];
        return Object.keys(sum).map(id => ({ id, seconds: sum[id] })).sort((a, b) => b.seconds - a.seconds);
    }
    function lastDays(n) {
        const out = [];
        const d = new Date(Time.now);
        for (let i = 0; i < n; i++) {
            out.push(key(d));
            d.setDate(d.getDate() - 1);
        }
        return out;
    }
    function appName(id) {
        return Apps.lookup(id)?.name ?? id;
    }
    function setLimit(id, minutes) {
        const l = Object.assign({}, cfg.limits || {});
        if (minutes > 0)
            l[id] = minutes;
        else
            delete l[id];
        cfg.limits = l;
    }
    function clear() {
        days = {};
        saveSoon.restart();
    }

    // ── counting ──
    IdleMonitor {
        id: idle
        enabled: root.enabled
        timeout: Math.max(30, root.cfg.idleAfter ?? 120)
        respectInhibitors: false
    }
    Timer {
        running: root.enabled && root.loaded
        interval: root.step * 1000
        repeat: true
        onTriggered: {
            const w = Niri.focusedWindow;
            if (idle.isIdle || !w || !w.app_id) {
                if (idle.isIdle)
                    root.stretch = 0;
                return;
            }
            const k = root.today;
            const d = Object.assign({}, root.days);
            d[k] = Object.assign({}, d[k] ?? {});
            d[k][w.app_id] = (d[k][w.app_id] ?? 0) + root.step;
            root.days = d;
            root.stretch += root.step;
            root.check(w.app_id, d[k][w.app_id]);
            saveSoon.restart();
        }
    }
    onTodayChanged: notified = {}

    function check(id, seconds) {
        const lim = (cfg.limits || {})[id];
        if (lim > 0 && seconds >= lim * 60 && !notified[id]) {
            notified = Object.assign({}, notified, { [id]: true });
            Quickshell.execDetached(["notify-send", "-a", "Digital wellbeing", "-i", "hourglass", "Time's up for " + appName(id),
                "You've used it for " + fmt(seconds) + " today (your limit is " + fmt(lim * 60) + ")"]);
        }
        const every = cfg.breakEvery ?? 0;
        if (every > 0 && stretch >= every * 60) {
            stretch = 0;
            Quickshell.execDetached(["notify-send", "-a", "Digital wellbeing", "-i", "self-care", "Time for a break",
                "You've been at it for " + fmt(every * 60) + ". Look away, stretch, drink some water."]);
        }
    }

    // ── keeping it ──
    FileView {
        id: store
        path: Paths.stateDir + "/wellbeing.json"
        printErrors: false
        onLoaded: {
            try {
                root.days = JSON.parse(text()).days ?? {};
            } catch (e) {
                root.days = {};
            }
            root.loaded = true;
        }
        onLoadFailed: root.loaded = true
    }
    Timer {
        id: saveSoon
        interval: 60000
        onTriggered: {
            // the last 120 days
            const keep = new Set(root.lastDays(120));
            const d = {};
            for (const k in root.days)
                if (keep.has(k))
                    d[k] = root.days[k];
            store.setText(JSON.stringify({ version: 1, days: d }));
        }
    }
    Component.onDestruction: if (saveSoon.running) saveSoon.triggered()
}
