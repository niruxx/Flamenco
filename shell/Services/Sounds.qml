pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Event sounds from the chosen freedesktop sound theme, plus the installed
// sound themes and fonts for the settings dropdowns.
Singleton {
    id: root

    readonly property var cfg: Settings.data.sound
    property var themes: []                 // [{ value, label }]
    property var fonts: []                  // all font families
    property var monoFonts: []              // monospace families

    function play(event) {
        Quickshell.execDetached([Paths.bin, "sound", "play", event]);
    }

    // shell hooks
    function notification(critical) {
        if (cfg.notifications)
            play(critical ? "dialog-warning" : "message-new-instant");
    }
    function volumeChanged() {
        if (cfg.volumeFeedback)
            volumeDebounce.restart();
    }
    function brightnessChanged() {
        if (cfg.brightnessFeedback)
            brightnessDebounce.restart();
    }

    function load() {
        if (themes.length === 0 && !themeProc.running)
            themeProc.running = true;
        if (fonts.length === 0 && !fontProc.running)
            fontProc.running = true;
    }

    // one click after the volume settles, not one per slider step
    Timer {
        id: volumeDebounce
        interval: 160
        onTriggered: root.play("audio-volume-change")
    }
    Timer {
        id: brightnessDebounce
        interval: 160
        onTriggered: root.play("brightness-change")
    }

    Process {
        id: themeProc
        command: [Paths.bin, "sound", "themes"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.themes = JSON.parse(text);
                } catch (e) {}
            }
        }
    }

    Process {
        id: fontProc
        command: [Paths.bin, "fonts", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    root.fonts = d.families;
                    root.monoFonts = d.mono;
                } catch (e) {}
            }
        }
    }
}
