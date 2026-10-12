import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: "App Theming"
    subtitle: "Style Qt and GTK applications with the shell palette. Flamenco writes qt5ct/qt6ct color schemes and stylesheets, a KDE color scheme, and GTK 3/4 CSS. Your own files are backed up before the first change."
    readonly property var o: Settings.data.apps
    readonly property var inst: AppTheming.installed
    readonly property var keep: [{ value: "", label: "Leave unchanged" }]

    Component.onCompleted: AppTheming.refreshInstalled()

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.sp3
        FButton {
            text: AppTheming.busy ? "Applying…" : "Apply now"
            icon: "format_paint"
            onClicked: AppTheming.apply()
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
            title: AppTheming.scanning ? "Scanning installed themes…" : "Installed themes"
            subtitle: page.inst.icons.length + " icon · " + page.inst.cursors.length + " cursor · " + page.inst.gtk.length + " GTK · " + page.inst.qtStyles.length + " Qt styles"
            icon: "inventory_2"
            FIconButton { icon: "refresh"; onClicked: AppTheming.refreshInstalled() }
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
