pragma Singleton

import QtQuick
import Quickshell
import qs.Services as FS

// Flamenco shim for Noctalia's AudioService.
Singleton {
    readonly property var sink: FS.Audio.sink
    readonly property var source: FS.Audio.source
    readonly property real volume: FS.Audio.volume
    readonly property bool muted: FS.Audio.muted
    readonly property real inputVolume: FS.Audio.micVolume
    readonly property bool inputMuted: FS.Audio.micMuted
    function setVolume(v) { FS.Audio.setVolume(v); }
    function increaseVolume() { FS.Audio.step(0.05); }
    function decreaseVolume() { FS.Audio.step(-0.05); }
    function setOutputMuted(m) { if (m !== muted) FS.Audio.toggleMute(); }
    function setInputMuted(m) { if (m !== inputMuted) FS.Audio.toggleMicMute(); }
}
