pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower

// Flamenco shim for Noctalia's BatteryService, on UPower.
Singleton {
    id: root

    readonly property var primaryDevice: UPower.displayDevice
    readonly property var laptopBatteries: UPower.devices.values.filter(d => d.isLaptopBattery)
    readonly property var bluetoothBatteries: UPower.devices.values.filter(d => !d.isLaptopBattery && d.isPresent && d.type !== UPowerDeviceType.LinePower && d.nativePath.indexOf("bluez") >= 0)
    readonly property string deviceModel: primaryDevice?.model ?? ""

    function findDevice(nativePath) {
        return UPower.devices.values.find(d => d.nativePath === nativePath) ?? null;
    }
    function isDevicePresent(d) {
        return !!d && (d.isPresent ?? d.ready ?? true);
    }
    function isDeviceReady(d) {
        return !!d && (d.ready ?? true);
    }
    function getPercentage(d) {
        const dev = d ?? primaryDevice;
        return Math.round((dev?.percentage ?? 0) * 100);
    }
    function isCharging(d) {
        const dev = d ?? primaryDevice;
        return dev?.state === UPowerDeviceState.Charging;
    }
    function isPluggedIn(d) {
        const dev = d ?? primaryDevice;
        return dev?.state === UPowerDeviceState.Charging || dev?.state === UPowerDeviceState.FullyCharged || dev?.state === UPowerDeviceState.PendingCharge;
    }
    function isLowBattery(d) {
        return getPercentage(d) <= 20 && !isCharging(d);
    }
    function isCriticalBattery(d) {
        return getPercentage(d) <= 7 && !isCharging(d);
    }
    function getDeviceName(d) {
        return d?.model || d?.nativePath || "Battery";
    }
    function getIcon(percent, charging, pluggedIn, isReady) {
        if (charging)
            return "battery-charging";
        if (percent >= 90) return "battery-4";
        if (percent >= 60) return "battery-3";
        if (percent >= 35) return "battery-2";
        if (percent >= 10) return "battery-1";
        return "battery";
    }
    function getTimeRemainingText(d) {
        const dev = d ?? primaryDevice;
        const s = isCharging(dev) ? dev?.timeToFull : dev?.timeToEmpty;
        if (!s || s <= 0)
            return "";
        const h = Math.floor(s / 3600), m = Math.round((s % 3600) / 60);
        return (h > 0 ? h + "h " : "") + m + "m";
    }
    function getRateText(d) {
        const r = (d ?? primaryDevice)?.changeRate ?? 0;
        return r ? Math.abs(r).toFixed(1) + " W" : "";
    }
}
