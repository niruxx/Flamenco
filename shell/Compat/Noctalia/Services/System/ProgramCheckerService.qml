pragma Singleton

import QtQuick
import Quickshell

// Flamenco shim for Noctalia's ProgramCheckerService.
Singleton {
    property bool gnomeCalendarAvailable: false
    property bool wlsunsetAvailable: false
    property bool cavaAvailable: true
}
