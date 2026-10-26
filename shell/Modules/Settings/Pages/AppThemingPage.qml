import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: "App Theming"
    subtitle: "Style Qt and GTK applications, terminals and more with the shell palette. Flamenco writes qt5ct/qt6ct color schemes and stylesheets, a KDE color scheme, GTK 3/4 CSS, and color files for the other apps you pick. Your own files are backed up before the first change."
    readonly property var o: Settings.data.apps
    readonly property var inst: AppTheming.installed
    readonly property var keep: [{ value: "", label: "Leave unchanged" }]

    Component.onCompleted: AppTheming.refreshInstalled()

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.sp3
        FButton {
            text: AppTheming.busy ? "Applying…" : AppTheming.following ? "Apply now" : "Use Flamenco's colors"
            icon: "format_paint"
            onClicked: AppTheming.following ? AppTheming.apply() : AppTheming.useScheme("flamenco")
        }
        FButton {
            text: "Restore originals"
            icon: "undo"
            variant: "outlined"
            onClicked: Quickshell.execDetached([Paths.bin, "apps-theme", "--restore"])
        }
        FText {
            Layout.fillWidth: true
            text: AppTheming.lastStatus
            dim: true
            elide: Text.ElideRight
        }
    }

    // ── which look apps get: the shell's, or a desktop's own defaults ──
    Group {
        title: "Color scheme"
        Item {
            Layout.fillWidth: true
            Layout.margins: Theme.sp3
            implicitHeight: schemes.implicitHeight
            Flow {
                id: schemes
                width: parent.width
                spacing: Theme.sp2
                readonly property real tileW: (width - spacing * 2) / 3
                Repeater {
                    model: [
                        { value: "flamenco", label: "Flamenco", hint: "Your shell palette in every app", swatch: [Theme.bg, Theme.surfaceHigh, Theme.accent, Theme.accent2] },
                        { value: "gnome", label: "GNOME defaults", hint: "Adwaita, GNOME's fonts, no color scheme", swatch: ["#fafafb", "#ebebed", "#3584e4", "#241f31"] },
                        { value: "kde", label: "KDE defaults", hint: "Breeze colors, style and icons", swatch: ["#eff0f1", "#fcfcfc", "#3daee9", "#232629"] }
                    ]
                    Rectangle {
                        id: stile
                        required property var modelData
                        readonly property bool on: (page.o.scheme || "flamenco") === modelData.value
                        width: Math.max(160, schemes.tileW)
                        height: 108
                        radius: Theme.rLg
                        color: on ? Theme.alpha(Theme.accent, 0.14) : Theme.alpha(Theme.text, 0.04)
                        border.width: on ? 2 : 1
                        border.color: on ? Theme.accent : Theme.alpha(Theme.text, 0.08)
                        Row {
                            x: 12
                            y: 12
                            spacing: 4
                            Repeater {
                                model: stile.modelData.swatch
                                Rectangle {
                                    required property color modelData
                                    width: 26
                                    height: 26
                                    radius: 8
                                    color: modelData
                                    border.width: 1
                                    border.color: Theme.alpha(Theme.text, 0.12)
                                }
                            }
                        }
                        Column {
                            x: 12
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 10
                            width: parent.width - 24
                            FText { text: stile.modelData.label; font.weight: Font.Bold; color: stile.on ? Theme.accent : Theme.text }
                            FText { width: parent.width; text: stile.modelData.hint; dim: true; font.pixelSize: Theme.fsXs; elide: Text.ElideRight }
                        }
                        StateLayer {
                            radius: parent.radius
                            onClicked: if (!stile.on) AppTheming.useScheme(stile.modelData.value)
                        }
                    }
                }
            }
        }
        SettingRow {
            title: AppTheming.following ? "Using another desktop too?" : "Apps use " + (page.o.scheme === "kde" ? "KDE's" : "GNOME's") + " defaults"
            subtitle: AppTheming.following
                ? "Before switching to GNOME or Plasma, pick its defaults here: Flamenco's colors come out of GTK, GNOME and KDE settings (your own files from before Flamenco come back), so the other desktop and its tools (GNOME Tweaks, System Settings) work as usual. Pick Flamenco again when you're back."
                : "Flamenco won't re-theme apps until you pick Flamenco again. Restart open apps to see the change."
            icon: AppTheming.following ? "swap_horiz" : "check_circle"
        }
    }

    // live preview of the generated widget style
    Group {
        title: "Preview"
        Rectangle {
            Layout.fillWidth: true
            Layout.margins: 12
            implicitHeight: 150
            radius: page.o.matchRoundness ? Theme.rSm : page.o.radius
            color: Theme.bg
            border.width: 1
            border.color: Theme.border

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                RowLayout {
                    spacing: 10
                    readonly property int r: page.o.matchRoundness ? Theme.rSm : page.o.radius
                    Repeater {
                        model: ["Default", "Primary"]
                        Rectangle {
                            required property string modelData
                            required property int index
                            implicitWidth: 110
                            implicitHeight: 34
                            radius: parent.r
                            color: index === 1 ? Theme.accent : page.o.buttons === "flat" ? "transparent" : page.o.buttons === "outlined" ? "transparent" : Theme.surfaceHighest
                            border.width: page.o.buttons === "outlined" || page.o.buttons === "flat" && index === 0 ? 1 : 0
                            border.color: Theme.border
                            FText { anchors.centerIn: parent; text: modelData; color: index === 1 ? Theme.onAccent : Theme.text }
                        }
                    }
                    Rectangle {
                        implicitWidth: 200
                        implicitHeight: 34
                        radius: parent.r
                        color: Theme.surface
                        border.width: 2
                        border.color: page.o.accentSelection ? Theme.accent : Theme.border
                        FText { anchors.verticalCenter: parent.verticalCenter; x: 10; text: "Text field"; dim: true }
                    }
                }
                RowLayout {
                    spacing: 10
                    FSwitch { checked: true }
                    FText { text: "Selection"; color: Theme.onAccent; Layout.preferredWidth: 90; horizontalAlignment: Text.AlignHCenter
                        Rectangle { z: -1; anchors.fill: parent; anchors.margins: -4; radius: 4; color: page.o.accentSelection ? Theme.accent : Theme.textDim }
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        implicitWidth: page.o.scrollbars === "classic" ? 12 : page.o.scrollbars === "thin" ? 6 : 4
                        implicitHeight: 60
                        radius: implicitWidth / 2
                        color: Theme.alpha(Theme.text, 0.35)
                    }
                }
            }
        }
    }

    Group {
        title: "General"
        SwitchRow { title: "Apply automatically"; subtitle: "Re-theme apps whenever the palette or these options change"; icon: "autorenew"; target: page.o; key: "autoApply" }
        SwitchRow { title: "Sync fonts"; subtitle: "Use the shell's interface and monospace fonts in apps"; icon: "font_download"; target: page.o; key: "syncFonts" }
        DropdownRow { title: "Icon theme"; subtitle: "Used by Qt and GTK apps"; icon: "category"; target: page.o; key: "iconTheme"; options: page.keep.concat(page.inst.icons) }
        DropdownRow { title: "Cursor theme"; icon: "arrow_selector_tool"; target: page.o; key: "cursorTheme"; options: page.keep.concat(page.inst.cursors) }
        SliderRow { visible: page.o.cursorTheme !== ""; title: "Cursor size"; icon: "straighten"; target: page.o; key: "cursorSize"; from: 16; to: 64; stepSize: 4; suffix: "px" }
        SettingRow {
            title: "Get more themes"
            subtitle: "Icon, cursor and GTK themes from the KDE Store, installed in one click"
            icon: "download"
            FButton {
                text: "Get themes"
                variant: "tonal"
                onClicked: Panels.settingsPage = "get"
            }
        }
        SettingRow {
            title: AppTheming.scanning ? "Scanning installed themes…" : "Installed themes"
            subtitle: page.inst.icons.length + " icon · " + page.inst.cursors.length + " cursor · " + page.inst.gtk.length + " GTK · " + page.inst.qtStyles.length + " Qt styles"
            icon: "inventory_2"
            FIconButton { icon: "refresh"; onClicked: AppTheming.refreshInstalled() }
        }
    }

    Group {
        title: "Other apps"
        SettingRow {
            title: "Terminals, launchers, browsers and more"
            subtitle: "Each one gets a color file from your palette, plus one marked line in its own config to load it. Restore originals undoes both."
            icon: "palette"
        }
        Repeater {
            model: [
                { id: "kitty", name: "kitty", icon: "terminal", note: "Reloads open windows" },
                { id: "ghostty", name: "Ghostty", icon: "terminal", note: "Reloads open windows; replaces its theme line (kept as a comment)" },
                { id: "alacritty", name: "Alacritty", icon: "terminal", note: "Imports flamenco.toml; reloads by itself" },
                { id: "foot", name: "foot", icon: "terminal", note: "New windows" },
                { id: "fuzzel", name: "fuzzel", icon: "search", note: "" },
                { id: "pywalfox", name: "Firefox (pywalfox)", icon: "public", note: "Needs the pywalfox add-on and package; writes ~/.cache/wal/colors.json" },
                { id: "vesktop", name: "Discord (Vesktop / Vencord)", icon: "forum", note: "Then turn on Flamenco under Vencord → Themes" },
                { id: "spicetify", name: "Spotify (spicetify)", icon: "music_note", note: "Runs spicetify apply" },
                { id: "vscode", name: "VS Code / VSCodium", icon: "code", note: "Then pick the Flamenco color theme" }
            ]
            SettingRow {
                id: appRow
                required property var modelData
                readonly property bool here: !!(page.inst.apps ?? {})[modelData.id]
                title: modelData.name
                subtitle: (here ? "" : "Not installed. ") + modelData.note
                icon: modelData.icon
                opacity: here ? 1 : 0.6
                FSwitch {
                    checked: !!(page.o.extraApps ?? {})[appRow.modelData.id]
                    onToggled: c => {
                        const all = Object.assign({}, page.o.extraApps || {});
                        all[appRow.modelData.id] = c;
                        page.o.extraApps = all;
                    }
                }
            }
        }
    }

    Group {
        title: "Stylesheet options (Qt + GTK)"
        SwitchRow { title: "Match shell roundness"; icon: "rounded_corner"; target: page.o; key: "matchRoundness" }
        SliderRow { visible: !page.o.matchRoundness; title: "Widget corner radius"; icon: "crop_square"; target: page.o; key: "radius"; from: 0; to: 20; stepSize: 1; suffix: "px" }
        ChoiceRow {
            title: "Buttons"
            icon: "smart_button"
            target: page.o
            key: "buttons"
            options: [{ value: "soft", label: "Soft" }, { value: "flat", label: "Flat" }, { value: "outlined", label: "Outlined" }]
        }
        ChoiceRow {
            title: "Scrollbars"
            icon: "swap_vert"
            target: page.o
            key: "scrollbars"
            options: [{ value: "thin", label: "Thin" }, { value: "overlay", label: "Overlay" }, { value: "classic", label: "Classic" }]
        }
        SwitchRow { title: "Accent selections & focus rings"; icon: "highlight"; target: page.o; key: "accentSelection" }
        SliderRow { title: "Surface contrast"; subtitle: "Separation between window, view and card backgrounds"; icon: "contrast"; target: page.o; key: "contrast"; from: -1; to: 1; stepSize: 0.1; decimals: 1 }
    }

    Group {
        title: "Qt applications"
        SwitchRow { title: "Theme Qt apps"; subtitle: "Writes qt5ct + qt6ct configs. Requires QT_QPA_PLATFORMTHEME=qt6ct (see `flamenco doctor`)."; icon: "widgets"; target: page.o; key: "qt" }
        DropdownRow {
            visible: page.o.qt
            title: "Widget style"
            subtitle: "Installed Qt 6 styles. Fusion takes the generated stylesheet best."
            icon: "style"
            target: page.o
            key: "qtStyle"
            options: page.inst.qtStyles
        }
        DropdownRow {
            visible: page.o.qt && page.o.qtStyle === "kvantum"
            title: "Kvantum theme"
            icon: "palette"
            target: page.o
            key: "kvantumTheme"
            placeholder: page.inst.kvantum.length ? "Select…" : "No Kvantum themes found"
            options: page.keep.concat(page.inst.kvantum)
        }
        SwitchRow { visible: page.o.qt; title: "Generated stylesheet (QSS)"; subtitle: "Rounded controls, accent focus, custom scrollbars"; icon: "css"; target: page.o; key: "qss" }
        SwitchRow { visible: page.o.qt; title: "KDE color scheme"; subtitle: "For KDE apps (Dolphin, Kate…) that read kdeglobals"; icon: "palette"; target: page.o; key: "kdeColors" }
    }

    Group {
        visible: page.o.qt
        title: "Custom QSS"
        CodeEditor {
            target: page.o
            key: "customQss"
            placeholder: "/* appended to the generated stylesheet */\nQPushButton { font-weight: 600; }"
        }
    }

    Group {
        title: "GTK applications"
        SwitchRow { title: "Theme GTK apps"; subtitle: "Writes ~/.config/gtk-3.0 and gtk-4.0 gtk.css and sets the dark/light preference"; icon: "widgets"; target: page.o; key: "gtk" }
        DropdownRow {
            visible: page.o.gtk
            title: "Base GTK theme"
            subtitle: "Automatic uses adw-gtk3 when installed so GTK 3 apps match libadwaita"
            icon: "web"
            target: page.o
            key: "gtkTheme"
            options: [{ value: "", label: "Automatic" }].concat(page.inst.gtk)
        }
        SwitchRow { visible: page.o.gtk; title: "GTK 3"; icon: "looks_3"; target: page.o; key: "gtk3" }
        SwitchRow { visible: page.o.gtk; title: "GTK 4 / libadwaita"; icon: "looks_4"; target: page.o; key: "gtk4" }
        SwitchRow { visible: page.o.gtk; title: "Extra styling"; subtitle: "Apply radius, button and scrollbar options, not just colors"; icon: "auto_awesome"; target: page.o; key: "gtkExtras" }
    }

    Group {
        visible: page.o.gtk
        title: "Custom GTK CSS"
        CodeEditor {
            target: page.o
            key: "customGtkCss"
            placeholder: "/* appended to gtk.css */\nheaderbar { min-height: 38px; }"
        }
    }
}
