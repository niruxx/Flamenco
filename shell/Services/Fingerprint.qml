pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// fprintd: is there a reader, and which of your fingers are enrolled.
// Enrolling itself happens in Settings → Lock & Login (`flamenco fingerprint`).
Singleton {
    id: root

    property var st: ({ installed: false, device: "", stages: 0, fingers: [], error: "", pam: {} })
    property bool loaded: false

    readonly property bool installed: !!st.installed
    readonly property bool reader: installed && st.device !== ""
    readonly property var fingers: st.fingers ?? []
    readonly property bool enrolled: reader && fingers.length > 0

    // fprintd's names, in the order they're offered
    readonly property var names: ["right-index-finger", "left-index-finger", "right-thumb", "left-thumb", "right-middle-finger", "left-middle-finger", "right-ring-finger", "left-ring-finger", "right-little-finger", "left-little-finger"]

    function label(finger) {
        const s = String(finger).replace(/-finger$/, "").replace(/-/g, " ");
        return s.charAt(0).toUpperCase() + s.slice(1) + (finger.endsWith("-finger") ? " finger" : "");
    }

    function refresh() {
        if (!getter.running)
            getter.running = true;
    }

    Component.onCompleted: refresh()

    Process {
        id: getter
        command: [Paths.bin, "fingerprint", "status", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.st = JSON.parse(text);
                } catch (e) {}
                root.loaded = true;
            }
        }
    }
}
