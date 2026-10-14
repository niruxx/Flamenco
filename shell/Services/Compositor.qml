pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Window look and behavior (gaps, focus ring, corners, cursor hiding, named
// workspaces…), kept in settings.json and written into the compositor config
// by `flamenco compositor apply`. niri and Hyprland reload it live.
Singleton {
    id: root

    readonly property var cfg: Settings.data.windows
    readonly property var keys: ["gaps", "struts", "centerColumn", "defaultWidth", "focusRing", "focusRingWidth", "border",
        "borderWidth", "activeColor", "inactiveColor", "cornerRadius", "shadows", "focusFollowsMouse", "warpMouse",
        "hideCursorTyping", "hideCursorAfter", "preferNoCsd", "hotCorners", "skipHotkeyOverlay", "workspaceBackForth"]
    property string status: ""
    readonly property bool busy: applier.running

    function load() {
        if (!cfg.imported && !getter.running)
            getter.running = true;
    }

    function queue() {
        if (cfg.imported)
            applyDelay.restart();
    }

    function hex(c) {
        return String(Qt.color(c)).slice(0, 7);
    }

    function spec() {
        const s = {};
        for (const k of keys)
            s[k] = cfg[k];
        if (cfg.syncColors) {
            s.activeColor = hex(Theme.palette.accent);
            s.inactiveColor = hex(Theme.palette.border);
        }
        s.overviewCorners = Edges.overviewCorners();
        s.hotCorners = s.overviewCorners.length > 0;
        s.workspaces = Settings.data.workspaces.named || [];
        s.screenshotPath = Settings.data.screenshot.path;
        return s;
    }

    // ring / border colors follow the palette
    Connections {
        target: Theme
        function onPaletteChanged() {
            if (root.cfg.syncColors)
                root.queue();
        }
    }

    Timer {
        id: applyDelay
        interval: 600
        onTriggered: {
            if (applier.running) {
                restart();
                return;
            }
            applier.command = [Paths.bin, "compositor", "apply", "--json", JSON.stringify(root.spec())];
            applier.running = true;
        }
    }

    Process {
        id: getter
        command: [Paths.bin, "compositor", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    for (const k of root.keys)
                        if (d[k] !== undefined)
                            root.cfg[k] = d[k];
                    if (Array.isArray(d.workspaces) && d.workspaces.length && !(Settings.data.workspaces.named || []).length)
                        Settings.data.workspaces.named = d.workspaces;
                    if (d.screenshotPath)
                        Settings.data.screenshot.path = d.screenshotPath;
                    // keep custom colors that differ from the palette
                    root.cfg.syncColors = d.activeColor === root.hex(Theme.palette.accent) || d.activeColor === "#ff5d73";
                    root.cfg.imported = true;
                    // Screen edges may already want other corners than niri's config has
                    if (JSON.stringify(Edges.overviewCorners()) !== JSON.stringify(d.overviewCorners ?? []))
                        root.queue();
                } catch (e) {}
            }
        }
    }

    Process {
        id: applier
        stdout: StdioCollector {
            onStreamFinished: if (text.trim()) root.status = text.trim().split("\n").pop()
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) root.status = text.trim().split("\n").pop()
        }
    }
}
