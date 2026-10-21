pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// mako as the notification daemon (Settings → Notifications → Shown by). The shell
// then lets go of the notification service (Notifs) and runs mako with a config
// of its own in ~/.config/flamenco/mako.conf, made from the shell's theme and
// notification settings (where, how long, Do Not Disturb), rewritten and
// reloaded whenever they change. ~/.config/mako/config is left alone.
Singleton {
    id: root

    readonly property bool on: (Settings.data.notifications.backend || "flamenco") === "mako"
    readonly property string path: Paths.configDir + "/mako.conf"
    property bool found: false
    readonly property var n: Settings.data.notifications

    function hex(c, alpha) {
        const a = alpha === undefined ? c.a : alpha;
        const h = v => Math.round(Math.max(0, Math.min(1, v)) * 255).toString(16).padStart(2, "0");
        return "#" + h(c.r) + h(c.g) + h(c.b) + h(a);
    }
    // the shell's positions in mako's words (top-center is the same in both)
    readonly property string anchor: ["top-right", "top-left", "top-center", "bottom-right", "bottom-left", "bottom-center"].includes(n.position) ? n.position : "top-right"

    readonly property string config: {
        const t = Theme;
        const ms = Math.max(0, (n.timeout ?? 6)) * 1000;
        return [
            "# Written by Flamenco from your theme (Settings → Notifications). Changes here are replaced;",
            "# ~/.config/mako/config is yours and isn't used while Flamenco runs mako.",
            "font=" + t.fontFamily + " " + Math.max(8, Math.round(t.fsMd * 0.75)),
            "background-color=" + hex(t.surface, Math.max(0.6, t.popupOp)),
            "text-color=" + hex(t.text, 1),
            "border-color=" + hex(t.border, 0.9),
            "progress-color=over " + hex(t.accent, 0.35),
            "border-size=1",
            "border-radius=" + t.rXl,
            "width=380",
            "height=220",
            "margin=" + t.edge,
            "padding=" + t.sp4,
            "outer-margin=0",
            "icons=1",
            "max-icon-size=48",
            "icon-location=left",
            "max-visible=5",
            "layer=overlay",
            "anchor=" + anchor,
            "default-timeout=" + ms,
            "ignore-timeout=0",
            "markup=1",
            "actions=1",
            "history=1",
            "format=<b>%s</b>\\n%b",
            "",
            "[app-name=\"\"]",
            "format=<b>%s</b>\\n%b",
            "",
            "[urgency=low]",
            "text-color=" + hex(t.textDim, 1),
            "",
            "[urgency=critical]",
            "border-color=" + hex(t.error, 1),
            "border-size=2",
            "default-timeout=0",
            "",
            "# Do Not Disturb (the shell's switch): hide all but critical ones",
            "[mode=do-not-disturb]",
            "invisible=1",
            "[mode=do-not-disturb urgency=critical]",
            "invisible=0",
            ""
        ].join("\n");
    }

    onConfigChanged: if (on) writeSoon.restart()
    Timer {
        id: writeSoon
        interval: 300
        onTriggered: {
            file.setText(root.config);
            if (daemon.running)
                Quickshell.execDetached(["makoctl", "reload"]);
        }
    }
    FileView {
        id: file
        path: root.path
        atomicWrites: true
        blockLoading: true
        printErrors: false
    }

    // mako runs while it's the chosen one (the config is written first)
    onOnChanged: start()
    Component.onCompleted: start()
    function start() {
        if (!on) {
            daemon.running = false;
            return;
        }
        file.setText(config);
        startSoon.restart();
    }
    // a moment for the shell to let go of the notification service first
    Timer {
        id: startSoon
        interval: 600
        onTriggered: daemon.running = root.on && root.found
    }
    Process {
        id: daemon
        command: ["mako", "--config", root.path]
        onRunningChanged: if (running) Qt.callLater(root.syncDnd)
        // it quit (another notification daemon holding the service?): try again later
        onExited: code => {
            if (root.on && code !== 0)
                retry.restart();
        }
    }
    Timer {
        id: retry
        interval: 5000
        onTriggered: if (root.on && !daemon.running) daemon.running = true
    }

    // Do Not Disturb follows the shell's switch
    function syncDnd() {
        if (daemon.running)
            Quickshell.execDetached(["makoctl", "mode", n.dnd ? "-a" : "-r", "do-not-disturb"]);
    }
    Connections {
        target: Settings.data.notifications
        function onDndChanged() {
            root.syncDnd();
        }
    }

    // the bell, with mako: bring back the last notification, or clear them
    function restore() {
        Quickshell.execDetached(["makoctl", "restore"]);
    }
    function dismissAll() {
        Quickshell.execDetached(["makoctl", "dismiss", "--all"]);
    }

    Process {
        running: true
        command: ["sh", "-c", "command -v mako && command -v makoctl"]
        onExited: code => {
            root.found = code === 0;
            if (root.on)
                root.start();
        }
    }
}
