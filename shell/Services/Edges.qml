pragma Singleton

import QtQuick
import Quickshell
import qs.Commons

// Hot corner actions (Settings → Screen edges).
Singleton {
    id: root

    readonly property var actions: [
        { value: "none", label: "Nothing" },
        { value: "overview", label: "Overview", niriOnly: true },
        { value: "launcher", label: "App launcher" },
        { value: "control", label: "Control center" },
        { value: "notifications", label: "Notifications" },
        { value: "calendar", label: "Calendar & dashboard" },
        { value: "power", label: "Power menu" },
        { value: "wallpaper", label: "Wallpapers" },
        { value: "settings", label: "Settings" },
        { value: "screenshot", label: "Screenshot" },
        { value: "workspace-up", label: "Previous workspace" },
        { value: "workspace-down", label: "Next workspace" },
        { value: "lock", label: "Lock the screen" }
    ]

    function run(action, screen) {
        switch (action) {
        case "overview":
            Niri.action("toggle-overview");
            break;
        case "launcher":
        case "control":
        case "notifications":
        case "power":
            Panels.toggle(action, screen);
            break;
        case "calendar":
            Panels.openDashboard("", screen);
            break;
        case "wallpaper":
            Panels.toggle("wallpaper", screen);
            break;
        case "settings":
            Panels.settingsOpen = !Panels.settingsOpen;
            break;
        case "screenshot":
            Quickshell.execDetached([Paths.bin, "screenshot", "region"]);
            break;
        case "workspace-up":
            Niri.action("focus-workspace-up");
            break;
        case "workspace-down":
            Niri.action("focus-workspace-down");
            break;
        case "lock":
            Quickshell.execDetached(["loginctl", "lock-session"]);
            break;
        }
    }
}
