pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Drives and accessories plugged in or taken out, for the device pop-ups
// (Settings → Notifications → Devices). `flamenco devices watch` follows udev and
// gives one line per device a person would recognise; this keeps the pop-ups and
// does what their buttons ask (open a drive, eject it).
Singleton {
    id: root

    readonly property var cfg: Settings.data.devices
    readonly property bool on: (cfg.enabled ?? true) && Settings.ready
    // what's showing: { uid, action, kind, name, detail, dev, note }
    property ListModel popups: ListModel {}
    property int seq: 0

    readonly property var kinds: ({
            drive: { label: "Drive", icon: "usb" }, phone: { label: "Phone", icon: "smartphone" },
            keyboard: { label: "Keyboard", icon: "keyboard" }, mouse: { label: "Mouse", icon: "mouse" },
            input: { label: "Input device", icon: "videogame_asset" }, camera: { label: "Camera", icon: "photo_camera" },
            audio: { label: "Audio device", icon: "headphones" }, bluetooth: { label: "Bluetooth adapter", icon: "bluetooth" },
            printer: { label: "Printer", icon: "print" }, network: { label: "Network adapter", icon: "lan" },
            device: { label: "USB device", icon: "devices" }
        })

    function show(e) {
        if (e.kind === "drive" ? !(cfg.drives ?? true) : !(cfg.accessories ?? true))
            return;
        if (e.action === "removed" && !(cfg.removals ?? true))
            return;
        // a drive taken out: its own pop-up (with buttons) goes
        for (let i = popups.count - 1; i >= 0; i--)
            if (e.dev && popups.get(i).dev === e.dev)
                popups.remove(i);
        if (Settings.data.notifications.dnd)
            return;
        popups.insert(0, { uid: ++seq, action: e.action, kind: e.kind, name: e.name || "", detail: e.detail || "", dev: e.dev || "", note: "" });
        while (popups.count > 4)
            popups.remove(popups.count - 1);
        if (cfg.sound ?? true)
            Sounds.play(e.action === "added" ? "device-added" : "device-removed");
    }
    function dismiss(uid) {
        for (let i = 0; i < popups.count; i++)
            if (popups.get(i).uid === uid) {
                popups.remove(i);
                return;
            }
    }
    function note(uid, text) {
        for (let i = 0; i < popups.count; i++)
            if (popups.get(i).uid === uid)
                popups.setProperty(i, "note", text);
    }
    function test() {
        show({ action: "added", kind: "drive", name: "Test drive", detail: "This is how a USB drive looks", dev: "" });
    }

    // ── the buttons ──
    function open(uid, dev) {
        note(uid, "Opening…");
        runner.createObject(root, { uid: uid, what: "open", command: [Paths.bin, "devices", "open", dev] }).running = true;
    }
    function eject(uid, dev) {
        note(uid, "Ejecting…");
        runner.createObject(root, { uid: uid, what: "eject", command: [Paths.bin, "devices", "eject", dev] }).running = true;
    }
    Component {
        id: runner
        Process {
            id: rp
            property int uid
            property string what
            stdout: StdioCollector { id: rout }
            stderr: StdioCollector { id: rerr }
            onExited: code => {
                const out = rout.text.trim();
                if (code !== 0)
                    root.note(rp.uid, (rerr.text.trim().split("\n").pop() || "It didn't work").replace(/^flamenco: /, ""));
                else if (rp.what === "open") {
                    Quickshell.execDetached(["xdg-open", out]);
                    root.dismiss(rp.uid);
                } else
                    root.note(rp.uid, out.charAt(0).toUpperCase() + out.slice(1));
                rp.destroy();
            }
        }
    }

    // ── following udev ──
    Process {
        id: watcher
        running: root.on
        command: [Paths.bin, "devices", "watch"]
        stdout: SplitParser {
            onRead: line => {
                try {
                    root.show(JSON.parse(line));
                } catch (e) {}
            }
        }
        // stopped by itself (not turned off): again in a moment
        onExited: if (root.on) again.restart()
    }
    Timer {
        id: again
        interval: 5000
        onTriggered: if (root.on && !watcher.running) watcher.running = true
    }
}
