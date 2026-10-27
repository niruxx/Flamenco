pragma Singleton

import QtQuick
import Quickshell
import qs.Commons

Singleton {
    readonly property date now: clock.date
    readonly property bool use24h: Settings.data.general.use24h
    readonly property string time: Qt.formatDateTime(clock.date, (use24h ? "HH:mm" : "h:mm") + (Settings.data.general.showSeconds ? ":ss" : "") + (use24h ? "" : " AP"))
    readonly property string hours: Qt.formatDateTime(clock.date, use24h ? "HH" : "h")
    readonly property string minutes: Qt.formatDateTime(clock.date, "mm")
    // Settings → Region & Language: how dates are written, and the first day of the week
    readonly property string dateStyle: Settings.data.general.dateStyle || "dmy"
    readonly property string date: Qt.formatDateTime(clock.date, dateStyle === "mdy" ? "dddd, MMMM d" : dateStyle === "iso" ? "dddd, yyyy-MM-dd" : "dddd, d MMMM")
    readonly property string shortDate: Qt.formatDateTime(clock.date, dateStyle === "mdy" ? "ddd MMM d" : dateStyle === "iso" ? "yyyy-MM-dd" : "ddd d MMM")
    // 0 = Sunday … 6 = Saturday; -1 in settings: as the language has it
    readonly property int firstDay: (Settings.data.general.firstDay ?? -1) >= 0 ? Settings.data.general.firstDay : Qt.locale().firstDayOfWeek % 7
    // the week's day names from the first day ("short": Mon, "narrow": M, else Mo)
    function weekdays(style) {
        const out = [];
        for (let i = 0; i < 7; i++) {
            const d = (firstDay + i) % 7;
            const n = Qt.locale().dayName(d, style === "narrow" ? Locale.NarrowFormat : Locale.ShortFormat);
            out.push(style === "short" || style === "narrow" ? n : n.slice(0, 2));
        }
        return out;
    }
    // how many days of the month's first week belong to the month before
    function lead(monthStart) {
        return (monthStart.getDay() - firstDay + 7) % 7;
    }

    function format(fmt) {
        return Qt.formatDateTime(clock.date, fmt);
    }

    // ticks once a minute (everything bound to the time wakes up 60× less);
    // every second only while the bar shows seconds
    SystemClock {
        id: clock
        precision: Settings.data.general.showSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }
}
