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
        ChoiceRow {
            title: "Transition"
            icon: "transition_fade"
            target: page.w
            key: "transition"
            segWidth: 80
            options: [{ value: "fade", label: "Fade" }, { value: "zoom", label: "Zoom" }, { value: "circle", label: "Circle" }, { value: "wipe", label: "Wipe" }, { value: "random", label: "Mix" }]
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
