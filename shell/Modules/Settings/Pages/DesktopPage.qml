import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: I18n.tr("Desktop widgets")
    subtitle: I18n.tr("Clocks, weather, system stats, media, a calendar and notes on the desktop, above the wallpaper and under your windows.")
    readonly property var d: Settings.data.desktop

    Group {
        SwitchRow { title: I18n.tr("Show desktop widgets"); icon: "widgets"; target: page.d; key: "enabled" }
        SwitchRow { title: I18n.tr("Right-click menu on the desktop"); subtitle: I18n.tr("Wallpaper, widgets, a terminal, settings"); icon: "ads_click"; target: page.d; key: "menu" }
        SettingRow {
            title: I18n.tr("Arrange widgets")
            subtitle: I18n.tr("Opens the widget sidebar on the desktop: drag widgets in, move, resize or remove them. Also in quick settings.")
            icon: "dashboard_customize"
            FButton {
                text: I18n.tr("Edit desktop")
                icon: "edit"
                variant: "tonal"
                onClicked: {
                    page.d.enabled = true;
                    Panels.settingsOpen = false;
                    Panels.editWidgets("");
                }
            }
        }
    }

    Group {
        title: I18n.tr("Look")
        ChoiceRow {
            title: I18n.tr("Style")
            subtitle: page.d.style === "bare" ? I18n.tr("Straight on the wallpaper, with a soft shadow") : page.d.style === "glass" ? I18n.tr("See-through, tinted with the palette") : I18n.tr("Solid cards in the palette's colors")
            icon: "style"
            target: page.d
            key: "style"
            options: [{ value: "card", label: I18n.tr("Card") }, { value: "glass", label: I18n.tr("Glass") }, { value: "bare", label: I18n.tr("Bare") }]
        }
        SliderRow { visible: page.d.style !== "bare"; title: I18n.tr("Background opacity"); icon: "opacity"; target: page.d; key: "opacity"; from: 0.2; to: 1; stepSize: 0.05; factor: 100; suffix: "%" }
    }

    Group {
        title: I18n.tr("On the desktop")
        SettingRow {
            visible: page.d.widgets.length === 0
            title: I18n.tr("No widgets yet")
            subtitle: I18n.tr("Use Edit desktop above, or quick settings → Desktop widgets")
            icon: "info"
        }
        Repeater {
            model: page.d.widgets
            SettingRow {
                required property var modelData
                readonly property var info: Desk.info(modelData.type)
                title: info.name
                subtitle: (Quickshell.screens.some(s => s.name === modelData.screen) ? modelData.screen : modelData.screen + " (not connected, shown on the first screen)") + " · " + ({ s: "small", m: "medium", l: "large" })[modelData.size || "m"]
                icon: info.icon
                FIconButton {
                    icon: "delete"
                    size: 32
                    iconColor: Theme.error
                    onClicked: Desk.remove(modelData.id)
                }
            }
        }
    }

    Group {
        title: I18n.tr("Dynamic island")
        SwitchRow { title: I18n.tr("Dynamic island"); subtitle: I18n.tr("A pill at the top that shows what's playing and grows for notifications and volume or brightness changes"); icon: "pill"; target: Settings.data.island; key: "enabled" }
        ChoiceRow {
            visible: Settings.data.island.enabled
            title: I18n.tr("Where")
            subtitle: Settings.data.island.place === "bar" ? I18n.tr("In the bar: add \"Dynamic island\" to a section in Bar settings (it's added to the center if it isn't there)") : I18n.tr("Its own spot on the screen")
            icon: "pill"
            target: Settings.data.island
            key: "place"
            segWidth: 110
            options: [{ value: "float", label: I18n.tr("Floating") }, { value: "bar", label: I18n.tr("In the bar") }]
            onEdited: {
                const b = Settings.data.bar;
                if (Settings.data.island.place === "bar" && !["left", "center", "right"].some(k => (b[k] || []).includes("island")))
                    b.center = ["island"].concat(b.center || []);
            }
        }
        ChoiceRow {
            visible: Settings.data.island.enabled && Settings.data.island.place !== "bar"
            title: I18n.tr("Position")
            icon: "picture_in_picture"
            target: Settings.data.island
            key: "position"
            segWidth: 64
            options: [{ value: "top-left", label: "↖" }, { value: "top-center", label: "↑" }, { value: "top-right", label: "↗" }, { value: "bottom-left", label: "↙" }, { value: "bottom-center", label: "↓" }, { value: "bottom-right", label: "↘" }]
        }
        SwitchRow { visible: Settings.data.island.enabled; title: I18n.tr("Lyrics"); subtitle: I18n.tr("The line being sung instead of the title, when the song has synced lyrics. Hover for the controls"); icon: "lyrics"; target: Settings.data.island; key: "lyrics" }
        SwitchRow { visible: Settings.data.island.enabled; title: I18n.tr("What's playing"); icon: "music_note"; target: Settings.data.island; key: "media" }
        SwitchRow { visible: Settings.data.island.enabled; title: I18n.tr("Notifications"); subtitle: I18n.tr("Turn off notification pop-ups in Notifications if you only want them here"); icon: "notifications"; target: Settings.data.island; key: "notifications" }
        SwitchRow { visible: Settings.data.island.enabled; title: I18n.tr("Volume and brightness"); subtitle: I18n.tr("Turn off the OSD (Sound) if you only want them here"); icon: "volume_up"; target: Settings.data.island; key: "levels" }
        SwitchRow { visible: Settings.data.island.enabled; title: I18n.tr("Always there"); subtitle: I18n.tr("Off: only while it has something to show"); icon: "visibility"; target: Settings.data.island; key: "idle" }
    }
}
