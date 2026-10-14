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

    // event -> sound file, resolved once per theme so a click doesn't wait for
    // the CLI to start; plays straight through pw-play (paplay as fallback)
    property var paths: ({})
    readonly property var feedbackEvents: ["audio-volume-change", "brightness-change", "message-new-instant", "dialog-warning"]

    function play(event) {
        const f = paths[event];
        if (f === "")
            return;      // the theme (and its fallbacks) has no such sound
        if (f) {
            Quickshell.execDetached(["sh", "-c", 'pw-play "$1" 2>/dev/null || paplay "$1"', "sh", f]);
            return;
        }
        Quickshell.execDetached([Paths.bin, "sound", "play", event]);
        if (f === undefined)
            resolve();
    }

    function resolve() {
        if (!resolver.running)
            resolver.running = true;
    }

    // shell hooks
    function notification(critical) {
        if (cfg.notifications)
            play(critical ? "dialog-warning" : "message-new-instant");
    }
    function volumeChanged() {
        if (cfg.volumeFeedback)
            volumeTick.hit();
    }
    function brightnessChanged() {
        if (cfg.brightnessFeedback)
            brightnessTick.hit();
    }

    Connections {
        target: root.cfg
        function onThemeChanged() {
            root.paths = {};
            root.resolve();
        }
    }
    Component.onCompleted: resolve()

    Process {
        id: resolver
        command: ["sh", "-c", 'for e in "$@"; do printf "%s\t%s\n" "$e" "$("$0" sound find "$e" 2>/dev/null)"; done', Paths.bin, ...root.feedbackEvents]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = {};
                for (const line of text.split("\n")) {
                    const [e, f] = line.split("\t");
                    if (e)
                        m[e] = f || "";      // "" = the theme has no such sound
                }
                root.paths = m;
            }
        }
    }

    function load() {
        if (themes.length === 0 && !themeProc.running)
            themeProc.running = true;
        if (fonts.length === 0 && !fontProc.running)
            fontProc.running = true;
    }

    // A click on every key press, right away. While a slider is dragged the
    // clicks are spaced out (one per cooldown, plus one when it stops).
    component Tick: Timer {
        signal fire
        property bool pending: false
        interval: 90
        function hit() {
            if (running) {
                pending = true;
            } else {
                fire();
                start();
            }
        }
        onTriggered: if (pending) {
            pending = false;
            fire();
            start();
        }
    }
    Tick {
        id: volumeTick
        onFire: root.play("audio-volume-change")
    }
    Tick {
        id: brightnessTick
        onFire: root.play("brightness-change")
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
                    // the shell's bundled fonts are there even when not installed system-wide
                    const add = (list, f) => list.includes(f) ? list : [f].concat(list);
                    root.fonts = add(add(d.families, "Google Sans Code"), "Google Sans Flex");
                    root.monoFonts = add(d.mono, "Google Sans Code");
                } catch (e) {}
            }
        }
    }
}
