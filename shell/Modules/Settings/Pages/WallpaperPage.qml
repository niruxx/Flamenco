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
        ChoiceRow {
            title: "Fill"
            subtitle: ({ crop: "Fills the screen, trimming the edges", fit: "The whole picture, with bars", stretch: "Fills the screen, out of proportion", center: "Its own size, in the middle", tile: "Its own size, repeated" })[page.w.fillMode || "crop"]
            icon: "aspect_ratio"
            target: page.w
            key: "fillMode"
            segWidth: 82
            options: [{ value: "crop", label: "Crop" }, { value: "fit", label: "Fit" }, { value: "stretch", label: "Stretch" }, { value: "center", label: "Center" }, { value: "tile", label: "Tile" }]
        }
        SwitchRow { title: "Cycle automatically"; icon: "shuffle"; target: page.w; key: "cycle" }
        SliderRow { visible: page.w.cycle; title: "Every"; icon: "schedule"; target: page.w; key: "cycleMinutes"; from: 1; to: 240; stepSize: 1; suffix: " min" }
        SwitchRow {
            title: "Favorites only"
            subtitle: (page.w.favorites || []).length ? "Shuffle and changing automatically pick from your " + page.w.favorites.length + " favorites" : "Star wallpapers in the switcher (☆) to make favorites"
            icon: "star"
            target: page.w
            key: "cycleFavorites"
        }
    }

    Group {
        title: "Color and mode"
        SwitchRow {
            title: "A plain color instead of a picture"
            icon: "format_color_fill"
            target: page.w
            key: "solid"
        }
        ColorChoiceRow {
            visible: page.w.solid
            title: "Color"
            icon: "palette"
            target: page.w
            key: "solidColor"
            choices: []
            swatches: ["#1e1f24", "#0f1115", "#2b2a27", "#1a2433", "#26323b", "#3b2a3a", "#f2f1f0", "#d9e4ec"]
        }
        SwitchRow {
            visible: !page.w.solid
            title: "One for light mode, one for dark mode"
            subtitle: page.w.byMode ? "Switching the mode swaps them. Picking a wallpaper sets the one for the mode you're in" : "Off: the same wallpaper in both"
            icon: "contrast"
            target: page.w
            key: "byMode"
        }
        Repeater {
            model: page.w.byMode && !page.w.solid ? [{ key: "light", label: "Light mode", icon: "light_mode" }, { key: "dark", label: "Dark mode", icon: "dark_mode" }] : []
            SettingRow {
                id: mrow
                required property var modelData
                readonly property string path: page.w[modelData.key] || page.w.current
                title: modelData.label
                subtitle: (page.w[modelData.key] ? Paths.fileName(page.w[modelData.key]) : "Not chosen: the main wallpaper") + (Theme.dark === (modelData.key === "dark") ? " (now)" : "")
                icon: modelData.icon
                Row {
                    spacing: 8
                    ClippingRectangle {
                        width: 96
                        height: 56
                        radius: Theme.rSm
                        color: Theme.surfaceHigh
                        Image {
                            anchors.fill: parent
                            source: Wallpapers.stillUrl(mrow.path)
                            sourceSize: Qt.size(192, 112)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                    }
                    FButton {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Use the current one"
                        variant: "tonal"
                        onClicked: page.w[mrow.modelData.key] = page.w.current
                    }
                }
            }
        }
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
                    // its own folder to shuffle / cycle from
                    FDropdown {
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: 170
                        placeholder: "Folder: all"
                        readonly property var subdirs: {
                            const out = [];
                            for (const f of Wallpapers.files) {
                                const d = f.slice(0, f.lastIndexOf("/"));
                                if (d !== Wallpapers.dir && !out.includes(d))
                                    out.push(d);
                            }
                            return out.sort();
                        }
                        options: [{ value: "", label: "Folder: all" }].concat(subdirs.map(d => ({ value: d, label: d.slice(Wallpapers.dir.length + 1) })))
                        current: (page.w.screenFolders || {})[srow.modelData.name] ?? ""
                        onSelected: v => {
                            const all = Object.assign({}, page.w.screenFolders || {});
                            if (v)
                                all[srow.modelData.name] = v;
                            else
                                delete all[srow.modelData.name];
                            page.w.screenFolders = all;
                        }
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
