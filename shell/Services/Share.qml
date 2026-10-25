pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Screen sharing's "which screen?" question (xdg-desktop-portal-wlr hands it to
// `flamenco portals choose`, which asks here). The SharePicker window shows the
// screens; the answer goes back in a file in the private runtime folder.
Singleton {
    id: root

    property string requestId: ""
    property var outputs: []                 // the screens the portal offered (names)
    readonly property bool asking: requestId !== ""

    function ask(id, names) {
        // a fresh request replaces one still open (that one is answered "cancel")
        if (asking)
            answer("");
        if (!/^[0-9a-f]{8,32}$/.test(id))
            return;
        outputs = String(names).split(",").filter(n => n);
        requestId = id;
    }
    function answer(name) {
        if (!asking)
            return;
        const file = Paths.runDir + "/flamenco-share-" + requestId + ".answer";
        Quickshell.execDetached(["sh", "-c", 'umask 077; printf "%s" "$1" > "$2"', "sh", outputs.includes(name) ? name : "", file]);
        requestId = "";
        outputs = [];
    }
}
