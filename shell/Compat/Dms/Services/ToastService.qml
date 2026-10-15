pragma Singleton

import QtQuick
import Quickshell

// Flamenco shim for DMS's ToastService: toasts become notifications.
Singleton {
    readonly property int levelInfo: 0
    readonly property int levelWarn: 1
    readonly property int levelError: 2
    property bool toastVisible: false

    function showToast(message, level = 0, details = "", command = "", category = "") {
        const args = ["notify-send", "-a", "Flamenco plugin"];
        if (level === 2)
            args.push("-u", "critical");
        args.push(String(message || ""), String(details || ""));
        Quickshell.execDetached(args);
    }
    function showInfo(message, details = "", command = "", category = "") {
        showToast(message, 0, details);
    }
    function showSuccess(message, details = "", command = "", category = "") {
        showToast(message, 0, details);
    }
    function showWarning(message, details = "", command = "", category = "") {
        showToast(message, 1, details);
    }
    function showError(message, details = "", command = "", category = "") {
        showToast(message, 2, details);
    }
    function hideToast() {}
    function dismissCategory(category) {}
}
