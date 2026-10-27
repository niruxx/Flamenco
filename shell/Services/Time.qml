pragma Singleton

import QtQuick
import Quickshell
import qs.Commons

Singleton {
    readonly property date now: clock.date
    readonly property bool use24h: Settings.data.general.use24h
    readonly property string time: I18n.locale.toString(clock.date, (use24h ? "HH:mm" : "h:mm") + (Settings.data.general.showSeconds ? ":ss" : "") + (use24h ? "" : " AP"))
    readonly property string hours: I18n.locale.toString(clock.date, use24h ? "HH" : "h")
    readonly property string minutes: I18n.locale.toString(clock.date, "mm")
    // Settings → Region & Language: how dates are written, and the first day of the week
    readonly property string dateStyle: Settings.data.general.dateStyle || "dmy"
    // day and month names in Flamenco's language (Settings → Region & Language)
    readonly property string date: I18n.locale.toString(clock.date, dateStyle === "mdy" ? "dddd, MMMM d" : dateStyle === "iso" ? "dddd, yyyy-MM-dd" : "dddd, d MMMM")
    readonly property string shortDate: I18n.locale.toString(clock.date, dateStyle === "mdy" ? "ddd MMM d" : dateStyle === "iso" ? "yyyy-MM-dd" : "ddd d MMM")
    // 0 = Sunday … 6 = Saturday; -1 in settings: as the language has it
    readonly property int firstDay: (Settings.data.general.firstDay ?? -1) >= 0 ? Settings.data.general.firstDay : I18n.locale.firstDayOfWeek % 7
    // the week's day names from the first day ("short": Mon, "narrow": M, else Mo)
    function weekdays(style) {
        const out = [];
        for (let i = 0; i < 7; i++) {
            const d = (firstDay + i) % 7;
            const n = I18n.locale.dayName(d, style === "narrow" ? Locale.NarrowFormat : Locale.ShortFormat);
            out.push(style === "short" || style === "narrow" ? n : n.slice(0, 2));
        }
        return out;
    }
    // how many days of the month's first week belong to the month before
    function lead(monthStart) {
        return (monthStart.getDay() - firstDay + 7) % 7;
    }

    function format(fmt) {
        return I18n.locale.toString(clock.date, fmt);
    }

    // ticks once a minute (everything bound to the time wakes up 60× less);
    // every second only while the bar shows seconds
    SystemClock {
        id: clock
        precision: Settings.data.general.showSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }
}
