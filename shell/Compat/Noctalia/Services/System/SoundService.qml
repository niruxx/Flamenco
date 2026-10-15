pragma Singleton

import QtQuick
import Quickshell

// Flamenco shim for Noctalia's SoundService: plays files with pw-play (or paplay).
Singleton {
    readonly property bool multimediaAvailable: true

    function resolvePath(p) {
        const s = String(p || "");
        return s.startsWith("file://") ? decodeURIComponent(s.slice(7)) : s.startsWith("~/") ? Quickshell.env("HOME") + s.slice(1) : s;
    }
    function playSound(soundPath, options) {
        const p = resolvePath(soundPath);
        if (p)
            Quickshell.execDetached(["sh", "-c", 'command -v pw-play >/dev/null && exec pw-play "$1" || exec paplay "$1"', "sh", p]);
    }
    function stopSound(soundPath) {
        const p = resolvePath(soundPath);
        Quickshell.execDetached(["pkill", "-f", "-x", "(pw-play|paplay) " + p.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")]);
    }
}
