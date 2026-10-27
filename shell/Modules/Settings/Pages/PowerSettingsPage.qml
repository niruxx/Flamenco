import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: I18n.tr("Power")
    subtitle: I18n.tr("Power profiles, sleep, and what the lid and power button do.")

    readonly property var pw: Settings.data.power
    property var logind: ({})          // effective values from logind
    property var draft: ({})           // edits not applied yet
    property bool loaded: false
    readonly property bool dirty: Object.keys(draft).some(k => draft[k] !== logind[k])
    readonly property var actions: [
        { value: "suspend", label: I18n.tr("Suspend") },
        { value: "hibernate", label: I18n.tr("Hibernate") },
        { value: "suspend-then-hibernate", label: I18n.tr("Suspend, then hibernate") },
        { value: "lock", label: I18n.tr("Lock the screen only") },
        { value: "ignore", label: I18n.tr("Do nothing") },
        { value: "poweroff", label: I18n.tr("Power off") }
    ]
    // "menu" = logind ignores the key and a shortcut opens Flamenco's power menu
    readonly property bool powerKeyMenu: Settings.data.keyboard.shortcuts.some(sc => sc.key === "XF86PowerOff" && sc.type === "flamenco" && sc.value === "power")

    function value(k) {
        return draft[k] ?? logind[k] ?? "";
    }
    function set(k, v) {
        const d = Object.assign({}, draft);
        d[k] = v;
        draft = d;
    }
    function load() {
        if (!getter.running)
            getter.running = true;
    }
    function applyLogind() {
        const spec = {};
        for (const k of ["HandleLidSwitch", "HandleLidSwitchExternalPower", "HandleLidSwitchDocked", "HandlePowerKey"])
            spec[k] = value(k);
        runner.command = Paths.termHold(Paths.shellQuote(Paths.bin) + " power logind apply --json " + Paths.shellQuote(JSON.stringify(spec)));
        runner.running = true;
    }
    function setPowerKey(v) {
        // the "menu" choice is logind=ignore + an XF86PowerOff shortcut
        const others = Settings.data.keyboard.shortcuts.filter(sc => sc.key !== "XF86PowerOff");
        if (v === "menu") {
            Keyboard.setShortcuts(others.concat([{ key: I18n.tr("XF86PowerOff"), type: "flamenco", value: "power", title: I18n.tr("Power menu") }]));
            set("HandlePowerKey", "ignore");
        } else {
            if (others.length !== Settings.data.keyboard.shortcuts.length)
                Keyboard.setShortcuts(others);
            set("HandlePowerKey", v);
        }
    }

    Component.onCompleted: {
        load();
        Keyboard.load();
    }

    Process {
        id: getter
        command: [Paths.bin, "power", "logind", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    page.logind = JSON.parse(text);
                    page.draft = {};
                    page.loaded = true;
                } catch (e) {}
            }
        }
    }
    Process {
        id: runner
        onExited: page.load()
    }

    Group {
        title: I18n.tr("Power profile")
        SettingRow {
            title: Power.profileName
            subtitle: Power.profileId === "power-saver" ? I18n.tr("Longer battery, lower performance") : Power.profileId === "performance" ? I18n.tr("Maximum performance, more power and heat") : I18n.tr("Balance performance and power use")
            icon: Power.profileIcon
            FSegmented {
                implicitWidth: Power.profileOptions.length * 130
                options: Power.profileOptions
                current: Power.profileId
                onSelected: v => Power.setProfile(v)
            }
        }
        SettingRow {
            visible: !Power.hasPerformance
            title: I18n.tr("Performance unavailable")
            subtitle: I18n.tr("This machine's power-profiles-daemon doesn't offer a performance profile.")
            icon: "info"
        }
    }

    Group {
        visible: Power.hasBattery
        title: I18n.tr("Battery")
        SettingRow {
            title: Power.percent + "%" + (Power.charging ? ", charging" : "")
            subtitle: Power.timeLeft
            icon: Power.icon
        }
    }

    Group {
        visible: Power.hasBattery
        title: I18n.tr("Battery warnings")
        SwitchRow {
            title: I18n.tr("Warn when the battery runs low")
            subtitle: I18n.tr("A notification at the low level, and a critical one (it shows even with Do Not Disturb) at the critical level")
            icon: "battery_alert"
            target: page.pw
            key: "batteryWarnings"
        }
        SliderRow { visible: page.pw.batteryWarnings; title: I18n.tr("Low"); icon: "battery_2_bar"; target: page.pw; key: "batteryWarnLow"; from: 10; to: 40; stepSize: 1; suffix: "%" }
        SliderRow { visible: page.pw.batteryWarnings; title: I18n.tr("Critical"); icon: "battery_alert"; target: page.pw; key: "batteryWarnCritical"; from: 3; to: 20; stepSize: 1; suffix: "%" }
        ChoiceRow {
            visible: page.pw.batteryWarnings
            title: I18n.tr("When it's nearly empty")
            subtitle: (page.pw.batteryEmptyAction || "none") === "none" ? I18n.tr("Nothing: it runs until the battery gives out")
                : "At " + Math.max(2, Math.min(page.pw.batteryWarnLow - 1, page.pw.batteryWarnCritical) - 5) + "%, after a minute's warning (plugging in cancels it)"
            icon: "battery_0_bar"
            target: page.pw
            key: "batteryEmptyAction"
            segWidth: 96
            options: [{ value: "none", label: I18n.tr("Nothing") }, { value: "suspend", label: I18n.tr("Suspend") }, { value: "hibernate", label: I18n.tr("Hibernate") }, { value: "poweroff", label: I18n.tr("Shut down") }]
        }
        SettingRow {
            visible: page.pw.batteryWarnings
            title: I18n.tr("Try it")
            subtitle: I18n.tr("Shows the low battery warning")
            icon: "science"
            FButton { text: I18n.tr("Show a test"); variant: "tonal"; onClicked: BatteryAlerts.test() }
        }
    }

    Group {
        title: I18n.tr("Sleep")
        SwitchRow {
            title: I18n.tr("Allow the computer to sleep")
            subtitle: I18n.tr("Off: nothing can suspend it (lid, idle, menu, sleep key) while Flamenco runs")
            icon: "bedtime"
            target: page.pw
            key: "allowSleep"
        }
        SwitchRow {
            visible: page.pw.allowSleep
            title: I18n.tr("Lock the screen before sleeping")
            subtitle: I18n.tr("Also covers closing the lid and suspends started elsewhere")
            icon: "lock"
            target: page.pw
            key: "lockOnSleep"
        }
        SliderRow {
            visible: page.pw.allowSleep
            title: I18n.tr("Suspend when idle on battery")
            subtitle: "0 = never"
            icon: "battery_5_bar"
            target: page.pw
            key: "idleSuspendBattery"
            from: 0
            to: 120
            stepSize: 5
            suffix: " min"
        }
        SliderRow {
            visible: page.pw.allowSleep
            title: I18n.tr("Suspend when idle while plugged in")
            subtitle: "0 = never"
            icon: "power"
            target: page.pw
            key: "idleSuspendAC"
            from: 0
            to: 240
            stepSize: 5
            suffix: " min"
        }
        ChoiceRow {
            visible: page.pw.allowSleep && (page.pw.idleSuspendBattery > 0 || page.pw.idleSuspendAC > 0)
            title: I18n.tr("Idle sleep means")
            subtitle: ({ suspend: I18n.tr("Suspend: quick to wake, uses a little battery"), hibernate: I18n.tr("Hibernate: saves to disk and powers off (needs swap set up for it)"),
                         "suspend-then-hibernate": "Suspend, then hibernate after a while (systemd's HibernateDelaySec)" })[page.pw.idleSleep || "suspend"]
            icon: "bedtime"
            target: page.pw
            key: "idleSleep"
            segWidth: 130
            options: [{ value: "suspend", label: I18n.tr("Suspend") }, { value: "hibernate", label: I18n.tr("Hibernate") }, { value: "suspend-then-hibernate", label: I18n.tr("Both") }]
        }
        SettingRow {
            title: I18n.tr("Lock and screen off when idle")
            subtitle: I18n.tr("Their times, on battery and plugged in, are in Lock & Login")
            icon: "lock_clock"
            FButton { text: I18n.tr("Lock & Login"); variant: "text"; onClicked: Panels.openSettings("lock") }
        }
    }

    Group {
        title: I18n.tr("Password dialog")
        SwitchRow {
            title: I18n.tr("Flamenco's password dialog")
            subtitle: !page.pw.polkitAgent ? I18n.tr("Off: another polkit agent has to be running, or apps can't ask for your password")
                : !PolkitAuth.available ? "Your Quickshell was built without polkit support, so another agent (polkit-gnome, polkit-kde…) is needed"
                : PolkitAuth.other !== "" ? PolkitAuth.other + " is running and answers instead. Take it out of your startup (niri: its spawn-at-startup line) and log in again"
                : "When an app (or Flamenco) needs your password for something that changes the system"
            icon: "admin_panel_settings"
            target: page.pw
            key: "polkitAgent"
        }
        SettingRow {
            visible: page.pw.polkitAgent && PolkitAuth.available
            title: I18n.tr("Try it")
            subtitle: I18n.tr("Asks for your password the way apps do (nothing is changed)")
            icon: "science"
            Row {
                spacing: 6
                FButton {
                    text: I18n.tr("Test")
                    variant: "tonal"
                    onClicked: Quickshell.execDetached(["pkexec", "--disable-internal-agent", "true"])
                }
                FButton {
                    text: I18n.tr("Check again")
                    variant: "text"
                    onClicked: PolkitAuth.findOthers()
                }
            }
        }
    }

    Group {
        title: I18n.tr("Power menu")
        SettingRow {
            title: I18n.tr("Hold to confirm")
            subtitle: I18n.tr("How long to hold each button before it acts, so a stray click can't log you out. 0 s acts on a click.")
            icon: "touch_app"
            FButton {
                text: page.pw.holdLogout === 0 && page.pw.holdReboot === 0 && page.pw.holdShutdown === 0 ? I18n.tr("Back to 3 s") : I18n.tr("All instant")
                variant: "tonal"
                onClicked: {
                    const v = page.pw.holdLogout === 0 && page.pw.holdReboot === 0 && page.pw.holdShutdown === 0 ? 3 : 0;
                    page.pw.holdLogout = v;
                    page.pw.holdReboot = v;
                    page.pw.holdShutdown = v;
                }
            }
        }
        SliderRow { title: I18n.tr("Log out"); subtitle: page.pw.holdLogout === 0 ? I18n.tr("Instant") : ""; icon: "logout"; target: page.pw; key: "holdLogout"; from: 0; to: 10; stepSize: 0.5; decimals: 1; suffix: " s" }
        SliderRow { title: I18n.tr("Restart"); subtitle: page.pw.holdReboot === 0 ? I18n.tr("Instant") : ""; icon: "restart_alt"; target: page.pw; key: "holdReboot"; from: 0; to: 10; stepSize: 0.5; decimals: 1; suffix: " s" }
        SliderRow { title: I18n.tr("Shut down"); subtitle: page.pw.holdShutdown === 0 ? I18n.tr("Instant") : ""; icon: "power_settings_new"; target: page.pw; key: "holdShutdown"; from: 0; to: 10; stepSize: 0.5; decimals: 1; suffix: " s" }
        SliderRow { title: I18n.tr("Countdown"); subtitle: page.pw.countdown > 0 ? I18n.tr("Actions that aren't held count down first; Esc cancels") : I18n.tr("Off: they run at once (or once held)"); icon: "timer"; target: page.pw; key: "countdown"; from: 0; to: 15; stepSize: 1; suffix: " s" }
        SwitchRow { title: I18n.tr("Hibernate button"); icon: "downloading"; target: page.pw; key: "menuHibernate" }
        SwitchRow { title: I18n.tr("Firmware setup button"); subtitle: I18n.tr("Restarts into the computer's UEFI setup"); icon: "developer_board"; target: page.pw; key: "menuFirmware" }
        SwitchRow { title: I18n.tr("Switch user button"); subtitle: Power.canSwitchUser ? I18n.tr("Back to the login screen, this session kept") : I18n.tr("Needs a login manager that can (LightDM's dm-tool, GDM)"); icon: "switch_account"; target: page.pw; key: "menuSwitchUser" }
        SettingRow {
            title: I18n.tr("Open the power menu")
            subtitle: I18n.tr("Mod+Escape, or the power button in the bar")
            icon: "power_settings_new"
            FButton {
                text: I18n.tr("Try it")
                variant: "text"
                onClicked: {
                    Panels.settingsOpen = false;
                    Panels.open("power", "");
                }
            }
        }
    }

    Group {
        title: I18n.tr("Laptop lid")
        SettingRow {
            visible: page.loaded && !page.logind.hasLid
            title: I18n.tr("No lid detected")
            subtitle: I18n.tr("These apply on laptops; you can still set them")
            icon: "info"
        }
        SettingRow {
            title: I18n.tr("When closed on battery")
            icon: "battery_full"
            FDropdown { implicitWidth: 260; options: page.actions; current: page.value("HandleLidSwitch"); onSelected: v => page.set("HandleLidSwitch", v) }
        }
        SettingRow {
            title: I18n.tr("When closed while plugged in")
            icon: "power"
            FDropdown { implicitWidth: 260; options: page.actions; current: page.value("HandleLidSwitchExternalPower"); onSelected: v => page.set("HandleLidSwitchExternalPower", v) }
        }
        SettingRow {
            title: I18n.tr("When closed with an external monitor")
            subtitle: I18n.tr("Docked")
            icon: "desktop_windows"
            FDropdown { implicitWidth: 260; options: page.actions; current: page.value("HandleLidSwitchDocked"); onSelected: v => page.set("HandleLidSwitchDocked", v) }
        }
    }

    Group {
        title: I18n.tr("Power button")
        SettingRow {
            title: I18n.tr("When pressed")
            icon: "power_settings_new"
            FDropdown {
                implicitWidth: 260
                options: [{ value: "menu", label: I18n.tr("Show the power menu") }].concat(page.actions.filter(a => a.value !== "lock"))
                current: page.powerKeyMenu && page.value("HandlePowerKey") === "ignore" ? "menu" : page.value("HandlePowerKey")
                onSelected: v => page.setPowerKey(v)
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.sp3
        FButton {
            text: I18n.tr("Apply lid & power button")
            icon: "admin_panel_settings"
            disabled: !page.dirty || runner.running
            onClicked: page.applyLogind()
        }
        FButton {
            visible: page.logind.managed ?? false
            text: I18n.tr("Back to system defaults")
            variant: "outlined"
            onClicked: {
                runner.command = Paths.termHold(Paths.shellQuote(Paths.bin) + " power logind reset");
                runner.running = true;
            }
        }
        FText {
            Layout.fillWidth: true
            text: page.dirty ? I18n.tr("Lid and power-button changes need your password (systemd-logind).") : I18n.tr("Sleep settings apply immediately.")
            dim: true
            wrapMode: Text.Wrap
            font.pixelSize: Theme.fsSm
        }
    }

    Group {
        title: I18n.tr("Session")
        SettingRow {
            title: I18n.tr("Lock, idle and screen off")
            subtitle: I18n.tr("Configured under Lock & Login")
            icon: "lock_clock"
            FButton {
                text: I18n.tr("Open")
                variant: "tonal"
                onClicked: Panels.settingsPage = "lock"
            }
        }
    }
}
