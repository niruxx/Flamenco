pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Pushes the shell palette + stylesheet options to Qt and GTK applications
// by calling `flamenco apps-theme` with a JSON spec on stdin.
Singleton {
    id: root

    readonly property var cfg: Settings.data.apps
    property string lastStatus: ""
    property bool busy: proc.running

    readonly property var spec: ({
            name: Theme.paletteName,
            dark: Theme.dark,
            colors: Theme.appPalette,
            caret: String(Theme.caret),
            radius: cfg.matchRoundness ? Theme.rSm : cfg.radius,
            fontFamily: Theme.fontFamily,
            monoFamily: Theme.monoFamily,
            fontSize: Math.round(10 * Theme.scale),
            options: {
                syncFonts: cfg.syncFonts,
                iconTheme: cfg.iconTheme,
                cursorTheme: cfg.cursorTheme,
                cursorTint: cfg.cursorTint === "accent" ? String(Theme.accent) : (cfg.cursorTint || ""),
                gtkTheme: cfg.gtkTheme,
                soundTheme: Settings.data.sound.theme,
                eventSounds: Settings.data.sound.eventSounds,
                kvantumTheme: cfg.kvantumTheme,
                cursorSize: cfg.cursorSize,
                scrollbars: cfg.scrollbars,
                buttons: cfg.buttons,
                accentSelection: cfg.accentSelection,
                contrast: cfg.contrast,
                qt: cfg.qt,
                qtStyle: cfg.qtStyle,
                qss: cfg.qss,
                kdeColors: cfg.kdeColors,
                customQss: cfg.customQss,
                gtk: cfg.gtk,
                gtk3: cfg.gtk3,
                gtk4: cfg.gtk4,
                gtkExtras: cfg.gtkExtras,
                customGtkCss: cfg.customGtkCss,
                apps: cfg.extraApps
            }
        })

    // Installed themes for the settings dropdowns (`flamenco list-themes --json`).
    property var installed: ({ icons: [], cursors: [], gtk: [], qtStyles: ["Fusion"], kvantum: [], sddm: [] })
    property bool scanning: lister.running

    function refreshInstalled() {
        if (!lister.running)
            lister.running = true;
    }

    Process {
        id: lister
        command: [Paths.bin, "list-themes", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.installed = JSON.parse(text);
                } catch (e) {
                    console.warn("[AppTheming] list-themes failed:", e);
                }
            }
        }
    }

    // only while apps follow the shell (not after going back to GNOME's or KDE's defaults)
    readonly property bool following: (cfg.scheme || "flamenco") === "flamenco"
    onSpecChanged: if (cfg.autoApply && following && Settings.ready) debounce.restart()

    // Settings → App Theming → Color scheme: the shell's palette, or a desktop's defaults
    function useScheme(v) {
        cfg.scheme = v;
        debounce.stop();
        if (v === "flamenco") {
            apply();
            return;
        }
        lastStatus = "Resetting…";
        resetter.command = [Paths.bin, "apps-theme", "--reset", v];
        resetter.running = true;
    }
    Process {
        id: resetter
        onExited: code => root.lastStatus = code === 0 ? ((root.cfg.scheme === "kde" ? "KDE" : "GNOME") + " defaults · " + Qt.formatTime(new Date(), "HH:mm:ss")) : "Reset failed (exit " + code + ")"
        stdout: StdioCollector {
            onStreamFinished: if (text.trim()) console.log("[AppTheming]", text.trim())
        }
    }

    function apply() {
        if (!following)
            return;
        if (proc.running) {
            debounce.restart();
            return;
        }
        proc.command = [Paths.bin, "apps-theme", "--json", JSON.stringify(spec)];
        proc.running = true;
    }

    Timer {
        id: debounce
        interval: 900
        onTriggered: root.apply()
    }

    Process {
        id: proc
        onExited: code => {
            root.lastStatus = code === 0 ? "Applied " + Qt.formatTime(new Date(), "HH:mm:ss") : "Failed (exit " + code + ")";
        }
        stdout: StdioCollector {
            onStreamFinished: if (text.trim()) console.log("[AppTheming]", text.trim())
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) root.lastStatus = text.trim().split("\n").pop()
        }
    }
}
