pragma Singleton

import QtQuick
import Quickshell

// Flamenco shim for Noctalia's FontService.
Singleton {
    readonly property var availableFonts: Qt.fontFamilies()
    readonly property var monospaceFonts: Qt.fontFamilies()
    readonly property bool fontsLoaded: true
}
