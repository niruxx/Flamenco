pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.Services as FS

// Flamenco shim for DMS's AudioService.
Singleton {
    readonly property var sink: FS.Audio.sink
    readonly property var source: FS.Audio.source
    readonly property bool soundsAvailable: false

    function displayName(node) {
        return node ? FS.Audio.nodeName(node) : "";
    }
    function getMaxVolumePercent() {
        return 100;
    }
    function setDefaultSinkByName(name) {
        const n = FS.Audio.sinks.find(x => x.name === name);
        if (n)
            Pipewire.preferredDefaultAudioSink = n;
    }
    function getSoundPath(name) {
        return "";
    }
    function playVolumeChangeSound() {}
}
