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
    readonly property string date: Qt.formatDateTime(clock.date, "dddd, d MMMM")
    readonly property string shortDate: Qt.formatDateTime(clock.date, "ddd d MMM")

    function format(fmt) {
        return Qt.formatDateTime(clock.date, fmt);
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }
}
