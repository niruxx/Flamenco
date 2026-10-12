import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets
import qs.Modules.WallpaperPicker

Page {
    id: page
    title: "Wallpaper"
    readonly property var w: Settings.data.wallpaper

    Group {
        TextRow { title: "Folder"; icon: "folder"; target: page.w; key: "dir"; placeholder: "~/Pictures/Wallpapers" }
        DropdownRow {
            title: "Transition"
            subtitle: "How a new wallpaper appears"
            icon: "transition_fade"
            target: page.w
            key: "transition"
            options: [
                { value: "mosaic", label: "Mosaic: tiles bloom out from the center" },
                { value: "ripple", label: "Ripple: expanding circle led by rings" },
                { value: "sweep", label: "Sweep: diagonal band with a glowing edge" },
                { value: "blinds", label: "Blinds: staggered vertical slats" },
                { value: "circle", label: "Circle: soft circular reveal" },
                { value: "wipe", label: "Wipe: left to right" },
                { value: "focus", label: "Focus: sharpens out of a blur" },
                { value: "fade", label: "Fade" },
                { value: "random", label: "Mix: a different one each time" }
            ]
        }
        SettingRow {
            title: "Preview"
            subtitle: "Switch to a random wallpaper from your folder"
            icon: "play_circle"
            FButton {
                text: "Try it"
                icon: "shuffle"
                variant: "tonal"
                onClicked: Wallpapers.random()
            }
        }
        SliderRow { title: "Transition duration"; icon: "timer"; target: page.w; key: "duration"; from: 200; to: 3000; stepSize: 50; suffix: "ms" }
        ChoiceRow { title: "Fill"; icon: "aspect_ratio"; target: page.w; key: "fillMode"; options: [{ value: "crop", label: "Crop" }, { value: "fit", label: "Fit" }, { value: "stretch", label: "Stretch" }] }
        SwitchRow { title: "Cycle automatically"; icon: "shuffle"; target: page.w; key: "cycle" }
        SliderRow { visible: page.w.cycle; title: "Every"; icon: "schedule"; target: page.w; key: "cycleMinutes"; from: 1; to: 240; stepSize: 1; suffix: " min" }
    }

    Group {
        title: "Library"
        WallpaperGrid {
            Layout.fillWidth: true
            Layout.margins: 8
            implicitHeight: 420
        }
    }
}
