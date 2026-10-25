import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

// Settings → Sound → Audio visualizer: how every visualizer looks and moves (the
// bar's, the desktop widget's, the dashboard's) and the big one on the desktop.
// The preview follows the music, or a made-up beat while nothing plays.
Group {
    id: root
    title: "Audio visualizer"
    readonly property var v: Settings.data.visualizer
    readonly property bool real: Media.playing && Cava.available
    property var demo: []

    // the preview listens while this page is open and something plays
    Component.onCompleted: Cava.users++
    Component.onDestruction: Cava.users = Math.max(0, Cava.users - 1)
    Timer {
        running: !root.real && root.visible
        interval: 1000 / 30
        repeat: true
        property real t: 0
        onTriggered: {
            t += 0.06;
            const out = [];
            for (let i = 0; i < 24; i++)
                out.push(Math.max(0, Math.min(1, 0.45 + 0.35 * Math.sin(t * 2.3 + i * 0.5) * Math.cos(t * 0.7 + i * 0.13) + 0.15 * Math.sin(t * 7 + i))));
            root.demo = out;
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.margins: Theme.sp3
        implicitHeight: 150
        radius: Theme.rLg
        color: Theme.alpha(Theme.shadow, Theme.dark ? 0.35 : 0.08)
        Spectrum {
            readonly property bool round: (root.v.style || "bars") === "radial"
            anchors.centerIn: parent
            width: round ? 140 : parent.width - 32
            height: round ? 140 : parent.height - 24
            count: round ? 48 : 32
            values: root.real ? Cava.values : root.demo
        }
        FText {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 10
            text: !Cava.available ? "Preview (cava isn't installed)" : root.real ? "Live" : "Preview"
            dim: true
            font.pixelSize: Theme.fsXs
        }
    }

    ChoiceRow {
        title: "Style"
        icon: "graphic_eq"
        target: root.v
        key: "style"
        segWidth: 78
        options: [{ value: "bars", label: "Bars" }, { value: "mirror", label: "Mirror" }, { value: "wave", label: "Wave" }, { value: "dots", label: "Dots" }, { value: "radial", label: "Radial" }, { value: "peaks", label: "Peaks" }]
    }
    ChoiceRow {
        title: "Colors"
        icon: "palette"
        target: root.v
        key: "colors"
        segWidth: 86
        options: [{ value: "accent", label: "Accent" }, { value: "palette", label: "Palette" }, { value: "rainbow", label: "Rainbow" }, { value: "fire", label: "Fire" }, { value: "mono", label: "Plain" }]
    }
    ChoiceRow {
        title: "Animation"
        subtitle: ({ smooth: "Glides to each beat", snappy: "Follows the sound closely", bouncy: "Springs past each beat and settles", gravity: "Jumps up at once, falls slowly" })[root.v.motion || "smooth"] ?? ""
        icon: "animation"
        target: root.v
        key: "motion"
        segWidth: 90
        options: [{ value: "smooth", label: "Smooth" }, { value: "snappy", label: "Snappy" }, { value: "bouncy", label: "Bouncy" }, { value: "gravity", label: "Gravity" }]
    }
    SliderRow { title: "Detail"; subtitle: "How finely the sound is split into bands"; icon: "equalizer"; target: root.v; key: "bars"; from: 8; to: 64; stepSize: 4 }
    ChoiceRow { title: "Frame rate"; icon: "speed"; target: root.v; key: "fps"; segWidth: 90; options: [{ value: 30, label: "30 fps" }, { value: 60, label: "60 fps" }] }

    SwitchRow {
        title: "Big on the desktop"
        subtitle: "A visualizer across the screen, above the wallpaper and under your windows, while something plays"
        icon: "fit_screen"
        target: root.v
        key: "band"
    }
    ChoiceRow {
        visible: root.v.band
        title: "Where"
        icon: "vertical_align_center"
        target: root.v
        key: "bandPosition"
        segWidth: 90
        options: [{ value: "bottom", label: "Bottom" }, { value: "center", label: "Middle" }, { value: "top", label: "Top" }]
    }
    SliderRow { visible: root.v.band; title: "Height"; icon: "height"; target: root.v; key: "bandHeight"; from: 80; to: 600; stepSize: 10; suffix: " px" }
    SliderRow { visible: root.v.band; title: "Opacity"; icon: "opacity"; target: root.v; key: "bandOpacity"; from: 0.2; to: 1; stepSize: 0.05; factor: 100; suffix: "%" }
    SettingRow {
        visible: !Cava.available
        title: "cava isn't installed"
        subtitle: "The visualizers need it (System check, or: sudo pacman -S cava)"
        icon: "warning"
    }
}
