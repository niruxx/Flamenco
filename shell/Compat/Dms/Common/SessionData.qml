pragma Singleton

import QtQuick
import Quickshell
import qs.Commons as F
import qs.Services as FS

// Flamenco shim for DMS's SessionData.
Singleton {
    readonly property bool isLightMode: !F.Theme.dark
    readonly property bool doNotDisturb: FS.Notifs.dnd
    readonly property string wallpaperPath: FS.Wallpapers.current
    readonly property string locale: ""
    readonly property var perMonitorWallpapers: ({})

    function setDoNotDisturb(on) {
        FS.Notifs.setDnd(on);
    }
    function setLightMode(light) {
        F.Settings.data.appearance.mode = light ? "light" : "dark";
    }
    function setWallpaper(path) {
        FS.Wallpapers.set(path, "");
    }
    function suppressOSDTemporarily() {}
}
