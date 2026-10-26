import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: "Appearance"
    subtitle: "Colors, shape and motion for the shell. The palette is also pushed to Qt and GTK apps (see App Theming)."
    readonly property var a: Settings.data.appearance

    Component.onCompleted: Sounds.load()

    readonly property var accents: ["#ff5d73", "#ff8a4c", "#f5c542", "#7bd88f", "#3ec7c2", "#5b9cff", "#9b7bff", "#f272c8"]

    function setAccent(v) {
        v = v.trim();
        if (v === "") {
            a.accentOverride = "";
            return;
        }
        if (!/^#?[0-9a-fA-F]{6}$/.test(v))
            return;
        a.accentOverride = (v.startsWith("#") ? v : "#" + v).toLowerCase();
    }

    // bar / dock / launcher / notification layouts in one click
    readonly property var presets: [
        { id: "flamenco", label: "Flamenco", icon: "local_fire_department", hint: "Black and grey: pills on a solid bar, a rounded screen frame",
          appearance: { palette: "noir", mode: "dark", accentOverride: "", screenFrame: true, frameWidth: 6, frameRadius: 18, blendPanels: false },
          bar: { position: "top", style: "framed", height: 44, workspaceStyle: "pills", batteryStyle: "icon", statsStyle: "text", statsTemp: false, clockLayout: "inline", clockAlign: "center",
                 left: ["launcher", "workspaces"], center: ["clock"],
                 right: ["recording", "privacy", "updates", "tray", "network", "bluetooth", "audio", "battery", "notifications", "quicksettings", "power"] },
          dock: { enabled: false }, launcher: { position: "center" }, notifications: { position: "top-right" } },
        { id: "y2k", label: "Y2K", icon: "auto_awesome", hint: "Chrome and pearl, hot pink and cyber cyan, bubbly",
          appearance: { palette: "y2k", mode: "dark", accentOverride: "", finish: "chrome", roundness: 1.5, panelOpacity: 0.9, screenFrame: false, blendPanels: false },
          bar: { position: "top", style: "capsule", height: 40, border: true, workspaceStyle: "dots", batteryStyle: "pill", statsStyle: "rings", statsTemp: false, clockLayout: "inline", clockAlign: "center",
                 left: ["launcher", "workspaces"], center: ["clock", "media"],
                 right: ["tray", "network", "bluetooth", "audio", "battery", "notifications", "quicksettings"] },
          dock: { enabled: true, autoHide: false, magnify: true }, launcher: { position: "center" }, notifications: { position: "top-right" } },
        { id: "aero", label: "Frutiger Aero", icon: "water_drop", hint: "Glossy glass, sky blue and grass green",
          appearance: { palette: "aero", mode: "light", accentOverride: "", finish: "gloss", roundness: 1.25, panelOpacity: 0.82, blur: true, screenFrame: false, blendPanels: false },
          bar: { position: "bottom", style: "floating", height: 48, border: true, workspaceStyle: "apps", batteryStyle: "battery", statsStyle: "text", statsTemp: false, clockLayout: "stacked", clockAlign: "center",
                 left: ["launcher", "taskbar"], center: [],
                 right: ["tray", "network", "bluetooth", "audio", "battery", "clock", "notifications", "quicksettings"] },
          dock: { enabled: false }, launcher: { position: "bottom-left" }, notifications: { position: "bottom-right" } },
        { id: "liquidglass", label: "Liquid Glass", icon: "water_drop", hint: "A macOS-style menu bar and dock, see-through glass everywhere",
          appearance: { palette: "glass", mode: "dark", accentOverride: "", finish: "liquid", roundness: 1.4, panelOpacity: 0.62, uiOpacity: 1,
                        barOpacity: 0.55, popupOpacity: 0.7, switcherOpacity: 0.6, blur: true, screenFrame: false, blendPanels: false, shadows: true },
          // the menu bar: the start button (the  menu), the app in front; status icons, then the clock last
          bar: { position: "top", style: "attached", height: 32, border: false, hide: "never", workspaceStyle: "dots", batteryStyle: "pill", statsStyle: "text",
                 statsTemp: false, clockLayout: "inline", clockAlign: "right", startIcon: "distro", startLabel: "",
                 left: ["launcher", "window"], center: [],
                 right: ["tray", "recording", "privacy", "battery", "network", "bluetooth", "audio", "quicksettings", "notifications", "clock"] },
          dock: { enabled: true, position: "bottom", style: "classic", autoHide: false, magnify: true, zoom: 0.6, indicator: "dot", border: true, opacity: 0.85, roundness: 1.4 },
          launcher: { position: "center" }, notifications: { position: "top-right" } },
        { id: "islands", label: "Islands", icon: "view_column_2", hint: "Three floating islands: app icons per workspace, ring gauges, battery shape, stacked clock",
          bar: { position: "top", style: "islands", height: 40, workspaceStyle: "apps", batteryStyle: "battery", statsStyle: "rings", statsTemp: true, clockLayout: "stacked", clockAlign: "center",
                 left: ["launcher", "separator", "workspaces", "window"], center: ["media", "visualizer"],
                 right: ["sysstats", "separator", "recording", "privacy", "updates", "tray", "keyboard", "network", "bluetooth", "audio", "mic", "battery", "notifications", "quicksettings", "clock", "power"] },
          dock: { enabled: false }, launcher: { position: "center" }, notifications: { position: "top-right" } },
        { id: "modern", label: "Modern", icon: "auto_awesome", hint: "Floating top bar, centered clock",
          bar: { position: "top", style: "floating", height: 40, workspaceStyle: "pills", batteryStyle: "pill", statsStyle: "text", statsTemp: false, clockLayout: "inline",
                 left: ["launcher", "workspaces", "window"], center: ["clock", "media"],
                 right: ["recording", "privacy", "updates", "tray", "sysstats", "keyboard", "network", "bluetooth", "audio", "mic", "battery", "notifications", "quicksettings", "power"] },
          dock: { enabled: false }, launcher: { position: "center" }, notifications: { position: "top-right" } },
        { id: "minimal", label: "Minimal", icon: "remove", hint: "Slim islands, just the essentials",
          bar: { position: "top", style: "islands", height: 34, workspaceStyle: "dots", batteryStyle: "dot", statsStyle: "text", statsTemp: false, clockLayout: "inline",
                 left: ["workspaces"], center: ["clock"], right: ["recording", "privacy", "updates", "tray", "network", "audio", "mic", "battery", "quicksettings"] },
          dock: { enabled: false }, launcher: { position: "center" }, notifications: { position: "top-center" } },
        { id: "classic", label: "Classic", icon: "desktop_windows", hint: "Taskbar at the bottom, Windows-style",
          bar: { position: "bottom", style: "attached", height: 44, workspaceStyle: "numbers", batteryStyle: "icon", statsStyle: "text", statsTemp: false, clockLayout: "inline",
                 left: ["launcher", "workspaces", "taskbar"], center: [],
                 right: ["recording", "privacy", "updates", "tray", "keyboard", "network", "bluetooth", "audio", "mic", "battery", "clock", "notifications", "quicksettings"] },
          dock: { enabled: false }, launcher: { position: "bottom-left" }, notifications: { position: "bottom-right" } },
        { id: "mac", label: "Dock & menu bar", icon: "dock_to_bottom", hint: "Thin top bar and a dock, macOS-style",
          bar: { position: "top", style: "attached", height: 32, workspaceStyle: "pills", batteryStyle: "outline", statsStyle: "text", statsTemp: false, clockLayout: "inline",
                 left: ["launcher", "window"], center: [],
                 right: ["recording", "privacy", "updates", "tray", "network", "bluetooth", "audio", "mic", "battery", "quicksettings", "clock", "notifications"] },
          dock: { enabled: true, autoHide: false, magnify: true }, launcher: { position: "center" }, notifications: { position: "top-right" } },
        { id: "vertical", label: "Vertical", icon: "side_navigation", hint: "Side bar, more room for windows",
          bar: { position: "left", style: "floating", height: 44, workspaceStyle: "pills", batteryStyle: "vertical", statsStyle: "text", statsTemp: false, clockLayout: "inline",
                 left: ["launcher", "workspaces"], center: [],
                 right: ["recording", "privacy", "updates", "tray", "network", "audio", "mic", "battery", "clock", "notifications", "quicksettings", "power"] },
          dock: { enabled: false }, launcher: { position: "bar" }, notifications: { position: "top-right" } }
    ]

    function applyPreset(p) {
        const d = Settings.data;
        for (const section of ["appearance", "bar", "dock", "launcher", "notifications"])
            for (const k in (p[section] ?? {}))
                d[section][k] = Array.isArray(p[section][k]) ? p[section][k].slice() : p[section][k];
        // the screen frame belongs to the Flamenco look; other layouts leave it off
        if (p.appearance?.screenFrame === undefined)
            a.screenFrame = false;
        // likewise the gloss / chrome finish and the rounder shapes of Aero and Y2K
        if (p.appearance?.finish === undefined)
            a.finish = "flat";
        if (p.appearance?.roundness === undefined && ["y2k", "aero", "liquidglass"].includes(a.layoutPreset))
            a.roundness = 1;
        a.layoutPreset = p.id;
    }

    Group {
        title: "Mode"
        ChoiceRow {
            title: "Color mode"
            icon: "contrast"
            target: page.a
            key: "mode"
            options: [{ value: "dark", label: "Dark", icon: "dark_mode" }, { value: "light", label: "Light", icon: "light_mode" }]
            segWidth: 110
        }
        ChoiceRow {
            title: "Switch automatically"
            subtitle: !AutoMode.on ? "" : page.a.autoMode === "sun" && !AutoMode.sunKnown ? "Sunset and sunrise need weather on (it knows your location); using the times below until then. " + AutoMode.nextSwitch
                : AutoMode.nextSwitch + (AutoMode.usingSun ? " (sunset / sunrise)" : "") + ". Changing the mode by hand lasts until then."
            icon: "routine"
            target: page.a
            key: "autoMode"
            segWidth: 130
            options: [{ value: "off", label: "Off" }, { value: "sun", label: "Sun" }, { value: "schedule", label: "Schedule" }]
        }
        TextRow { visible: page.a.autoMode === "schedule" || (page.a.autoMode === "sun" && !AutoMode.sunKnown); title: "Light from"; subtitle: "24-hour time"; icon: "light_mode"; target: page.a; key: "lightAt"; placeholder: "07:00" }
        TextRow { visible: page.a.autoMode === "schedule" || (page.a.autoMode === "sun" && !AutoMode.sunKnown); title: "Dark from"; subtitle: "24-hour time"; icon: "dark_mode"; target: page.a; key: "darkAt"; placeholder: "20:00" }
    }

    Group {
        title: "Palette"

        GridLayout {
            Layout.fillWidth: true
            Layout.margins: 12
            columns: 3
            rowSpacing: 12
            columnSpacing: 12

            Repeater {
                model: Palettes.names.concat(["wallpaper"])

                Rectangle {
                    id: sw
                    required property string modelData
                    readonly property bool sel: page.a.palette === modelData
                    readonly property var pal: modelData === "wallpaper" ? (ColorGen.available ? (Theme.dark ? ColorGen.dark : ColorGen.light) : null) : Palettes.get(modelData, Theme.dark)

                    Layout.fillWidth: true
                    implicitHeight: 96
                    radius: sel ? Theme.rXl : Theme.rLg
                    color: pal ? pal.bg : Theme.surfaceHigh
                    border.width: sel ? 3 : 1
                    border.color: sel ? Theme.accent : Theme.border
                    scale: tap.pressed ? 0.96 : 1

                    Behavior on radius { Anim { easing.bezierCurve: Theme.curves.spring } }
                    Behavior on scale { Anim { duration: Theme.durShort } }

                    Row {
                        x: 14
                        y: 14
                        spacing: -8
                        Repeater {
                            model: sw.pal ? [sw.pal.accent, sw.pal.accent2, sw.pal.accent3, sw.pal.surfaceHighest] : []
                            Rectangle {
                                required property var modelData
                                width: 30; height: 30; radius: 15
                                color: modelData
                                border.width: 2
                                border.color: sw.pal.bg
                            }
                        }
                        FIcon {
                            visible: !sw.pal
                            icon: "image"
                            size: 28
                            color: Theme.textDim
                        }
                    }

                    FText {
                        x: 14
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 12
                        text: Palettes.labels[sw.modelData] ?? sw.modelData
                        color: sw.pal ? sw.pal.text : Theme.text
                        font.weight: Font.DemiBold
                    }

                    FIcon {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 12
                        icon: "check_circle"
                        fill: 1
                        color: sw.pal ? sw.pal.accent : Theme.accent
                        scale: sw.sel ? 1 : 0
                        Behavior on scale { Anim { easing.bezierCurve: Theme.curves.springFast } }
                    }

                    MouseArea {
                        id: tap
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: page.a.palette = sw.modelData
                    }
                }
            }
        }

        FText {
            Layout.margins: 12
            Layout.topMargin: 0
            Layout.fillWidth: true
            visible: page.a.palette === "wallpaper" && !ColorGen.available
            text: ColorGen.busy ? "Generating colors from wallpaper…" : "Install matugen to generate colors from your wallpaper."
            dim: true
            wrapMode: Text.Wrap
        }
    }

    Group {
        title: "Accent"
        SettingRow {
            title: "Accent color"
            subtitle: page.a.accentOverride ? "Replaces the palette's accent everywhere" : "Using the palette's own accent"
            icon: "colors"
            RowLayout {
                spacing: 6
                Repeater {
                    model: page.accents
                    Rectangle {
                        required property string modelData
                        readonly property bool sel: page.a.accentOverride.toLowerCase() === modelData
                        width: 26; height: 26; radius: 13
                        color: modelData
                        border.width: sel ? 3 : 0
                        border.color: Theme.text
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: page.a.accentOverride = parent.modelData
                        }
                    }
                }
            }
        }
        SettingRow {
            title: "Custom accent"
            subtitle: "Any hex color"
            icon: "colorize"
            RowLayout {
                spacing: 8
                FTextField {
                    implicitWidth: 130
                    text: page.a.accentOverride
                    placeholder: "#rrggbb"
                    onAccepted: page.setAccent(text)
                    onEditingFinished: page.setAccent(text)
                }
                FButton {
                    text: "Use palette"
                    variant: "tonal"
                    disabled: page.a.accentOverride === ""
                    onClicked: page.a.accentOverride = ""
                }
            }
        }
    }

    Group {
        title: "Text"
        ColorChoiceRow {
            title: "Text color"
            subtitle: {
                const c = page.a.textColor;
                if (!c)
                    return "The palette's own";
                return Theme.contrast(Theme.text, Theme.bg) < 4.5 ? "Hard to read on this background: try a lighter or darker one" : "Text across the shell" + ((page.a.textColorApps ?? true) ? " and apps" : "") + "; dimmer text is mixed from it";
            }
            icon: "format_color_text"
            target: page.a
            key: "textColor"
            choices: [{ value: "", label: "Palette" }, { value: "accent", label: "Accent" }]
            swatches: ["#ffffff", "#f2ede4", "#ffd8a8", "#c8e6c9", "#b3d4ff", "#e1c8ff", "#1b1b1b"]
        }
        SwitchRow {
            visible: page.a.textColor !== ""
            title: "Apps use it too"
            subtitle: "Qt, GTK and the other apps App Theming colors (needs App Theming on)"
            icon: "format_paint"
            target: page.a
            key: "textColorApps"
        }
        ColorChoiceRow {
            title: "Text cursor"
            subtitle: "The blinking line where you type: in the shell, GTK apps and terminals (Qt apps draw it in the text color)"
            icon: "text_select_end"
            target: page.a
            key: "caretColor"
            choices: [{ value: "accent", label: "Accent" }, { value: "text", label: "Text" }]
        }
    }

    Group {
        title: "Layout presets"
        FText {
            Layout.fillWidth: true
            Layout.margins: 12
            text: "Sets up the bar, dock, launcher and notifications in one go. You can still change each part afterwards."
            dim: true
            wrapMode: Text.Wrap
        }
        GridLayout {
            Layout.fillWidth: true
            Layout.margins: 12
            Layout.topMargin: 0
            columns: 3
            rowSpacing: 10
            columnSpacing: 10
            Repeater {
                model: page.presets
                Rectangle {
                    id: pr
                    required property var modelData
                    readonly property bool sel: page.a.layoutPreset === modelData.id
                    Layout.fillWidth: true
                    implicitHeight: 76
                    radius: Theme.rLg
                    color: sel ? Theme.alpha(Theme.accent, 0.14) : Theme.surfaceHigh
                    border.width: sel ? 2 : 1
                    border.color: sel ? Theme.accent : Theme.border
                    Column {
                        x: 12
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 24
                        spacing: 2
                        Row {
                            spacing: 8
                            FIcon { icon: pr.modelData.icon; color: pr.sel ? Theme.accent : Theme.textDim }
                            FText { text: pr.modelData.label; font.weight: Font.DemiBold }
                        }
                        FText {
                            width: parent.width
                            text: pr.modelData.hint
                            dim: true
                            font.pixelSize: Theme.fsSm
                            elide: Text.ElideRight
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: page.applyPreset(pr.modelData)
                    }
                }
            }
        }
    }

    Group {
        title: "Screen frame"
        SwitchRow { title: "Frame the screen"; subtitle: "A band in the bar's color around the screen's edges, rounding the desktop's corners (part of the Flamenco layout)"; icon: "crop_free"; target: page.a; key: "screenFrame" }
        SliderRow { visible: page.a.screenFrame; title: "Frame width"; icon: "border_outer"; target: page.a; key: "frameWidth"; from: 0; to: 24; stepSize: 1; suffix: " px" }
        SliderRow { visible: page.a.screenFrame; title: "Corner radius"; icon: "rounded_corner"; target: page.a; key: "frameRadius"; from: 0; to: 48; stepSize: 1; suffix: " px" }
    }

    Group {
        title: "Transparency"
        OpacityRow {
            title: "Whole UI"
            subtitle: "Scales every part below at once: lower to see more of the wallpaper through the shell"
            icon: "opacity"
            target: page.a
            key: "uiOpacity"
            from: 0.4
        }
        OpacityRow { title: "Panels"; subtitle: "Quick settings, the dashboard, launcher, volume, clipboard and the other panels"; icon: "dock_to_left"; target: page.a; key: "panelOpacity" }
        OpacityRow { title: "Bar"; subtitle: "And the screen frame"; icon: "toolbar"; target: page.a; key: "barOpacity"; follows: true; from: 0 }
        OpacityRow { title: "Notifications & pop-ups"; subtitle: "Notification pop-ups, the volume / brightness OSD, tray and window menus"; icon: "notifications"; target: page.a; key: "popupOpacity"; follows: true }
        OpacityRow { title: "Switchers & overview"; subtitle: "The app switcher, the overview and the wallpaper switcher"; icon: "select_window"; target: page.a; key: "switcherOpacity"; follows: true }
        OpacityRow { title: "Dock"; subtitle: "On top of the panels' opacity"; icon: "dock_to_bottom"; target: Settings.data.dock; key: "opacity"; from: 0 }
        OpacityRow { title: "Desktop widgets"; subtitle: "Their cards (glass and card styles)"; icon: "widgets"; target: Settings.data.desktop; key: "opacity"; from: 0 }
        OpacityRow { title: "Settings window"; icon: "settings"; target: page.a; key: "settingsOpacity"; from: 0.5 }
        SwitchRow {
            title: "Blur behind"
            subtitle: Niri.hyprland ? "Blurs what's behind the see-through parts (Hyprland layer blur; costs some GPU)" : "Hyprland only: niri doesn't blur behind other programs' surfaces yet"
            icon: "blur_on"
            enabled: Niri.hyprland
            opacity: enabled ? 1 : 0.5
            target: page.a
            key: "blur"
        }
        SettingRow {
            title: "Reset transparency"
            subtitle: "Every slider above back to its default"
            icon: "format_color_reset"
            FButton {
                text: "Reset"
                variant: "text"
                onClicked: {
                    page.a.uiOpacity = 1;
                    page.a.panelOpacity = 0.94;
                    page.a.barOpacity = -1;
                    page.a.popupOpacity = -1;
                    page.a.switcherOpacity = -1;
                    page.a.settingsOpacity = 1;
                    Settings.data.dock.opacity = 1;
                    Settings.data.desktop.opacity = 0.8;
                }
            }
        }
    }

    Group {
        title: "Shape & surfaces"
        ChoiceRow {
            title: "Surface finish"
            subtitle: page.a.finish === "gloss" ? "Glassy highlights, like Frutiger Aero" : page.a.finish === "chrome" ? "Metallic bands and an iridescent sheen, like Y2K"
                : page.a.finish === "liquid" ? "Layered glass: a soft sheen, a light rim and depth (best with see-through panels, Transparency)" : "Plain surfaces"
            icon: "texture"
            target: page.a
            key: "finish"
            segWidth: 100
            options: [{ value: "flat", label: "Flat" }, { value: "gloss", label: "Gloss" }, { value: "chrome", label: "Chrome" }, { value: "liquid", label: "Liquid glass" }]
        }
        SliderRow { title: "Corner roundness"; icon: "rounded_corner"; target: page.a; key: "roundness"; from: 0; to: 1.6; factor: 100; suffix: "%" }
        SwitchRow { title: "Drop shadows"; icon: "shadow"; target: page.a; key: "shadows" }
        SwitchRow { title: "Dim screen behind panels"; icon: "gradient"; target: page.a; key: "dimBehindPanels" }
        SwitchRow {
            title: "Connect panels to the bar"
            subtitle: Settings.data.bar.style === "islands" ? "Not with the Islands bar style, which has no bar to connect to" : "Quick settings, the calendar and other panels grow out of the bar as one surface, with no gap showing the wallpaper"
            icon: "join"
            target: page.a
            key: "blendPanels"
        }
    }

    Group {
        title: "Motion"
        SliderRow { title: "Animation speed"; subtitle: "0% turns animations off"; icon: "animation"; target: page.a; key: "animSpeed"; from: 0; to: 2; stepSize: 0.05; factor: 100; suffix: "%" }
        ChoiceRow {
            title: "Style"
            subtitle: page.a.motionStyle === "smooth" ? "Gentle easing, nothing overshoots" : page.a.motionStyle === "snappy" ? "Quick and crisp" : page.a.motionStyle === "minimal" ? "Short and plain, no hover zoom" : "Springy, with a little bounce (Material 3 Expressive)"
            icon: "motion_mode"
            target: page.a
            key: "motionStyle"
            options: [{ value: "expressive", label: "Expressive" }, { value: "smooth", label: "Smooth" }, { value: "snappy", label: "Snappy" }, { value: "minimal", label: "Minimal" }]
        }
        ChoiceRow {
            title: "Panels open with"
            subtitle: "Quick settings, the calendar, the launcher and the other panels"
            icon: "open_in_full"
            target: page.a
            key: "panelEffect"
            options: [{ value: "rise", label: "Rise" }, { value: "fade", label: "Fade" }, { value: "slide", label: "Slide" }, { value: "zoom", label: "Zoom" }, { value: "none", label: "None" }]
        }
        ChoiceRow {
            title: "Notifications arrive with"
            icon: "notifications"
            target: page.a
            key: "notifEffect"
            options: [{ value: "slide", label: "Slide" }, { value: "fade", label: "Fade" }, { value: "pop", label: "Pop" }]
        }
        SwitchRow { title: "Ripple where you click"; icon: "touch_app"; target: page.a; key: "ripple" }
        SwitchRow { title: "Grow under the pointer"; subtitle: "Workspace dots, launcher icons…"; icon: "zoom_in"; target: page.a; key: "hoverZoom" }
        SettingRow {
            title: "Speed of each part"
            subtitle: "On top of the overall speed. Off removes that part's animations."
            icon: "speed"
        }
        Repeater {
            model: [{ k: "panels", label: "Panels", icon: "dashboard" }, { k: "notifications", label: "Notifications", icon: "notifications" },
                { k: "bar", label: "Bar (appearing at login)", icon: "toolbar" }, { k: "workspaces", label: "Workspace indicator", icon: "view_week" },
                { k: "dock", label: "Dock (showing and hiding)", icon: "dock_to_bottom" }, { k: "launcher", label: "Launcher results", icon: "apps" },
                { k: "lock", label: "Lock screen", icon: "lock" }]
            SettingRow {
                id: ar
                required property var modelData
                readonly property real v: Theme.areaSpeed(modelData.k)
                title: modelData.label
                subtitle: v <= 0 ? "Off" : v === 1 ? "Normal" : Math.round(v * 100) + "%"
                icon: modelData.icon
                FSlider {
                    width: 220
                    from: 0
                    to: 2
                    stepSize: 0.1
                    value: ar.v
                    onMoved: val => {
                        const all = Object.assign({}, page.a.motionAreas || {});
                        all[ar.modelData.k] = Math.round(val * 10) / 10;
                        page.a.motionAreas = all;
                    }
                }
            }
        }
        SettingRow {
            title: "Try it"
            subtitle: "Opens quick settings with these settings"
            icon: "play_circle"
            FButton {
                text: "Preview"
                variant: "tonal"
                onClicked: Panels.toggle("control", "")
            }
        }
    }

    Group {
        title: "Login & logout"
        SettingRow {
            title: "Turning them on or off"
            subtitle: "The welcome and goodbye screens, niri's own logout, and the slide-in are in Lock & Login → Session"
            icon: "toggle_on"
            FButton {
                text: "Session settings"
                variant: "text"
                onClicked: Panels.findSetting("lock", "Session")
            }
        }

        DropdownRow {
            title: "When you log in"
            subtitle: "Plays when niri starts the shell (not on restarts)"
            icon: "login"
            target: Settings.data.session
            key: "intro"
            options: [
                { value: "bloom", label: "Bloom: opens from the center" },
                { value: "curtain", label: "Curtain: slides apart" },
                { value: "blinds", label: "Blinds: staggered slats" },
                { value: "zoom", label: "Zoom: flies in" },
                { value: "fade", label: "Fade" },
                { value: "none", label: "None" }
            ]
        }
        DropdownRow {
            title: "When you log out, restart or shut down"
            subtitle: "Plays after the power menu's countdown, before the action"
            icon: "logout"
            target: Settings.data.session
            key: "outro"
            options: [
                { value: "curtain", label: "Curtain: closes together" },
                { value: "bloom", label: "Bloom: closes in on the center" },
                { value: "blinds", label: "Blinds: staggered slats" },
                { value: "zoom", label: "Zoom" },
                { value: "fade", label: "Fade" },
                { value: "none", label: "None" }
            ]
        }
        SliderRow { title: "Duration"; icon: "timer"; target: Settings.data.session; key: "duration"; from: 400; to: 3000; stepSize: 100; suffix: " ms" }
        SwitchRow { title: "Greeting"; subtitle: "\"Good evening, you\" with the date, or \"See you soon\""; icon: "waving_hand"; target: Settings.data.session; key: "greeting" }
        SettingRow {
            title: "Preview"
            subtitle: "Plays the animation without logging you out"
            icon: "play_circle"
            Row {
                spacing: 6
                FButton { text: "Log in"; icon: "login"; variant: "tonal"; onClicked: SessionFx.playIntro(true) }
                FButton { text: "Log out"; icon: "logout"; variant: "tonal"; onClicked: SessionFx.playOutro("Logging out…", null, true) }
            }
        }
    }

    Group {
        title: "Typography"

        SettingRow {
            title: "Interface font"
            subtitle: Sounds.fonts.length ? Sounds.fonts.length + " fonts installed (system and ~/.local/share/fonts)" : "Loading installed fonts…"
            icon: "font_download"
            FDropdown {
                implicitWidth: 300
                fontPreview: true
                options: Sounds.fonts
                current: page.a.fontFamily
                placeholder: "Choose a font…"
                onSelected: v => page.a.fontFamily = v
            }
        }
        SettingRow {
            title: "Monospace font"
            subtitle: "Used for numbers, code and terminal-style text"
            icon: "code"
            FDropdown {
                implicitWidth: 300
                fontPreview: true
                options: Sounds.monoFonts.length ? Sounds.monoFonts : Sounds.fonts
                current: page.a.monoFamily
                placeholder: "Choose a font…"
                onSelected: v => page.a.monoFamily = v
            }
        }
        SliderRow { title: "Scale"; icon: "format_size"; target: page.a; key: "uiScale"; from: 0.8; to: 1.4; stepSize: 0.05; factor: 100; suffix: "%" }
        DropdownRow {
            title: "UI icons"
            subtitle: (page.a.uiIcons || "flamenco") === "flamenco" ? "Flamenco's own (Material Symbols) in the bar, quick settings, Settings and everywhere else"
                : UiIcons.loading ? "Looking up " + UiIcons.theme + "'s icons…"
                : UiIcons.theme === "" ? "Flamenco's own until an icon theme is picked for apps (App Theming → Icon theme, or Settings → Get themes)"
                : !UiIcons.loading && UiIcons.count === 0 ? UiIcons.theme + " has none of the icons the shell uses, so they stay Flamenco's"
                : UiIcons.count + " of the shell's icons come from " + UiIcons.theme + "; the rest stay Flamenco's. Back to Flamenco to undo"
            icon: "category"
            target: page.a
            key: "uiIcons"
            options: [{ value: "flamenco", label: "Flamenco (built in)" }, { value: "apps", label: "Same as apps" + (Settings.data.apps.iconTheme ? " (" + Settings.data.apps.iconTheme + ")" : "") }]
                .concat((AppTheming.installed.icons || []).filter(t => t.value))
            Component.onCompleted: AppTheming.refreshInstalled()
        }
        ChoiceRow {
            title: "Icons"
            subtitle: (page.a.uiIcons || "flamenco") === "flamenco" ? "Material Symbols. Filled is the newer Material 3 look; outlined fills only what's active." : "For Flamenco's own icons (the ones the icon theme doesn't have)"
            icon: "interests"
            target: page.a
            key: "iconStyle"
            options: [{ value: "filled", label: "Filled" }, { value: "outlined", label: "Outlined" }]
        }
        SliderRow { title: "Icon weight"; subtitle: "How thick icon strokes are"; icon: "line_weight"; target: page.a; key: "iconWeight"; from: 300; to: 700; stepSize: 100 }

        // live preview
        Rectangle {
            Layout.fillWidth: true
            Layout.margins: 12
            implicitHeight: preview.implicitHeight + 28
            radius: Theme.rMd
            color: Theme.bg
            ColumnLayout {
                id: preview
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 14
                spacing: 4
                FText { text: "The quick brown fox jumps over the lazy dog"; font.pixelSize: Theme.fsXl; font.weight: Font.Bold }
                FText { text: "Flamenco Shell · interface text at " + Theme.fsMd + " px"; dim: true }
                FText { text: "0123456789  {} => monospace"; mono: true }
            }
        }
        FText {
            Layout.fillWidth: true
            Layout.leftMargin: 12
            Layout.bottomMargin: 8
            text: "Qt and GTK apps get the same fonts when \"Sync fonts\" is on in App Theming."
            dim: true
            wrapMode: Text.Wrap
            font.pixelSize: Theme.fsSm
        }
    }
}
