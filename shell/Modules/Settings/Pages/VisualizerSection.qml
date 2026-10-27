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
    title: I18n.tr("Audio visualizer")
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
            text: !Cava.available ? I18n.tr("Preview (cava isn't installed)") : root.real ? I18n.tr("Live") : I18n.tr("Preview")
            dim: true
            font.pixelSize: Theme.fsXs
        }
    }

    ChoiceRow {
        title: I18n.tr("Style")
        icon: "graphic_eq"
        target: root.v
        key: "style"
        segWidth: 78
        options: [{ value: "bars", label: I18n.tr("Bars") }, { value: "mirror", label: I18n.tr("Mirror") }, { value: "wave", label: I18n.tr("Wave") }, { value: "dots", label: I18n.tr("Dots") }, { value: "radial", label: I18n.tr("Radial") }, { value: "peaks", label: I18n.tr("Peaks") }]
    }
    ChoiceRow {
        title: I18n.tr("Colors")
        icon: "palette"
        target: root.v
        key: "colors"
        segWidth: 86
        options: [{ value: "accent", label: I18n.tr("Accent") }, { value: "palette", label: I18n.tr("Palette") }, { value: "rainbow", label: I18n.tr("Rainbow") }, { value: "fire", label: I18n.tr("Fire") }, { value: "mono", label: I18n.tr("Plain") }]
    }
    ChoiceRow {
        title: I18n.tr("Animation")
        subtitle: ({ smooth: I18n.tr("Glides to each beat"), snappy: I18n.tr("Follows the sound closely"), bouncy: I18n.tr("Springs past each beat and settles"), gravity: I18n.tr("Jumps up at once, falls slowly") })[root.v.motion || "smooth"] ?? ""
        icon: "animation"
        target: root.v
        key: "motion"
        segWidth: 90
        options: [{ value: "smooth", label: I18n.tr("Smooth") }, { value: "snappy", label: I18n.tr("Snappy") }, { value: "bouncy", label: I18n.tr("Bouncy") }, { value: "gravity", label: I18n.tr("Gravity") }]
    }
    SliderRow { title: I18n.tr("Detail"); subtitle: I18n.tr("How finely the sound is split into bands"); icon: "equalizer"; target: root.v; key: "bars"; from: 8; to: 64; stepSize: 4 }
    ChoiceRow { title: I18n.tr("Frame rate"); icon: "speed"; target: root.v; key: "fps"; segWidth: 90; options: [{ value: 30, label: I18n.tr("30 fps") }, { value: 60, label: I18n.tr("60 fps") }] }

    SwitchRow {
        title: I18n.tr("Big on the desktop")
        subtitle: I18n.tr("A visualizer across the screen, above the wallpaper and under your windows, while something plays")
        icon: "fit_screen"
        target: root.v
        key: "band"
    }
    ChoiceRow {
        visible: root.v.band
        title: I18n.tr("Where")
        icon: "vertical_align_center"
        target: root.v
        key: "bandPosition"
        segWidth: 90
        options: [{ value: "bottom", label: I18n.tr("Bottom") }, { value: "center", label: I18n.tr("Middle") }, { value: "top", label: I18n.tr("Top") }]
    }
    SliderRow { visible: root.v.band; title: I18n.tr("Height"); icon: "height"; target: root.v; key: "bandHeight"; from: 80; to: 600; stepSize: 10; suffix: " px" }
    SliderRow { visible: root.v.band; title: I18n.tr("Opacity"); icon: "opacity"; target: root.v; key: "bandOpacity"; from: 0.2; to: 1; stepSize: 0.05; factor: 100; suffix: "%" }
    SettingRow {
        visible: !Cava.available
        title: "cava isn't installed"
        subtitle: I18n.tr("The visualizers need it (System check, or: sudo pacman -S cava)")
        icon: "warning"
    }
}
