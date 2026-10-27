pragma Singleton

import QtQuick
import Quickshell
import qs.Commons

// Your own commands when something happens (Settings → Auto-start → Hooks): the
// wallpaper or dark mode changes, the screen locks or unlocks, the shell starts,
// colors come from a new wallpaper. Each runs with sh, with what changed in its
// environment: FLAMENCO_EVENT, FLAMENCO_WALLPAPER, FLAMENCO_MODE (dark | light),
// FLAMENCO_PALETTE and FLAMENCO_ACCENT.
Singleton {
    id: root

    readonly property var cfg: Settings.data.hooks
    // not for what's set while the shell starts up
    property bool armed: false
    Timer {
        running: Settings.ready
        interval: 3000
        onTriggered: {
            root.armed = true;
            root.run("startup");
        }
    }

    function run(event) {
        const cmd = String(cfg[event] || "").trim();
        if (!cmd || !armed)
            return;
        Quickshell.execDetached(["env",
            "FLAMENCO_EVENT=" + event,
            "FLAMENCO_WALLPAPER=" + Wallpapers.current,
            "FLAMENCO_MODE=" + (Theme.dark ? "dark" : "light"),
            "FLAMENCO_PALETTE=" + Settings.data.appearance.palette,
            "FLAMENCO_ACCENT=" + String(Theme.accent).slice(0, 7),
            "sh", "-c", cmd]);
    }

    Connections {
        target: Wallpapers
        function onCurrentChanged() {
            root.run("wallpaper");
        }
    }
    Connections {
        target: Theme
        function onDarkChanged() {
            root.run("darkMode");
        }
    }
    Connections {
        target: ColorGen
        function onDarkChanged() {
            root.run("colors");
        }
    }
}
