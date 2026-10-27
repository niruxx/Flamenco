import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: "Desktop widgets"
    subtitle: "Clocks, weather, system stats, media, a calendar and notes on the desktop, above the wallpaper and under your windows."
    readonly property var d: Settings.data.desktop

    Group {
        SwitchRow { title: "Show desktop widgets"; icon: "widgets"; target: page.d; key: "enabled" }
        SwitchRow { title: "Right-click menu on the desktop"; subtitle: "Wallpaper, widgets, a terminal, settings"; icon: "ads_click"; target: page.d; key: "menu" }
        SettingRow {
            title: "Arrange widgets"
            subtitle: "Opens the widget sidebar on the desktop: drag widgets in, move, resize or remove them. Also in quick settings."
            icon: "dashboard_customize"
            FButton {
                text: "Edit desktop"
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
        title: "Look"
        ChoiceRow {
            title: "Style"
            subtitle: page.d.style === "bare" ? "Straight on the wallpaper, with a soft shadow" : page.d.style === "glass" ? "See-through, tinted with the palette" : "Solid cards in the palette's colors"
            icon: "style"
            target: page.d
            key: "style"
            options: [{ value: "card", label: "Card" }, { value: "glass", label: "Glass" }, { value: "bare", label: "Bare" }]
        }
        SliderRow { visible: page.d.style !== "bare"; title: "Background opacity"; icon: "opacity"; target: page.d; key: "opacity"; from: 0.2; to: 1; stepSize: 0.05; factor: 100; suffix: "%" }
    }

    Group {
        title: "On the desktop"
        SettingRow {
            visible: page.d.widgets.length === 0
            title: "No widgets yet"
            subtitle: "Use Edit desktop above, or quick settings → Desktop widgets"
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
        title: "Dynamic island"
        SwitchRow { title: "Dynamic island"; subtitle: "A pill at the top that shows what's playing and grows for notifications and volume or brightness changes"; icon: "pill"; target: Settings.data.island; key: "enabled" }
        ChoiceRow {
            visible: Settings.data.island.enabled
            title: "Where"
            subtitle: Settings.data.island.place === "bar" ? "In the bar: add \"Dynamic island\" to a section in Bar settings (it's added to the center if it isn't there)" : "Its own spot on the screen"
            icon: "pill"
            target: Settings.data.island
            key: "place"
            segWidth: 110
            options: [{ value: "float", label: "Floating" }, { value: "bar", label: "In the bar" }]
            onEdited: {
                const b = Settings.data.bar;
                if (Settings.data.island.place === "bar" && !["left", "center", "right"].some(k => (b[k] || []).includes("island")))
                    b.center = ["island"].concat(b.center || []);
            }
        }
        ChoiceRow {
            visible: Settings.data.island.enabled && Settings.data.island.place !== "bar"
            title: "Position"
            icon: "picture_in_picture"
            target: Settings.data.island
            key: "position"
            segWidth: 64
            options: [{ value: "top-left", label: "↖" }, { value: "top-center", label: "↑" }, { value: "top-right", label: "↗" }, { value: "bottom-left", label: "↙" }, { value: "bottom-center", label: "↓" }, { value: "bottom-right", label: "↘" }]
        }
        SwitchRow { visible: Settings.data.island.enabled; title: "Lyrics"; subtitle: "The line being sung instead of the title, when the song has synced lyrics. Hover for the controls"; icon: "lyrics"; target: Settings.data.island; key: "lyrics" }
        SwitchRow { visible: Settings.data.island.enabled; title: "What's playing"; icon: "music_note"; target: Settings.data.island; key: "media" }
        SwitchRow { visible: Settings.data.island.enabled; title: "Notifications"; subtitle: "Turn off notification pop-ups in Notifications if you only want them here"; icon: "notifications"; target: Settings.data.island; key: "notifications" }
        SwitchRow { visible: Settings.data.island.enabled; title: "Volume and brightness"; subtitle: "Turn off the OSD (Sound) if you only want them here"; icon: "volume_up"; target: Settings.data.island; key: "levels" }
        SwitchRow { visible: Settings.data.island.enabled; title: "Always there"; subtitle: "Off: only while it has something to show"; icon: "visibility"; target: Settings.data.island; key: "idle" }
    }
}
