pragma Singleton

import QtQuick
import Quickshell
import qs.Services as FS

// Flamenco shim for DMS's MprisController.
Singleton {
    readonly property var activePlayer: FS.Media.player
    readonly property var availablePlayers: FS.Media.players
    function previousOrRewind() {
        FS.Media.previous();
    }
}
