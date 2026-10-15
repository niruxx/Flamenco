pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Hot corner actions (Settings → Screen edges).
// On niri, a corner set to Overview is niri's own hot corner (written into its
// config by `flamenco compositor apply`): it reacts even while you drag a window.
// Every other corner is a small shell window, and niri's corner there is off.
Singleton {
    id: root

    readonly property var cfg: Settings.data.edges
    readonly property var names: ({ topLeft: "top-left", topRight: "top-right", bottomLeft: "bottom-left", bottomRight: "bottom-right" })
    // niri 25.11 can turn on any corner; older versions only the top-left one
    property bool perCorner: false

    // the corners niri itself should open the overview from
    function overviewCorners() {
        if (Niri.hyprland)
            return [];
        if (!cfg.niriImported)
            return Settings.data.windows.hotCorners ? ["top-left"] : [];
        if (!cfg.enabled)
            return [];
        return Object.keys(names).filter(k => cfg[k] === "overview").map(k => names[k]);
    }

    // niri handles this corner, so the shell's corner window stays out of its way
    function nativeCorner(key) {
        return !Niri.hyprland && cfg.niriImported && cfg.enabled && cfg[key] === "overview" && (perCorner || key === "topLeft");
    }

    Process {
        running: !Niri.hyprland
        command: ["niri", "--version"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/(\d+)\.(\d+)/);
                root.perCorner = !!m && (Number(m[1]) > 25 || (Number(m[1]) === 25 && Number(m[2]) >= 11));
            }
        }
    }

    // once: bring niri's own hot corners into Screen edges, so turning them on or
    // off here doesn't lose what niri's config had
    Process {
        running: Settings.ready && !Niri.hyprland && !root.cfg.niriImported
        command: [Paths.bin, "compositor", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                let d;
                try {
                    d = JSON.parse(text);
                } catch (e) {
                    return;
                }
                if (d.compositor !== "niri" || !Array.isArray(d.overviewCorners))
                    return;
                const e = root.cfg;
                const wasOn = e.enabled;
                for (const k of Object.keys(root.names)) {
                    const niriHas = d.overviewCorners.includes(root.names[k]);
                    if (niriHas && (e[k] === "none" || !wasOn))
                        e[k] = "overview";
                    else if (!wasOn && !niriHas)
                        e[k] = "none";      // corners that were switched off stay off
                }
                if (d.overviewCorners.length)
                    e.enabled = true;
                e.niriImported = true;
                // a Flamenco action on a corner niri also had: switch niri's off there
                if (JSON.stringify(root.overviewCorners()) !== JSON.stringify(d.overviewCorners)) {
                    Compositor.load();
                    Compositor.queue();
                }
            }
        }
    }

    readonly property var actions: [
        { value: "none", label: "Nothing" },
        { value: "overview", label: "Overview (niri's)", niriOnly: true },
        { value: "activities", label: "Overview (Flamenco)" },
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
        case "activities":
            Panels.toggle("overview", screen);
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
