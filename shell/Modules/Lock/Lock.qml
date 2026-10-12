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

    readonly property var cfg: Settings.data.lock
    // SDDM theme folder to show, or "" for the built-in lock
    readonly property string sddmDir: cfg.backend !== "sddm" ? "" : cfg.sddmThemePath ? Paths.expand(cfg.sddmThemePath) : cfg.sddmTheme ? (cfg.sddmTheme.startsWith("/") ? cfg.sddmTheme : "/usr/share/sddm/themes/" + cfg.sddmTheme) : ""
    // set when an SDDM theme fails or the emergency shortcut is used
    property bool fallback: false
    property string fallbackReason: ""

    function lock() {
        if (cfg.backend === "command" && cfg.command.trim() !== "") {
            Quickshell.execDetached(["sh", "-c", cfg.command]);
            return;
        }
        if (locked)
            return;
        buffer = "";
        errorText = "";
        unlocking = false;
        fallback = false;
        fallbackReason = "";
        locked = true;
    }

    function useFallback(reason) {
        if (fallback)
            return;
        console.warn("[Lock] using built-in lock screen:", reason);
        fallbackReason = reason;
        fallback = true;
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
            id: surface
            color: "black"

            Loader {
                anchors.fill: parent
                focus: true
                sourceComponent: root.sddmDir !== "" && !root.fallback ? sddmC : builtinC
            }

            Component {
                id: builtinC
                LockSurface { ctx: root }
            }

            Component {
                id: sddmC
                SddmHost {
                    ctx: root
                    themeDir: root.sddmDir
                    onFailed: reason => root.useFallback(reason)
                }
            }

            // Escape hatch if an SDDM theme misbehaves: always reach the built-in lock.
            Shortcut {
                sequence: "Ctrl+Alt+Shift+L"
                context: Qt.WindowShortcut
                onActivated: root.useFallback("emergency shortcut")
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
