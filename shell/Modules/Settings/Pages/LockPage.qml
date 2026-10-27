import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: I18n.tr("Lock & Login")
    subtitle: I18n.tr("The lock screen, locking when idle, fingerprints, and the login screen you see at boot (greetd).")
    readonly property var l: Settings.data.lock
    readonly property var sddmOptions: [{ value: "", label: I18n.tr("Select a theme…") }].concat(AppTheming.installed.sddm.map(t => ({ value: t.path, label: t.label })))

    Component.onCompleted: AppTheming.refreshInstalled()

    Group {
        title: I18n.tr("Lock screen")
        ChoiceRow {
            title: I18n.tr("Lock screen")
            subtitle: I18n.tr("What locks your session (idle timeout, Super+Alt+L, power menu)")
            icon: "lock"
            target: page.l
            key: "backend"
            segWidth: 112
            options: [{ value: "flamenco", label: I18n.tr("Flamenco") }, { value: "sddm", label: I18n.tr("SDDM theme") }, { value: "command", label: I18n.tr("Command") }]
        }

        DropdownRow {
            visible: page.l.backend === "sddm"
            title: I18n.tr("SDDM theme")
            subtitle: AppTheming.installed.sddm.length ? I18n.tr("Installed greeter themes (/usr/share/sddm/themes, ~/.local/share/sddm/themes)") : I18n.tr("No SDDM themes found. Install one, or point to a folder below.")
            icon: "palette"
            target: page.l
            key: "sddmTheme"
            options: page.sddmOptions
        }
        TextRow {
            visible: page.l.backend === "sddm"
            title: I18n.tr("Theme folder")
            subtitle: I18n.tr("Any folder with an SDDM theme (metadata.desktop + Main.qml). Overrides the dropdown.")
            icon: "folder"
            target: page.l
            key: "sddmThemePath"
            placeholder: "~/Downloads/my-sddm-theme"
        }
        SettingRow {
            visible: page.l.backend === "sddm"
            title: I18n.tr("If a theme won't unlock")
            subtitle: I18n.tr("Press Ctrl+Alt+Shift+L on the lock screen to switch to the Flamenco lock. Themes that fail to load fall back to it automatically.")
            icon: "emergency_home"
        }

        TextRow {
            visible: page.l.backend === "command"
            title: I18n.tr("Lock command")
            subtitle: I18n.tr("Runs instead of the built-in lock, e.g. hyprlock or swaylock -f")
            icon: "terminal"
            target: page.l
            key: "command"
            placeholder: "hyprlock"
        }

        SettingRow {
            title: I18n.tr("Preview")
            subtitle: I18n.tr("Locks the screen now with the selected lock screen")
            icon: "visibility"
            FButton {
                text: I18n.tr("Lock now")
                icon: "lock"
                variant: "tonal"
                onClicked: Quickshell.execDetached([Paths.bin, "lock"])
            }
        }
    }

    Group {
        id: sess
        readonly property var c: Settings.data.session
        title: I18n.tr("Session")

        SwitchRow {
            title: I18n.tr("Welcome screen")
            subtitle: I18n.tr("A greeting with the date as you log in, then the desktop opens up (style in Appearance → Login & logout)")
            icon: "waving_hand"
            target: sess.c
            key: "welcome"
        }
        SwitchRow {
            title: I18n.tr("Goodbye screen")
            subtitle: I18n.tr("Covers the screen with \"See you soon\" before logging out, restarting or shutting down. Off: they happen straight away.")
            icon: "logout"
            target: sess.c
            key: "goodbye"
        }
        ChoiceRow {
            visible: !Niri.hyprland
            title: I18n.tr("Logging out")
            subtitle: sess.c.logout === "niri" ? "niri asks \"Exit niri?\" itself, with no goodbye screen first" : I18n.tr("Flamenco logs out right away (after the goodbye screen and the power menu's hold)")
            icon: "exit_to_app"
            target: sess.c
            key: "logout"
            segWidth: 130
            options: [{ value: "flamenco", label: I18n.tr("Flamenco") }, { value: "niri", label: I18n.tr("niri's own") }]
        }
        SwitchRow {
            title: I18n.tr("Slide in after logging in")
            subtitle: I18n.tr("The bar, then the dock, then desktop widgets glide into place")
            icon: "animation"
            target: sess.c
            key: "slideIn"
        }
        SliderRow { visible: sess.c.slideIn; title: I18n.tr("Slide speed"); subtitle: I18n.tr("How long each one takes"); icon: "speed"; target: sess.c; key: "slideDuration"; from: 200; to: 2500; stepSize: 50; suffix: " ms" }
        SliderRow { visible: sess.c.slideIn; title: I18n.tr("Gap between them"); subtitle: I18n.tr("0 slides them all at once"); icon: "timer"; target: sess.c; key: "slideStagger"; from: 0; to: 800; stepSize: 20; suffix: " ms" }
        SettingRow {
            title: I18n.tr("Preview")
            subtitle: I18n.tr("Plays it without logging out")
            icon: "play_circle"
            Row {
                spacing: 6
                FButton {
                    text: I18n.tr("Slide in")
                    icon: "animation"
                    variant: "tonal"
                    onClicked: {
                        Panels.settingsOpen = false;
                        SessionFx.previewReveal();
                    }
                }
                FButton { text: I18n.tr("Welcome"); icon: "login"; variant: "tonal"; onClicked: SessionFx.playIntro(true) }
                FButton { text: I18n.tr("Goodbye"); icon: "logout"; variant: "tonal"; onClicked: SessionFx.playOutro("Logging out…", null, true) }
            }
        }
    }

    Group {
        title: I18n.tr("Idle")
        SwitchRow { title: I18n.tr("Lock when idle"); icon: "lock_clock"; target: page.l; key: "autoLock" }
        SliderRow { visible: page.l.autoLock; title: Power.hasBattery ? I18n.tr("Lock after, plugged in") : I18n.tr("Lock after"); subtitle: Power.hasBattery && !Power.onBattery ? I18n.tr("Now") : ""; icon: "timer"; target: page.l; key: "idleMinutes"; from: 1; to: 60; stepSize: 1; suffix: " min" }
        SliderRow { visible: page.l.autoLock && Power.hasBattery; title: I18n.tr("Lock after, on battery"); subtitle: Power.onBattery ? I18n.tr("Now") : ""; icon: "battery_5_bar"; target: page.l; key: "idleMinutesBattery"; from: 1; to: 60; stepSize: 1; suffix: " min" }
        SliderRow { title: Power.hasBattery ? I18n.tr("Turn screens off, plugged in") : I18n.tr("Turn screens off after"); subtitle: I18n.tr("0 disables"); icon: "monitor"; target: page.l; key: "screenOffMinutes"; from: 0; to: 90; stepSize: 1; suffix: " min" }
        SliderRow { visible: Power.hasBattery; title: I18n.tr("Turn screens off, on battery"); subtitle: I18n.tr("0 disables"); icon: "battery_5_bar"; target: page.l; key: "screenOffMinutesBattery"; from: 0; to: 90; stepSize: 1; suffix: " min" }
        SettingRow {
            title: I18n.tr("Sleep when idle")
            subtitle: I18n.tr("Suspend or hibernate after a while, on battery and plugged in, is in Power")
            icon: "bedtime"
            FButton { text: I18n.tr("Power"); variant: "text"; onClicked: Panels.openSettings("power") }
        }
        SwitchRow { title: I18n.tr("Media controls on lock screen"); icon: "music_note"; target: page.l; key: "showMedia" }
        TextRow { title: I18n.tr("Avatar image"); subtitle: I18n.tr("Or choose a picture in Users"); icon: "account_circle"; target: Settings.data.general; key: "avatar"; placeholder: I18n.tr("~/.face") }
    }

    FingerprintSection {}

    LoginSection {}

}
