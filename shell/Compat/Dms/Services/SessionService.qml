pragma Singleton

import QtQuick
import Quickshell
import qs.Services as FS

// Flamenco shim for DMS's SessionService.
Singleton {
    readonly property bool wtypeAvailable: true
    readonly property bool idleInhibited: FS.Toggles.caffeine
    function lock() {
        Quickshell.execDetached(["flamenco", "lock"]);
    }
    function logout() {
        FS.Power.logout();
    }
    function suspend() {
        FS.Power.suspend();
    }
    function reboot() {
        FS.Power.reboot();
    }
    function poweroff() {
        FS.Power.shutdown();
    }
}
