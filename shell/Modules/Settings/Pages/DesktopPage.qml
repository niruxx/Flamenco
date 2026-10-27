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
}
