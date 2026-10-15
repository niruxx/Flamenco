pragma Singleton

import QtQuick
import Quickshell

// Flamenco shim for DMS's BlurService (Flamenco draws its own surfaces).
Singleton {
    readonly property bool enabled: false
    readonly property bool available: false
    function registerWidget(item) {}
    function unregisterWidget(item) {}
}
