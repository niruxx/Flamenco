pragma Singleton

import QtQuick
import Quickshell
import qs.Services as FS

// Flamenco shim for DMS's PopoutService: DMS's own popouts map to Flamenco's.
Singleton {
    property var colorPickerModal: null
    property var processListPopoutLoader: null
    property var controlCenterPopout: null

    function openSettingsWithTab(tab) {
        FS.Panels.openSettings("thirdparty");
    }
    function closeControlCenter() {
        if (FS.Panels.current === "control")
            FS.Panels.close();
    }
    function openControlCenter() {
        FS.Panels.open("control", "");
    }
    function toggleControlCenter() {
        FS.Panels.toggle("control", "");
    }
    function openNotificationCenter() {
        FS.Panels.open("notifications", "");
    }
    function openDankLauncherV2WithQuery(query) {
        FS.Panels.launcherQuery = query || "";
        FS.Panels.open("launcher", "");
    }
    function toggleAppDrawer() {
        FS.Panels.toggle("launcher", "");
    }
    function openPowerMenu() {
        FS.Panels.open("power", "");
    }
}
