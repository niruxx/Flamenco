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
        { id: "modern", label: "Modern", icon: "auto_awesome", hint: "Floating top bar, centered clock",
          bar: { position: "top", style: "floating", height: 40, workspaceStyle: "pills",
                 left: ["launcher", "workspaces", "window"], center: ["clock", "media"],
                 right: ["tray", "sysstats", "keyboard", "network", "bluetooth", "audio", "battery", "notifications", "quicksettings", "power"] },
          dock: { enabled: false }, launcher: { position: "center" }, notifications: { position: "top-right" } },
        { id: "minimal", label: "Minimal", icon: "remove", hint: "Slim islands, just the essentials",
          bar: { position: "top", style: "islands", height: 34, workspaceStyle: "dots",
                 left: ["workspaces"], center: ["clock"], right: ["tray", "network", "audio", "battery", "quicksettings"] },
          dock: { enabled: false }, launcher: { position: "center" }, notifications: { position: "top-center" } },
        { id: "classic", label: "Classic", icon: "desktop_windows", hint: "Taskbar at the bottom, Windows-style",
          bar: { position: "bottom", style: "attached", height: 44, workspaceStyle: "numbers",
                 left: ["launcher", "workspaces", "taskbar"], center: [],
                 right: ["tray", "keyboard", "network", "bluetooth", "audio", "battery", "clock", "notifications", "quicksettings"] },
          dock: { enabled: false }, launcher: { position: "bottom-left" }, notifications: { position: "bottom-right" } },
        { id: "mac", label: "Dock & menu bar", icon: "dock_to_bottom", hint: "Thin top bar and a dock, macOS-style",
          bar: { position: "top", style: "attached", height: 32, workspaceStyle: "pills",
                 left: ["launcher", "window"], center: [],
                 right: ["tray", "network", "bluetooth", "audio", "battery", "quicksettings", "clock", "notifications"] },
          dock: { enabled: true, autoHide: false, magnify: true }, launcher: { position: "center" }, notifications: { position: "top-right" } },
        { id: "vertical", label: "Vertical", icon: "side_navigation", hint: "Side bar, more room for windows",
          bar: { position: "left", style: "floating", height: 44, workspaceStyle: "pills",
                 left: ["launcher", "workspaces"], center: [],
                 right: ["tray", "network", "audio", "battery", "clock", "notifications", "quicksettings", "power"] },
          dock: { enabled: false }, launcher: { position: "bar" }, notifications: { position: "top-right" } }
    ]

    function applyPreset(p) {
        const d = Settings.data;
        for (const section of ["bar", "dock", "launcher", "notifications"])
            for (const k in p[section])
                d[section][k] = Array.isArray(p[section][k]) ? p[section][k].slice() : p[section][k];
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
        title: "Shape & surfaces"
        SliderRow { title: "Corner roundness"; icon: "rounded_corner"; target: page.a; key: "roundness"; from: 0; to: 1.6; factor: 100; suffix: "%" }
        SliderRow { title: "Panel opacity"; icon: "opacity"; target: page.a; key: "panelOpacity"; from: 0.5; to: 1; factor: 100; suffix: "%" }
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
    }

    Group {
        title: "Login & logout"

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
        ChoiceRow {
            title: "Icons"
            subtitle: "Material Symbols. Filled is the newer Material 3 look; outlined fills only what's active."
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
