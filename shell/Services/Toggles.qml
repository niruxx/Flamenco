pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Small stateful toggles: caffeine and night light.
Singleton {
    id: root

    property bool caffeine: false
    readonly property bool nightLight: Settings.data.night.enabled

    function setNightLight(on) {
        Settings.data.night.enabled = on;
    }

    Process {
        running: root.nightLight
        command: ["gammastep", "-O", String(Settings.data.night.temperature)]
    }
}
