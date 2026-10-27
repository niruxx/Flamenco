import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services
import qs.Widgets

// A widget made from your own command (Settings → Bar → Custom widgets): it runs
// every so often (or keeps running, a line per update) and shows what it prints.
// A line of plain text, or waybar-style JSON: {"text", "tooltip", "icon", "class"}
// ("class": "warning" or "critical" colors it). Clicks run commands of their own.
BarChip {
    id: root
    property string customId: ""
    property string screenName
    property int barLevel: 0
    readonly property var cfg: (Settings.data.bar.customs || {})[customId] ?? ({})
    property string text: ""
    property string tip: ""
    property string iconName: cfg.icon || ""
    property string kind: ""
    property bool barVisible: text !== "" || iconName !== ""

    function show(line) {
        line = String(line || "").trim();
        if (line.startsWith("{")) {
            try {
                const j = JSON.parse(line);
                text = String(j.text ?? "");
                tip = String(j.tooltip ?? "");
                if (j.icon)
                    iconName = String(j.icon);
                kind = String(Array.isArray(j.class) ? j.class.join(" ") : (j.class ?? ""));
                return;
            } catch (e) {}
        }
        text = line;
    }
    function run(cmd) {
        if (cmd)
            Quickshell.execDetached(["sh", "-c", cmd]);
        // its output may have changed
        if (!(cfg.watch ?? false))
            again.restart();
    }
    onClicked: run(cfg.onClick || "")
    onRightClicked: run(cfg.onRightClick || "")
    onMiddleClicked: run(cfg.onMiddleClick || "")

    // every few seconds; or (watch) one long-running command, a line per update
    Process {
        id: proc
        command: ["sh", "-c", root.cfg.exec || ""]
        running: !!root.cfg.exec && (root.cfg.watch ?? false)
        stdout: SplitParser {
            onRead: line => {
                if (root.cfg.watch ?? false)
                    root.show(line);
            }
        }
    }
    Process {
        id: once
        command: ["sh", "-c", root.cfg.exec || ""]
        stdout: StdioCollector {
            onStreamFinished: root.show(text.split("\n").find(l => l.trim() !== "") ?? "")
        }
    }
    Timer {
        id: again
        interval: 300
        onTriggered: if (!once.running && root.cfg.exec) once.running = true
    }
    Timer {
        running: !!root.cfg.exec && !(root.cfg.watch ?? false)
        interval: Math.max(1, root.cfg.interval ?? 10) * 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!once.running) once.running = true
    }

    BarFlow {
        spacing: Theme.barVertical ? 0 : 5
        FIcon {
            visible: root.iconName !== ""
            icon: root.iconName
            size: Theme.barIcon
            color: root.kind.includes("critical") ? Theme.error : root.kind.includes("warning") ? Theme.warning : Theme.accent2
        }
        FText {
            visible: root.text !== ""
            width: Math.min(implicitWidth, 260)
            text: root.text
            elide: Text.ElideRight
            color: root.kind.includes("critical") ? Theme.error : root.kind.includes("warning") ? Theme.warning : Theme.text
            font.pixelSize: Theme.barVertical ? Theme.fsXs : Theme.fsSm
        }
    }
}
