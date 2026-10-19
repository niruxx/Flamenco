import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.Commons
import qs.Services
import qs.Widgets
import qs.Modules.WallpaperPicker

Page {
    id: page
    title: "Wallpaper"
    readonly property var w: Settings.data.wallpaper

    Group {
        title: "Switcher"
        ChoiceRow {
            title: "Style"
            subtitle: page.w.picker === "grid" ? "A grid of thumbnails in a panel" : "A 3D cover flow over the screen, with the picture's colors. ← → browse, Enter applies."
            icon: "view_carousel"
            target: page.w
            key: "picker"
            segWidth: 120
            options: [{ value: "carousel", label: "Carousel", icon: "view_carousel" }, { value: "grid", label: "Grid", icon: "grid_view" }]
        }
        SettingRow {
            title: "Open the switcher"
            icon: "wallpaper"
            FButton {
                text: "Open"
                variant: "tonal"
                onClicked: {
                    Panels.settingsOpen = false;
                    Panels.open("wallpaper", "");
                }
            }
        }
    }

    Group {
        SettingRow {
            title: "Folder"
            subtitle: Wallpapers.status === "missing" ? "Folder not found" : Wallpapers.scanning ? "Scanning…" : Wallpapers.files.length + " wallpapers (including subfolders)" + (Wallpapers.liveCount ? ", " + Wallpapers.liveCount + " live" : "")
            icon: "folder"
            FFolderField {
                width: 400
                path: page.w.dir
                status: Wallpapers.status
                busy: Wallpapers.scanning
                onChanged: p => Wallpapers.setDir(p)
            }
        }
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

    // which screen the library below sets, in per-screen mode
    property string target: ""

    LiveSection {}

    Group {
        title: "Screens"
        SwitchRow {
            title: "A different wallpaper on each screen"
            subtitle: page.w.perScreen ? "Colors from the wallpaper follow the first screen's" : "Off: every screen shows the same one"
            icon: "monitor"
            target: page.w
            key: "perScreen"
        }
        Repeater {
            model: page.w.perScreen ? Quickshell.screens : []
            SettingRow {
                id: srow
                required property var modelData
                readonly property bool own: !!(page.w.screens || {})[modelData.name]
                title: modelData.name + (modelData.model ? " · " + modelData.model : "")
                subtitle: (own ? Paths.fileName(Wallpapers.forScreen(modelData.name)) : "The main wallpaper") + (modelData.name === Wallpapers.primary ? " (first screen)" : "")
                icon: "wallpaper"
                Row {
                    spacing: 8
                    ClippingRectangle {
                        width: 96
                        height: 56
                        radius: Theme.rSm
                        color: Theme.surfaceHigh
                        Image {
                            anchors.fill: parent
                            source: Wallpapers.stillUrl(Wallpapers.forScreen(srow.modelData.name))
                            sourceSize: Qt.size(192, 112)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                    }
                    FButton {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Pick below"
                        variant: page.target === srow.modelData.name ? "filled" : "tonal"
                        onClicked: page.target = srow.modelData.name
                    }
                    FButton {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: srow.own && srow.modelData.name !== Wallpapers.primary
                        text: "Use main"
                        variant: "text"
                        onClicked: {
                            const all = Object.assign({}, page.w.screens || {});
                            delete all[srow.modelData.name];
                            page.w.screens = all;
                        }
                    }
                }
            }
        }
    }

    Group {
        title: page.w.perScreen ? "Library · " + (page.target ? "for " + page.target : "for every screen") : "Library"
        SettingRow {
            visible: page.w.perScreen
            title: "Click a wallpaper to set it for"
            icon: "ads_click"
            FDropdown {
                implicitWidth: 240
                options: [{ value: "", label: "Every screen" }].concat(Quickshell.screens.map(x => ({ value: x.name, label: x.name })))
                current: page.target
                onSelected: v => page.target = v
            }
        }
        WallpaperGrid {
            Layout.fillWidth: true
            Layout.margins: 8
            implicitHeight: 420
            screenName: page.w.perScreen ? page.target : ""
        }
    }
}
