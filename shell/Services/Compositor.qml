pragma Singleton

import QtQuick
import Quickshell
import qs.Services as S
import Quickshell.Io
import qs.Commons

// Window look and behavior (gaps, focus ring, corners, cursor hiding, named
// workspaces…), kept in settings.json and written into the compositor config
// by `flamenco compositor apply`. niri and Hyprland reload it live.
Singleton {
    id: root

    readonly property var cfg: Settings.data.windows
    readonly property var keys: ["gaps", "struts", "centerColumn", "defaultWidth", "focusRing", "focusRingWidth", "border",
        "borderWidth", "activeColor", "inactiveColor", "borderActiveColor", "borderInactiveColor", "gradient", "gradientTo",
        "gradientAngle", "cornerRadius", "shadows", "focusFollowsMouse", "warpMouse",
        "hideCursorTyping", "hideCursorAfter", "preferNoCsd", "hotCorners", "skipHotkeyOverlay", "workspaceBackForth"]
    property string status: ""
    property bool failed: false
    readonly property bool busy: applier.running
    // a change made before the compositor config was read in; applied right after
    property bool pending: false

    function load() {
        if (!cfg.imported && !getter.running)
            getter.running = true;
    }

    function queue() {
        if (cfg.imported) {
            applyDelay.restart();
        } else {
            // reading the config first keeps settings this page doesn't show
            pending = true;
            load();
        }
    }

    function hex(c) {
        return String(Qt.color(c)).slice(0, 7);
    }

    function spec() {
        const s = {};
        for (const k of keys)
            s[k] = cfg[k];
        if (cfg.gradient && !cfg.gradientTo)
            s.gradientTo = hex(Theme.palette.accent2);
        if (cfg.syncColors) {
            s.activeColor = hex(Theme.palette.accent);
            s.inactiveColor = hex(Theme.palette.border);
        }
        s.overviewCorners = S.Edges.overviewCorners();
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
                    if (root.pending || JSON.stringify(S.Edges.overviewCorners()) !== JSON.stringify(d.overviewCorners ?? []))
                        root.queue();
                } catch (e) {
                    root.fail("couldn't read the compositor config");
                }
                root.pending = false;
            }
        }
    }

    // a change that didn't reach the compositor shouldn't go unnoticed: say so
    function fail(msg) {
        status = msg;
        if (failed && lastError === msg)
            return;
        failed = true;
        lastError = msg;
        Quickshell.execDetached(["notify-send", "-a", "Flamenco Settings", "-i", "dialog-warning", "Window settings weren't applied", msg]);
    }
    property string lastError: ""

    Process {
        id: applier
        property string out: ""
        stdout: StdioCollector {
            onStreamFinished: applier.out = text.trim()
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) root.status = text.trim().split("\n").pop()
        }
        onExited: code => {
            if (code !== 0) {
                root.fail(root.status || "flamenco compositor apply failed");
            } else {
                root.failed = false;
                root.lastError = "";
                if (applier.out)
                    root.status = applier.out.split("\n").pop();
            }
        }
    }
}
