pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower

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

    readonly property int profile: PowerProfiles.profile
    readonly property string profileName: profile === PowerProfile.Performance ? "Performance" : profile === PowerProfile.PowerSaver ? "Power saver" : "Balanced"
    readonly property string profileIcon: profile === PowerProfile.Performance ? "rocket_launch" : profile === PowerProfile.PowerSaver ? "eco" : "balance"

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
        Quickshell.execDetached(["niri", "msg", "action", "quit", "--skip-confirmation"]);
    }
}
