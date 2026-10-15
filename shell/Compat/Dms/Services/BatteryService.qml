pragma Singleton

import QtQuick
import Quickshell
import qs.Services as FS

// Flamenco shim for DMS's BatteryService.
Singleton {
    readonly property bool batteryAvailable: FS.Power.hasBattery
    readonly property int batteryLevel: FS.Power.percent
    readonly property bool isCharging: FS.Power.charging
    readonly property bool isPluggedIn: FS.Power.hasBattery && !FS.Power.onBattery
    readonly property string batteryStatus: isCharging ? "Charging" : "Discharging"
    readonly property bool isLowBattery: batteryLevel <= 20 && !isCharging
}
