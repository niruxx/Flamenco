import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import qs.Commons
import qs.Services

// Session lock (ext-session-lock) + PAM auth + idle auto-lock.
Scope {
    id: root

    property bool locked: false
    property bool unlocking: false
    property string buffer: ""
    property bool authenticating: false
    property string errorText: ""
    property int shakeCount: 0

    function lock() {
        if (locked)
            return;
        buffer = "";
        errorText = "";
        unlocking = false;
        locked = true;
    }

    function submit() {
        if (authenticating || buffer === "")
            return;
        errorText = "";
        authenticating = true;
        pam.start();
    }

    PamContext {
        id: pam
        config: "login"
        onPamMessage: {
            if (responseRequired)
                respond(root.buffer);
        }
        onCompleted: result => {
            root.authenticating = false;
            if (result === PamResult.Success) {
                root.unlocking = true;
                unlockTimer.start();
            } else {
                root.errorText = "Wrong password";
                root.buffer = "";
                root.shakeCount++;
            }
        }
        onError: () => {
            root.authenticating = false;
            root.errorText = "Authentication error";
        }
    }

    // Let the exit animation play before releasing the lock.
    Timer {
        id: unlockTimer
        interval: Theme.durXl + 50
        onTriggered: {
            root.locked = false;
            root.unlocking = false;
            root.buffer = "";
        }
    }

    WlSessionLock {
        locked: root.locked

        WlSessionLockSurface {
            color: "black"
            LockSurface {
                anchors.fill: parent
                ctx: root
            }
        }
    }

    // ── idle ──
    IdleMonitor {
        enabled: Settings.data.lock.autoLock && !Toggles.caffeine
        timeout: Math.max(1, Settings.data.lock.idleMinutes) * 60
        respectInhibitors: true
        onIsIdleChanged: if (isIdle) root.lock()
    }

    IdleMonitor {
        enabled: Settings.data.lock.screenOffMinutes > 0 && !Toggles.caffeine
        timeout: Math.max(1, Settings.data.lock.screenOffMinutes) * 60
        respectInhibitors: true
        onIsIdleChanged: if (isIdle) Niri.action("power-off-monitors")
    }

    IpcHandler {
        target: "lock"
        function lock(): void {
            root.lock();
        }
        function isLocked(): bool {
            return root.locked;
        }
    }
}
