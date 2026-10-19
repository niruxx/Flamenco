pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Generates a palette from the current wallpaper using matugen (optional).
// Handles both the matugen 2.x and 3.x JSON layouts.
Singleton {
    id: root

    property var dark: null
    property var light: null
    readonly property bool available: dark !== null && light !== null
    property bool busy: proc.running

    // a live (video) wallpaper's colors come from its poster (Wallpapers runs this again once it's made)
    readonly property string wanted: {
        if (Settings.data.appearance.palette !== "wallpaper")
            return "";
        const p = Paths.expand(Settings.data.wallpaper.current);
        return Paths.isVideo(p) ? Paths.poster(p) : p;
    }
    property int attempt: 0

    // after a new wallpaper's transition has (nearly) played, so the colors change as
    // it finishes revealing instead of before it starts
    onWantedChanged: afterTransition.restart()
    Component.onCompleted: generate()
    Timer {
        id: afterTransition
        interval: Settings.data.wallpaper.transition === "none" ? 0 : Math.max(0, (Settings.data.wallpaper.duration || 1200) * 0.8)
        onTriggered: root.generate()
    }

    function generate() {
        if (!wanted)
            return;
        attempt = 0;
        run();
    }

    function run() {
        const base = ["matugen", "image", wanted, "--json", "hex", "--dry-run"];
        // matugen 3 prompts when it finds several source colors; 2.x doesn't know the flag.
        proc.command = attempt === 0 ? base.concat(["--source-color-index", "0"]) : base;
        proc.running = true;
    }

    function role(colors, mode, name) {
        const v = colors?.[mode]?.[name] ?? colors?.[name]?.[mode] ?? colors?.[name]?.["default"];
        if (typeof v === "string")
            return v;
        return v?.color ?? null;
    }

    function build(colors, mode) {
        const r = n => role(colors, mode, n);
        if (!r("primary"))
            return null;
        const fb = Palettes.get("flamenco", mode === "dark");
        const pick = (n, key) => r(n) || fb[key];
        return {
            bg: pick("surface", "bg"),
            surface: pick("surface_container", "surface"),
            surfaceHigh: pick("surface_container_high", "surfaceHigh"),
            surfaceHighest: pick("surface_container_highest", "surfaceHighest"),
            border: pick("outline_variant", "border"),
            text: pick("on_surface", "text"),
            textDim: pick("on_surface_variant", "textDim"),
            accent: pick("primary", "accent"),
            onAccent: pick("on_primary", "onAccent"),
            accent2: pick("secondary", "accent2"),
            accent3: pick("tertiary", "accent3"),
            error: pick("error", "error"),
            warning: pick("tertiary", "warning"),
            success: fb.success
        };
    }

    Process {
        id: proc

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const json = JSON.parse(text);
                    const d = root.build(json.colors, "dark");
                    const l = root.build(json.colors, "light");
                    if (d && l) {
                        root.dark = d;
                        root.light = l;
                    }
                } catch (e) {
                    console.warn("[ColorGen] could not parse matugen output:", e);
                }
            }
        }

        onExited: code => {
            if (code !== 0 && root.attempt === 0) {
                root.attempt = 1;
                root.run();
            } else if (code !== 0) {
                console.warn("[ColorGen] matugen failed; is it installed?");
            }
        }
    }
}
