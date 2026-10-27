import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: "Power"
    subtitle: "Power profiles, sleep, and what the lid and power button do."

    readonly property var pw: Settings.data.power
    property var logind: ({})          // effective values from logind
    property var draft: ({})           // edits not applied yet
    property bool loaded: false
    readonly property bool dirty: Object.keys(draft).some(k => draft[k] !== logind[k])
    readonly property var actions: [
        { value: "suspend", label: "Suspend" },
        { value: "hibernate", label: "Hibernate" },
        { value: "suspend-then-hibernate", label: "Suspend, then hibernate" },
        { value: "lock", label: "Lock the screen only" },
        { value: "ignore", label: "Do nothing" },
        { value: "poweroff", label: "Power off" }
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
            Keyboard.setShortcuts(others.concat([{ key: "XF86PowerOff", type: "flamenco", value: "power", title: "Power menu" }]));
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
        title: "Power profile"
        SettingRow {
            title: Power.profileName
            subtitle: Power.profileId === "power-saver" ? "Longer battery, lower performance" : Power.profileId === "performance" ? "Maximum performance, more power and heat" : "Balance performance and power use"
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
            title: "Performance unavailable"
            subtitle: "This machine's power-profiles-daemon doesn't offer a performance profile."
            icon: "info"
        }
    }

    Group {
        visible: Power.hasBattery
        title: "Battery"
        SettingRow {
            title: Power.percent + "%" + (Power.charging ? ", charging" : "")
            subtitle: Power.timeLeft
            icon: Power.icon
        }
    }

    Group {
        visible: Power.hasBattery
        title: "Battery warnings"
        SwitchRow {
            title: "Warn when the battery runs low"
            subtitle: "A notification at the low level, and a critical one (it shows even with Do Not Disturb) at the critical level"
            icon: "battery_alert"
            target: page.pw
            key: "batteryWarnings"
        }
        SliderRow { visible: page.pw.batteryWarnings; title: "Low"; icon: "battery_2_bar"; target: page.pw; key: "batteryWarnLow"; from: 10; to: 40; stepSize: 1; suffix: "%" }
        SliderRow { visible: page.pw.batteryWarnings; title: "Critical"; icon: "battery_alert"; target: page.pw; key: "batteryWarnCritical"; from: 3; to: 20; stepSize: 1; suffix: "%" }
        ChoiceRow {
            visible: page.pw.batteryWarnings
            title: "When it's nearly empty"
            subtitle: (page.pw.batteryEmptyAction || "none") === "none" ? "Nothing: it runs until the battery gives out"
                : "At " + Math.max(2, Math.min(page.pw.batteryWarnLow - 1, page.pw.batteryWarnCritical) - 5) + "%, after a minute's warning (plugging in cancels it)"
            icon: "battery_0_bar"
            target: page.pw
            key: "batteryEmptyAction"
            segWidth: 96
            options: [{ value: "none", label: "Nothing" }, { value: "suspend", label: "Suspend" }, { value: "hibernate", label: "Hibernate" }, { value: "poweroff", label: "Shut down" }]
        }
        SettingRow {
            visible: page.pw.batteryWarnings
            title: "Try it"
            subtitle: "Shows the low battery warning"
            icon: "science"
            FButton { text: "Show a test"; variant: "tonal"; onClicked: BatteryAlerts.test() }
        }
    }

    Group {
        title: "Sleep"
        SwitchRow {
            title: "Allow the computer to sleep"
            subtitle: "Off: nothing can suspend it (lid, idle, menu, sleep key) while Flamenco runs"
            icon: "bedtime"
            target: page.pw
            key: "allowSleep"
        }
        SwitchRow {
            visible: page.pw.allowSleep
            title: "Lock the screen before sleeping"
            subtitle: "Also covers closing the lid and suspends started elsewhere"
            icon: "lock"
            target: page.pw
            key: "lockOnSleep"
        }
        SliderRow {
            visible: page.pw.allowSleep
            title: "Suspend when idle on battery"
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
            title: "Suspend when idle while plugged in"
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
            title: "Idle sleep means"
            subtitle: ({ suspend: "Suspend: quick to wake, uses a little battery", hibernate: "Hibernate: saves to disk and powers off (needs swap set up for it)",
                         "suspend-then-hibernate": "Suspend, then hibernate after a while (systemd's HibernateDelaySec)" })[page.pw.idleSleep || "suspend"]
            icon: "bedtime"
            target: page.pw
            key: "idleSleep"
            segWidth: 130
            options: [{ value: "suspend", label: "Suspend" }, { value: "hibernate", label: "Hibernate" }, { value: "suspend-then-hibernate", label: "Both" }]
        }
        SettingRow {
            title: "Lock and screen off when idle"
            subtitle: "Their times, on battery and plugged in, are in Lock & Login"
            icon: "lock_clock"
            FButton { text: "Lock & Login"; variant: "text"; onClicked: Panels.openSettings("lock") }
        }
    }

    Group {
        title: "Password dialog"
        SwitchRow {
            title: "Flamenco's password dialog"
            subtitle: !page.pw.polkitAgent ? "Off: another polkit agent has to be running, or apps can't ask for your password"
                : !PolkitAuth.available ? "Your Quickshell was built without polkit support, so another agent (polkit-gnome, polkit-kde…) is needed"
                : PolkitAuth.other !== "" ? PolkitAuth.other + " is running and answers instead. Take it out of your startup (niri: its spawn-at-startup line) and log in again"
                : "When an app (or Flamenco) needs your password for something that changes the system"
            icon: "admin_panel_settings"
            target: page.pw
            key: "polkitAgent"
        }
        SettingRow {
            visible: page.pw.polkitAgent && PolkitAuth.available
            title: "Try it"
            subtitle: "Asks for your password the way apps do (nothing is changed)"
            icon: "science"
            Row {
                spacing: 6
                FButton {
                    text: "Test"
                    variant: "tonal"
                    onClicked: Quickshell.execDetached(["pkexec", "--disable-internal-agent", "true"])
                }
                FButton {
                    text: "Check again"
                    variant: "text"
                    onClicked: PolkitAuth.findOthers()
                }
            }
        }
    }

    Group {
        title: "Power menu"
        SettingRow {
            title: "Hold to confirm"
            subtitle: "How long to hold each button before it acts, so a stray click can't log you out. 0 s acts on a click."
            icon: "touch_app"
            FButton {
                text: page.pw.holdLogout === 0 && page.pw.holdReboot === 0 && page.pw.holdShutdown === 0 ? "Back to 3 s" : "All instant"
                variant: "tonal"
                onClicked: {
                    const v = page.pw.holdLogout === 0 && page.pw.holdReboot === 0 && page.pw.holdShutdown === 0 ? 3 : 0;
                    page.pw.holdLogout = v;
                    page.pw.holdReboot = v;
                    page.pw.holdShutdown = v;
                }
            }
        }
        SliderRow { title: "Log out"; subtitle: page.pw.holdLogout === 0 ? "Instant" : ""; icon: "logout"; target: page.pw; key: "holdLogout"; from: 0; to: 10; stepSize: 0.5; decimals: 1; suffix: " s" }
        SliderRow { title: "Restart"; subtitle: page.pw.holdReboot === 0 ? "Instant" : ""; icon: "restart_alt"; target: page.pw; key: "holdReboot"; from: 0; to: 10; stepSize: 0.5; decimals: 1; suffix: " s" }
        SliderRow { title: "Shut down"; subtitle: page.pw.holdShutdown === 0 ? "Instant" : ""; icon: "power_settings_new"; target: page.pw; key: "holdShutdown"; from: 0; to: 10; stepSize: 0.5; decimals: 1; suffix: " s" }
        SliderRow { title: "Countdown"; subtitle: page.pw.countdown > 0 ? "Actions that aren't held count down first; Esc cancels" : "Off: they run at once (or once held)"; icon: "timer"; target: page.pw; key: "countdown"; from: 0; to: 15; stepSize: 1; suffix: " s" }
        SwitchRow { title: "Hibernate button"; icon: "downloading"; target: page.pw; key: "menuHibernate" }
        SwitchRow { title: "Firmware setup button"; subtitle: "Restarts into the computer's UEFI setup"; icon: "developer_board"; target: page.pw; key: "menuFirmware" }
        SwitchRow { title: "Switch user button"; subtitle: Power.canSwitchUser ? "Back to the login screen, this session kept" : "Needs a login manager that can (LightDM's dm-tool, GDM)"; icon: "switch_account"; target: page.pw; key: "menuSwitchUser" }
        SettingRow {
            title: "Open the power menu"
            subtitle: "Mod+Escape, or the power button in the bar"
            icon: "power_settings_new"
            FButton {
                text: "Try it"
                variant: "text"
                onClicked: {
                    Panels.settingsOpen = false;
                    Panels.open("power", "");
                }
            }
        }
    }

    Group {
        title: "Laptop lid"
        SettingRow {
            visible: page.loaded && !page.logind.hasLid
            title: "No lid detected"
            subtitle: "These apply on laptops; you can still set them"
            icon: "info"
        }
        SettingRow {
            title: "When closed on battery"
            icon: "battery_full"
            FDropdown { implicitWidth: 260; options: page.actions; current: page.value("HandleLidSwitch"); onSelected: v => page.set("HandleLidSwitch", v) }
        }
        SettingRow {
            title: "When closed while plugged in"
            icon: "power"
            FDropdown { implicitWidth: 260; options: page.actions; current: page.value("HandleLidSwitchExternalPower"); onSelected: v => page.set("HandleLidSwitchExternalPower", v) }
        }
        SettingRow {
            title: "When closed with an external monitor"
            subtitle: "Docked"
            icon: "desktop_windows"
            FDropdown { implicitWidth: 260; options: page.actions; current: page.value("HandleLidSwitchDocked"); onSelected: v => page.set("HandleLidSwitchDocked", v) }
        }
    }

    Group {
        title: "Power button"
        SettingRow {
            title: "When pressed"
            icon: "power_settings_new"
            FDropdown {
                implicitWidth: 260
                options: [{ value: "menu", label: "Show the power menu" }].concat(page.actions.filter(a => a.value !== "lock"))
                current: page.powerKeyMenu && page.value("HandlePowerKey") === "ignore" ? "menu" : page.value("HandlePowerKey")
                onSelected: v => page.setPowerKey(v)
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.sp3
        FButton {
            text: "Apply lid & power button"
            icon: "admin_panel_settings"
            disabled: !page.dirty || runner.running
            onClicked: page.applyLogind()
        }
        FButton {
            visible: page.logind.managed ?? false
            text: "Back to system defaults"
            variant: "outlined"
            onClicked: {
                runner.command = Paths.termHold(Paths.shellQuote(Paths.bin) + " power logind reset");
                runner.running = true;
            }
        }
        FText {
            Layout.fillWidth: true
            text: page.dirty ? "Lid and power-button changes need your password (systemd-logind)." : "Sleep settings apply immediately."
            dim: true
            wrapMode: Text.Wrap
            font.pixelSize: Theme.fsSm
        }
    }

    Group {
        title: "Session"
        SettingRow {
            title: "Lock, idle and screen off"
            subtitle: "Configured under Lock & Login"
            icon: "lock_clock"
            FButton {
                text: "Open"
                variant: "tonal"
                onClicked: Panels.settingsPage = "lock"
            }
        }
    }
}
