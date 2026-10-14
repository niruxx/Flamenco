import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: "Lock & Login"
    subtitle: "The lock screen, locking when idle, and the login screen you see at boot (greetd)."
    readonly property var l: Settings.data.lock
    readonly property var sddmOptions: [{ value: "", label: "Select a theme…" }].concat(AppTheming.installed.sddm.map(t => ({ value: t.path, label: t.label })))

    Component.onCompleted: AppTheming.refreshInstalled()

    Group {
        title: "Lock screen"
        ChoiceRow {
            title: "Lock screen"
            subtitle: "What locks your session (idle timeout, Super+Alt+L, power menu)"
            icon: "lock"
            target: page.l
            key: "backend"
            segWidth: 112
            options: [{ value: "flamenco", label: "Flamenco" }, { value: "sddm", label: "SDDM theme" }, { value: "command", label: "Command" }]
        }

        DropdownRow {
            visible: page.l.backend === "sddm"
            title: "SDDM theme"
            subtitle: AppTheming.installed.sddm.length ? "Installed greeter themes (/usr/share/sddm/themes, ~/.local/share/sddm/themes)" : "No SDDM themes found. Install one, or point to a folder below."
            icon: "palette"
            target: page.l
            key: "sddmTheme"
            options: page.sddmOptions
        }
        TextRow {
            visible: page.l.backend === "sddm"
            title: "Theme folder"
            subtitle: "Any folder with an SDDM theme (metadata.desktop + Main.qml). Overrides the dropdown."
            icon: "folder"
            target: page.l
            key: "sddmThemePath"
            placeholder: "~/Downloads/my-sddm-theme"
        }
        SettingRow {
            visible: page.l.backend === "sddm"
            title: "If a theme won't unlock"
            subtitle: "Press Ctrl+Alt+Shift+L on the lock screen to switch to the Flamenco lock. Themes that fail to load fall back to it automatically."
            icon: "emergency_home"
        }

        TextRow {
            visible: page.l.backend === "command"
            title: "Lock command"
            subtitle: "Runs instead of the built-in lock, e.g. hyprlock or swaylock -f"
            icon: "terminal"
            target: page.l
            key: "command"
            placeholder: "hyprlock"
        }

        SettingRow {
            title: "Preview"
            subtitle: "Locks the screen now with the selected lock screen"
            icon: "visibility"
            FButton {
                text: "Lock now"
                icon: "lock"
                variant: "tonal"
                onClicked: Quickshell.execDetached([Paths.bin, "lock"])
            }
        }
    }

    Group {
        title: "Idle"
        SwitchRow { title: "Lock when idle"; icon: "lock_clock"; target: page.l; key: "autoLock" }
        SliderRow { title: "Lock after"; icon: "timer"; target: page.l; key: "idleMinutes"; from: 1; to: 60; stepSize: 1; suffix: " min" }
        SliderRow { title: "Turn screens off after"; subtitle: "0 disables"; icon: "monitor"; target: page.l; key: "screenOffMinutes"; from: 0; to: 90; stepSize: 1; suffix: " min" }
        SwitchRow { title: "Media controls on lock screen"; icon: "music_note"; target: page.l; key: "showMedia" }
        TextRow { title: "Avatar image"; icon: "account_circle"; target: Settings.data.general; key: "avatar"; placeholder: "~/.face" }
    }

    LoginSection {}

    Group {
        title: "Night light"
        SwitchRow { title: "Night light"; subtitle: "Uses gammastep"; icon: "nightlight"; target: Settings.data.night; key: "enabled" }
        SliderRow { title: "Temperature"; icon: "thermostat"; target: Settings.data.night; key: "temperature"; from: 2500; to: 6000; stepSize: 100; suffix: "K" }
    }
}
