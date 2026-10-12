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
        title: "Shape & surfaces"
        SliderRow { title: "Corner roundness"; icon: "rounded_corner"; target: page.a; key: "roundness"; from: 0; to: 1.6; factor: 100; suffix: "%" }
        SliderRow { title: "Panel opacity"; icon: "opacity"; target: page.a; key: "panelOpacity"; from: 0.5; to: 1; factor: 100; suffix: "%" }
        SwitchRow { title: "Drop shadows"; icon: "shadow"; target: page.a; key: "shadows" }
        SwitchRow { title: "Dim screen behind panels"; icon: "gradient"; target: page.a; key: "dimBehindPanels" }
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
