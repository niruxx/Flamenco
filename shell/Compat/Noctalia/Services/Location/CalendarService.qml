pragma Singleton

import QtQuick
import Quickshell

// Flamenco shim for Noctalia's CalendarService (Flamenco's calendars are in its own panel).
Singleton {
    readonly property bool available: false
    property var events: []
    function loadEvents() {}
}
