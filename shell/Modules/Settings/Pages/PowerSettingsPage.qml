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
