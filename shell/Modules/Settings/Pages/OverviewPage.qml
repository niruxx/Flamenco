import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: "Overview"
    subtitle: "Flamenco's own overview, like GNOME's Activities: search apps, see this screen's workspaces and windows, and switch between them."
    readonly property var o: Settings.data.overview

    Group {
        title: "Overview"
        SwitchRow {
            title: "Flamenco overview"
            subtitle: "The start button opens it instead of the launcher (right-click the start button for the other one)"
            icon: "overview_key"
            target: page.o
            key: "enabled"
        }
        SettingRow {
            title: "Preview"
            icon: "visibility"
            FButton {
                text: "Open the overview"
                variant: "tonal"
                icon: "overview_key"
                onClicked: {
                    Panels.settingsOpen = false;
                    Panels.open("overview", "");
                }
            }
        }
    }

    Group {
        title: "Super key"
        visible: page.o.enabled
        SwitchRow {
            title: "Tap Super to open it"
            subtitle: "Press Super and let go without another key. Super with another key still works as a shortcut."
            icon: "keyboard_command_key"
            target: page.o
            key: "superKey"
        }
        SliderRow {
            visible: page.o.superKey
            title: "Longest tap"
            subtitle: "Holding Super longer than this doesn't open it"
            icon: "timer"
            target: page.o
            key: "superHold"
            from: 0.2
            to: 1.5
            stepSize: 0.1
            suffix: " s"
        }
        SettingRow {
            visible: page.o.superKey
            title: SuperKey.status === "ready" ? "Working" : SuperKey.status === "permission" ? "Needs keyboard access" : SuperKey.status === "no-keyboard" ? "No keyboard found" : SuperKey.status === "failed" ? "Stopped, restarting…" : "Starting…"
            subtitle: SuperKey.status === "permission"
                ? "niri and Hyprland run shortcuts as soon as a key goes down, so they can't tell Super alone from Super+T. Flamenco reads the keyboard itself for this, which needs the input group. Note that being in it lets any program you run read the keyboard."
                : SuperKey.status === "ready" ? "Tap Super to try it" : SuperKey.status === "no-keyboard" ? "Plug one in; it's picked up within a few seconds" : ""
            icon: SuperKey.status === "ready" ? "check_circle" : SuperKey.status === "permission" ? "lock" : "info"
            FButton {
                visible: SuperKey.status === "permission"
                text: "Join the input group"
                variant: "tonal"
                icon: "terminal"
                onClicked: Quickshell.execDetached(Paths.termHold('sudo usermod -aG input "$USER" && echo && echo "Done. Log out and back in for it to take effect."'))
            }
        }
    }

    Group {
        title: "Layout"
        visible: page.o.enabled
        SwitchRow { title: "Workspaces"; subtitle: "Along the top. Drop a window on one to move it there."; icon: "view_carousel"; target: page.o; key: "workspaces" }
        ChoiceRow {
            title: "Dash"
            subtitle: "Your dock's pinned apps and the running ones, along the bottom"
            icon: "dock_to_bottom"
            target: page.o
            key: "dash"
            segWidth: 140
            options: [{ value: "auto", label: "When no dock" }, { value: "always", label: "Always" }, { value: "never", label: "Never" }]
        }
        SwitchRow { title: "Window pictures"; subtitle: "Where the compositor lets Flamenco capture windows; app icons otherwise"; icon: "picture_in_picture"; target: page.o; key: "previews" }
        SwitchRow { title: "Blurred wallpaper"; subtitle: "Off: a plain dimmed background"; icon: "blur_on"; target: page.o; key: "blur" }
    }

    Group {
        title: "More ways to open it"
        SettingRow {
            title: "Start button"
            subtitle: "Its icon, label and what it opens are in Bar → Start button"
            icon: "toolbar"
            FButton {
                text: "Bar settings"
                variant: "text"
                onClicked: Panels.findSetting("bar", "Start button")
            }
        }
        SettingRow {
            title: "A shortcut or a screen corner"
            subtitle: "\"Overview (Flamenco)\" in Keyboard shortcuts and Screen edges. From a script: flamenco overview"
            icon: "keyboard"
        }
    }
}
