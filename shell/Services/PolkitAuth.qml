pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// The password dialog apps and Flamenco ask for (polkit: "authentication is
// required to…"), drawn by Flamenco (Modules/Polkit/PolkitDialog). Only one agent
// can serve a session, so another one started first (polkit-gnome, polkit-kde,
// hyprpolkitagent…) keeps the job; Settings → Power says which.
Singleton {
    id: root

    readonly property bool wanted: Settings.data.power.polkitAgent ?? true
    readonly property var agent: loader.item
    // false: Quickshell was built without polkit, or it's turned off
    readonly property bool available: agent !== null
    readonly property var flow: agent?.flow ?? null
    readonly property bool active: (agent?.isActive ?? false) && flow !== null
    property bool failed: false               // the last try was wrong
    property bool switching: false

    // another agent that would hold the session first
    property string other: ""
    function findOthers() {
        if (!finder.running)
            finder.running = true;
    }
    Process {
        id: finder
        command: ["sh", "-c", "for p in polkit-gnome-authentication-agent-1 polkit-kde-authentication-agent-1 polkit-mate-authentication-agent-1 lxpolkit lxqt-policykit-agent hyprpolkitagent xfce-polkit; do pgrep -x \"$p\" >/dev/null 2>&1 || pgrep -f \"/$p\" >/dev/null 2>&1 && echo \"$p\"; done | head -n1"]
        stdout: StdioCollector {
            onStreamFinished: root.other = text.trim()
        }
    }
    Component.onCompleted: findOthers()

    // when several people may answer (wheel, admins): this user, rather than the first
    function pickSelf() {
        const ids = flow?.identities ?? [];
        if (!flow || ids.length < 2)
            return;
        const me = Quickshell.env("USER");
        for (let i = 0; i < ids.length; i++) {
            const id = ids[i];
            if (!id.isGroup && id.string === me && id !== flow.selectedIdentity) {
                // choosing someone restarts the session, which polkit reports as a failure
                switching = true;
                flow.selectedIdentity = id;
                switching = false;
                return;
            }
        }
    }

    function submit(text) {
        if (flow && !flow.isCompleted) {
            failed = false;
            flow.submit(text);
        }
    }
    function cancel() {
        if (flow && !flow.isCompleted)
            flow.cancelAuthenticationRequest();
    }

    Connections {
        target: root.agent
        enabled: root.agent !== null
        function onAuthenticationRequestStarted() {
            root.failed = false;
            root.pickSelf();
        }
    }
    Connections {
        target: root.flow
        enabled: root.flow !== null
        function onAuthenticationFailed() {
            if (!root.switching)
                root.failed = true;
        }
    }

    Loader {
        id: loader
        active: root.wanted
        asynchronous: false
        source: "PolkitAgentInstance.qml"
    }
}
