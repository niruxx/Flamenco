pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// fuzzel as the app launcher (Settings → Launcher → Launcher app). Its look comes
// from the shell's theme: a config of its own in ~/.config/flamenco/fuzzel.ini
// (your ~/.config/fuzzel/fuzzel.ini is left alone), rewritten whenever the colors,
// fonts, roundness or launcher settings change, and passed with --config.
Singleton {
    id: root

    readonly property bool on: (Settings.data.launcher.backend || "flamenco") === "fuzzel"
    readonly property string path: Paths.configDir + "/fuzzel.ini"
    property bool found: false
    readonly property bool running: proc.running

    // #rrggbbaa, as fuzzel wants it (no #)
    function hex(c, alpha) {
        const a = alpha === undefined ? c.a : alpha;
        const h = v => Math.round(Math.max(0, Math.min(1, v)) * 255).toString(16).padStart(2, "0");
        return h(c.r) + h(c.g) + h(c.b) + h(a);
    }
    // the launcher's place on the screen, in fuzzel's words
    readonly property string anchor: {
        const p = Settings.data.launcher.position || "center";
        if (p === "bar")
            return Theme.barPos === "bottom" ? "bottom-left" : Theme.barPos === "right" ? "top-right" : "top-left";
        return ["center", "top", "bottom", "top-left", "top-right", "bottom-left", "bottom-right"].includes(p) ? p : "center";
    }
    readonly property string config: {
        const t = Theme;
        const lines = [
            "# Written by Flamenco from your theme (Settings → Launcher). Changes here are replaced;",
            "# ~/.config/fuzzel/fuzzel.ini is yours and isn't used while Flamenco opens fuzzel.",
            "[main]",
            "font=" + t.fontFamily + ":size=" + Math.max(8, Math.round(t.fsMd * 0.75)),
            "prompt=\"❯ \"",
            "placeholder=Search apps",
            "terminal=" + (Settings.data.general.terminal || "kitty") + " -e",
            "layer=overlay",
            "exit-on-keyboard-focus-loss=yes",
            "anchor=" + anchor,
            "x-margin=" + (anchor === "center" || anchor === "top" || anchor === "bottom" ? 0 : t.edge),
            "y-margin=" + (anchor === "center" ? 0 : t.edge),
            "width=" + Math.max(30, Math.round((Settings.data.launcher.width || 600) / 12)),
            "lines=" + Math.max(4, Settings.data.launcher.maxResults || 8),
            "horizontal-pad=" + t.sp4,
            "vertical-pad=" + t.sp3,
            "inner-pad=" + t.sp2,
            "line-height=" + Math.round(t.fsMd * 2.2),
            "image-size-ratio=0.5",
            "icons-enabled=yes"
        ];
        if (Settings.data.apps.iconTheme)
            lines.push("icon-theme=" + Settings.data.apps.iconTheme);
        lines.push("",
            "[colors]",
            "background=" + hex(t.surface, Math.max(0.6, t.panelOp)),
            "text=" + hex(t.text, 1),
            "prompt=" + hex(t.accent, 1),
            "placeholder=" + hex(t.textDim, 1),
            "input=" + hex(t.text, 1),
            "match=" + hex(t.accent, 1),
            "selection=" + hex(t.accent, 0.24),
            "selection-text=" + hex(t.text, 1),
            "selection-match=" + hex(t.accent, 1),
            "counter=" + hex(t.textDim, 1),
            "border=" + hex(t.border, 0.9),
            "",
            "[border]",
            "width=1",
            "radius=" + t.rXl,
            "",
            "[dmenu]",
            "exit-immediately-if-empty=yes",
            "");
        return lines.join("\n");
    }

    // (re)written when it changes, while fuzzel is the launcher
    onConfigChanged: if (on) writeSoon.restart()
    onOnChanged: if (on) writeSoon.restart()
    Timer {
        id: writeSoon
        interval: 300
        onTriggered: file.setText(root.config)
    }
    Component.onCompleted: if (on) writeSoon.restart()
    FileView {
        id: file
        path: root.path
        atomicWrites: true
        blockLoading: true
        printErrors: false
    }

    // opening it again closes it, like the shell's own launcher
    function toggle() {
        if (proc.running) {
            proc.signal(15);
            return;
        }
        file.setText(config);
        proc.running = true;
    }
    Process {
        id: proc
        command: ["fuzzel", "--config", root.path]
        onExited: code => {
            if (code === 127)
                console.warn("[Fuzzel] fuzzel isn't installed; falling back to Flamenco's launcher");
        }
    }

    Process {
        running: true
        command: ["sh", "-c", "command -v fuzzel"]
        onExited: code => root.found = code === 0
    }
}
