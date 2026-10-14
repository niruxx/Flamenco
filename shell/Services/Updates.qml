pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Waiting package updates (`flamenco updates`): repo, AUR and Flatpak.
Singleton {
    id: root

    property var repo: []
    property var aur: []
    property var flatpak: []
    property string upgrade: ""
    property real checked: 0
    readonly property int count: repo.length + aur.length + flatpak.length
    readonly property bool checking: proc.running

    function check() {
        if (!proc.running)
            proc.running = true;
    }

    // in a terminal; checks again once it's closed
    function runUpgrade() {
        upgrader.command = Paths.termHold(upgrade || "sudo pacman -Syu");
        upgrader.running = true;
    }

    Timer {
        running: true
        interval: Math.max(10, Settings.data.updates.interval) * 60000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.check()
    }

    Process {
        id: proc
        command: [Paths.bin, "updates", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    root.repo = d.repo ?? [];
                    root.aur = d.aur ?? [];
                    root.flatpak = d.flatpak ?? [];
                    root.upgrade = d.upgrade ?? "";
                    root.checked = Date.now();
                } catch (e) {}
            }
        }
    }
    Process {
        id: upgrader
        onExited: root.check()
    }
}
