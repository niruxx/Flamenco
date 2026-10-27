pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Caps Lock and Num Lock, from the keyboards' lights (`flamenco lockkeys watch`;
// niri doesn't report them), for the toasts and the bar's lock keys widget. Runs
// while something wants it.
Singleton {
    id: root

    property bool caps: false
    property bool num: false
    property int users: 0
    readonly property bool wanted: users > 0 || (Settings.data.toasts.enabled ?? true)
    signal changed(string key, bool on)

    Process {
        running: root.wanted
        command: [Paths.bin, "lockkeys", "watch"]
        stdout: SplitParser {
            onRead: line => {
                let k = null;
                try {
                    k = JSON.parse(line);
                } catch (e) {
                    return;
                }
                const was = { caps: root.caps, num: root.num };
                root.caps = !!k.caps;
                root.num = !!k.num;
                if (k.initial)
                    return;
                if (root.caps !== was.caps)
                    root.changed("caps", root.caps);
                if (root.num !== was.num)
                    root.changed("num", root.num);
            }
        }
    }
}
