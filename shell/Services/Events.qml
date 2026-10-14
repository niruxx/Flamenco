pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Calendar events from Settings → Clock & Weather → Calendars
// (`flamenco calendar events`): ICS links, .ics files, vdir folders.
Singleton {
    id: root

    readonly property var sources: Settings.data.calendar.sources || []
    property var events: []                 // [{ title, start, end, allDay, location, calendar, color }]
    property var errors: ({})
    readonly property bool loading: proc.running

    function refresh(force) {
        if (sources.length === 0) {
            events = [];
            return;
        }
        if (proc.running)
            return;
        proc.command = [Paths.bin, "calendar", "events"].concat(force ? ["--refresh"] : []);
        proc.running = true;
    }

    function key(d) {
        return d.getFullYear() + "-" + String(d.getMonth() + 1).padStart(2, "0") + "-" + String(d.getDate()).padStart(2, "0");
    }
    // events on a day (all-day ones spanning it included)
    function on(d) {
        const k = key(d);
        return events.filter(e => {
            const s = e.start.slice(0, 10), en = e.end.slice(0, 10);
            return e.allDay ? (s <= k && k < en) || s === k : s === k;
        });
    }
    // days that have something, for the dots in the month grid
    readonly property var busyDays: {
        const set = {};
        for (const e of events) {
            set[e.start.slice(0, 10)] = true;
            if (e.allDay) {
                const d = new Date(e.start);
                const end = new Date(e.end);
                for (let i = 0; i < 60 && d < end; i++, d.setDate(d.getDate() + 1))
                    set[key(d)] = true;
            }
        }
        return set;
    }

    function timeOf(e) {
        if (e.allDay)
            return "All day";
        const s = new Date(e.start), en = new Date(e.end);
        const f = d => Qt.formatTime(d, Settings.data.general.use24h ? "HH:mm" : "h:mm AP");
        return f(s) + (e.end !== e.start ? " – " + f(en) : "");
    }

    Component.onCompleted: refresh(false)
    onSourcesChanged: refreshSoon.restart()

    Timer {
        id: refreshSoon
        interval: 800
        onTriggered: root.refresh(true)
    }
    Timer {
        running: root.sources.length > 0
        interval: 15 * 60 * 1000
        repeat: true
        onTriggered: root.refresh(false)
    }

    Process {
        id: proc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    root.events = d.events ?? [];
                    root.errors = d.errors ?? {};
                } catch (e) {}
            }
        }
    }
}
