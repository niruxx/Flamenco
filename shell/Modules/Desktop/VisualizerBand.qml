import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services
import qs.Widgets

// The big visualizer (Settings → Sound → Audio visualizer → On the desktop): a band
// across each screen, above the wallpaper and under windows, while something plays.
// Click-through; it fades in and out with the music. The radial style is a big
// circle in the middle of it instead.
Variants {
    model: (Settings.data.visualizer.band ?? false) ? Quickshell.screens : []

    PanelWindow {
        id: win
        required property ShellScreen modelData
        readonly property var cfg: Settings.data.visualizer
        readonly property string pos: ["bottom", "center", "top"].includes(cfg.bandPosition) ? cfg.bandPosition : "bottom"
        readonly property bool playing: Media.playing && Cava.available
        readonly property bool round: (cfg.style || "bars") === "radial"
        readonly property real shown: fade.v
        // animated value lives on an Item: Behaviors on the window itself crash Qt 6.12
        Item {
            id: fade
            property real v: win.playing ? 1 : 0
            Behavior on v { Anim { duration: 900 } }
        }

        // cava runs while it shows
        readonly property bool live: playing
        onLiveChanged: live ? Cava.users++ : Cava.users = Math.max(0, Cava.users - 1)
        Component.onCompleted: if (live) Cava.users++
        Component.onDestruction: if (live) Cava.users = Math.max(0, Cava.users - 1)

        screen: modelData
        visible: shown > 0.01
        color: "transparent"
        anchors {
            left: true
            right: true
            top: win.pos === "top" || win.pos === "center"
            bottom: win.pos === "bottom" || win.pos === "center"
        }
        implicitHeight: win.pos === "center" ? 0 : Math.max(60, cfg.bandHeight || 220)
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "flamenco-visualizer"
        mask: Region {}

        Spectrum {
            readonly property real h: Math.max(60, win.cfg.bandHeight || 220)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: win.pos === "center" ? parent.verticalCenter : undefined
            anchors.bottom: win.pos === "bottom" ? parent.bottom : undefined
            anchors.top: win.pos === "top" ? parent.top : undefined
            width: win.round ? h : parent.width - Theme.edge * 2
            height: h
            count: win.round ? 72 : Math.max(24, Math.min(128, Math.floor(width / 18)))
            gap: 0.3
            active: win.shown > 0.01
            opacity: win.shown * (win.cfg.bandOpacity ?? 0.85)
            // the top band hangs down, mirrored
            transform: Scale { origin.y: height / 2; yScale: win.pos === "top" && !win.round && (Settings.data.visualizer.style || "bars") !== "mirror" ? -1 : 1 }
        }
    }
}
