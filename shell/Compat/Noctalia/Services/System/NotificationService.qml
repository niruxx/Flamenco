pragma Singleton

import QtQuick
import Quickshell
import qs.Services as FS

// Flamenco shim for Noctalia's NotificationService (history comes from Flamenco's).
Singleton {
    readonly property var historyModel: FS.Notifs.history
    readonly property bool doNotDisturb: FS.Notifs.dnd
    function clearHistory() {
        FS.Notifs.clearAll();
    }
}
