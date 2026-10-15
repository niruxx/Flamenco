pragma Singleton

import QtQuick
import Quickshell

// Flamenco shim for Noctalia's ToastService: toasts become notifications.
Singleton {
    id: root

    function notify(title, description, icon, kind, duration) {
        const args = ["notify-send", "-a", "Flamenco plugin", "-t", String(duration || 4000)];
        if (kind === "error")
            args.push("-u", "critical");
        args.push(String(title || ""), String(description || ""));
        Quickshell.execDetached(args);
    }
    function showNotice(title, description = "", icon = "", duration = 3000, actionLabel = "", actionCallback = null) {
        notify(title, description, icon, "notice", duration);
    }
    function showWarning(title, description = "", duration = 4000, actionLabel = "", actionCallback = null) {
        notify(title, description, "", "warning", duration);
    }
    function showError(title, description = "", duration = 6000, actionLabel = "", actionCallback = null) {
        notify(title, description, "", "error", duration);
    }
    function dismissToast() {}
}
