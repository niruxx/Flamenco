pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Screenshots taken from Settings → Screenshots. This lives here and not on the
// page: Settings is unloaded when it closes, which took a page's timer with it,
// so the screenshot never happened. Settings comes back once it's done.
Singleton {
    id: root

    property bool busy: wait.running || proc.running
    property bool reopen: false

    // close Settings (so it isn't in the picture), then capture
    function fromSettings(mode) {
        reopen = Panels.settingsOpen;
        Panels.settingsOpen = false;
        wait.mode = mode;
        wait.restart();
    }

    Timer {
        id: wait
        property string mode: "region"
        interval: 450
        onTriggered: {
            proc.command = [Paths.bin, "screenshot", mode];
            proc.running = true;
        }
    }

    Process {
        id: proc
        onExited: if (root.reopen) back.restart()
    }

    Timer {
        id: back
        interval: 400
        onTriggered: {
            root.reopen = false;
            Panels.openSettings("screenshots");
        }
    }
}
