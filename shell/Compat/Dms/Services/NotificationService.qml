pragma Singleton

import QtQuick
import Quickshell
import qs.Services as FS

// Flamenco shim for DMS's NotificationService.
Singleton {
    readonly property var notifications: []
    readonly property var visibleNotifications: []
    readonly property var historyList: []
    function dismissNotification(n) {}
    function dismissAllPopups() {}
    function removeFromHistory(id) {}
    function clearAllNotifications() {
        FS.Notifs.clearAll();
    }
}
