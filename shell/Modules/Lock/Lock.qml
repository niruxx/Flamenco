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
        Fingerprint.refresh();
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

    function granted() {
        root.unlocking = true;
        unlockTimer.start();
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
                root.granted();
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

    // ── fingerprint ──
    // A second PAM check that waits for a finger the whole time the screen is
    // locked, next to the password one. It uses the shell's own PAM file
    // (assets/pam/fingerprint: pam_fprintd only), so /etc/pam.d isn't touched.
    readonly property bool fpWanted: locked && !unlocking && cfg.fingerprint && Fingerprint.enrolled
    property string fpText: ""
    property bool fpError: false
    property int fpQuickFails: 0
    property real fpStartedAt: 0

    onFpWantedChanged: fpWanted ? fpStart() : fpStop()

    function fpStart() {
        if (fprint.active)
            return;
        fpStartedAt = Date.now();
        fprint.start();
    }

    function fpStop() {
        fpRetry.stop();
        if (fprint.active)
            fprint.abort();
        fpText = "";
        fpError = false;
        fpQuickFails = 0;
    }

    // after a timeout or too many misses, start again; stop if it keeps failing at once (no reader)
    function fpAgain() {
        fpQuickFails = Date.now() - fpStartedAt < 3000 ? fpQuickFails + 1 : 0;
        if (fpWanted && fpQuickFails < 3)
            fpRetry.restart();
    }

    PamContext {
        id: fprint
        configDirectory: Quickshell.shellDir + "/assets/pam"
        config: "fingerprint"
        onPamMessage: {
            if (responseRequired) {
                respond("");
                return;
            }
            if (messageIsError && !/time/i.test(message)) {
                root.fpError = true;
                root.fpText = "Not recognized, try again";
                fpClear.restart();
            }
        }
        onCompleted: result => {
            if (result === PamResult.Success) {
                if (pam.active)
                    pam.abort();
                root.authenticating = false;
                root.granted();
            } else {
                root.fpAgain();
            }
        }
        onError: () => root.fpAgain()
    }

    Timer {
        id: fpRetry
        interval: 1500
        onTriggered: if (root.fpWanted) root.fpStart()
    }
    Timer {
        id: fpClear
        interval: 2500
        onTriggered: {
            root.fpError = false;
            root.fpText = "";
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

    // suspend after being idle (separate timers on battery / plugged in)
    IdleMonitor {
        readonly property int minutes: Power.onBattery ? Settings.data.power.idleSuspendBattery : Settings.data.power.idleSuspendAC
        enabled: minutes > 0 && Settings.data.power.allowSleep && !Toggles.caffeine
        timeout: Math.max(1, minutes) * 60
        respectInhibitors: true
        onIsIdleChanged: if (isIdle) {
            if (Settings.data.power.lockOnSleep)
                root.lock();
            Power.suspend();
        }
    }

    // logind: PrepareForSleep(true) right before any suspend (lid, idle, menu, systemctl)
    // and Session.Lock for `loginctl lock-session` / HandleLidSwitch=lock
    readonly property string sessionPath: {
        const id = Quickshell.env("XDG_SESSION_ID") || "";
        // D-Bus object paths escape a leading digit as _3X
        return id ? "/org/freedesktop/login1/session/" + (/^[0-9]/.test(id) ? "_3" + id[0] + id.slice(1) : id) : "";
    }
    Process {
        running: true
        command: ["gdbus", "monitor", "--system", "--dest", "org.freedesktop.login1"]
        stdout: SplitParser {
            onRead: line => {
                if (line.includes("PrepareForSleep (true") && Settings.data.power.lockOnSleep)
                    root.lock();
                else if (line.includes(".Session.Lock ") && (!root.sessionPath || line.startsWith(root.sessionPath + ":")))
                    root.lock();
            }
        }
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
