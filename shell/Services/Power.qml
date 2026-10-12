pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.Commons
import Quickshell.Io

// Battery + power profiles + session actions.
Singleton {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property bool hasBattery: device?.isLaptopBattery ?? false
    readonly property real percent: Math.round((device?.percentage ?? 0) * 100)
    readonly property bool charging: device?.state === UPowerDeviceState.Charging || device?.state === UPowerDeviceState.FullyCharged
    readonly property string icon: {
        if (charging)
            return "battery_charging_full";
        if (percent >= 95)
            return "battery_full";
        const bars = Math.max(0, Math.min(6, Math.floor(percent / 15)));
        return "battery_" + bars + "_bar";
    }
    readonly property string timeLeft: {
        const s = charging ? device?.timeToFull : device?.timeToEmpty;
        if (!s)
            return "";
        const h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60);
        return (h > 0 ? h + "h " : "") + m + "m" + (charging ? " until full" : " left");
    }

    readonly property bool onBattery: hasBattery && device?.state === UPowerDeviceState.Discharging

    // "Allow sleep" off: block every kind of sleep (lid, idle, menu, suspend key) while the shell runs
    Process {
        running: !Settings.data.power.allowSleep
        command: ["systemd-inhibit", "--what=sleep:idle:handle-lid-switch:handle-suspend-key:handle-hibernate-key", "--who=Flamenco", "--why=Sleep is turned off in Flamenco Settings", "--mode=block", "sleep", "infinity"]
    }

    readonly property int profile: PowerProfiles.profile
    readonly property string profileName: profile === PowerProfile.Performance ? "Performance" : profile === PowerProfile.PowerSaver ? "Power saver" : "Balanced"
    readonly property string profileIcon: profile === PowerProfile.Performance ? "rocket_launch" : profile === PowerProfile.PowerSaver ? "eco" : "balance"

    // "power-saver" | "balanced" | "performance"
    readonly property string profileId: profile === PowerProfile.Performance ? "performance" : profile === PowerProfile.PowerSaver ? "power-saver" : "balanced"
    readonly property bool hasPerformance: PowerProfiles.hasPerformanceProfile
    readonly property var profileOptions: [
        { value: "power-saver", label: "Power saver", icon: "eco" },
        { value: "balanced", label: "Balanced", icon: "balance" }
    ].concat(hasPerformance ? [{ value: "performance", label: "Performance", icon: "rocket_launch" }] : [])

    function setProfile(id) {
        PowerProfiles.profile = id === "performance" ? PowerProfile.Performance : id === "power-saver" ? PowerProfile.PowerSaver : PowerProfile.Balanced;
    }

    function cycleProfile() {
        if (profile === PowerProfile.Balanced)
            PowerProfiles.profile = PowerProfiles.hasPerformanceProfile ? PowerProfile.Performance : PowerProfile.PowerSaver;
        else if (profile === PowerProfile.Performance)
            PowerProfiles.profile = PowerProfile.PowerSaver;
        else
            PowerProfiles.profile = PowerProfile.Balanced;
    }

    function suspend() {
        Quickshell.execDetached(["systemctl", "suspend"]);
    }
    function reboot() {
        Quickshell.execDetached(["systemctl", "reboot"]);
    }
    function shutdown() {
        Quickshell.execDetached(["systemctl", "poweroff"]);
    }
    function logout() {
        Niri.action("quit", "--skip-confirmation");
    }
}
