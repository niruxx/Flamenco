pragma Singleton

import QtQuick
import Quickshell
import qs.Services as FS

// Flamenco shim for Noctalia's SystemStatService, from Flamenco's system stats.
Singleton {
    id: root

    readonly property int networkIntervalMs: FS.SystemStats.interval
    readonly property real cpuUsage: FS.SystemStats.cpu * 100
    readonly property real cpuTemp: FS.SystemStats.temp
    readonly property real memPercent: FS.SystemStats.mem * 100
    readonly property real memGb: FS.SystemStats.memUsed
    readonly property real memTotalGb: FS.SystemStats.memTotal
    readonly property real rxSpeed: FS.SystemStats.netDown
    readonly property real txSpeed: FS.SystemStats.netUp
    property var rxSpeedHistory: []
    property var txSpeedHistory: []
    property real rxMaxSpeed: 0
    property real txMaxSpeed: 0
    readonly property var cpuHistory: FS.SystemStats.cpuHistory.map(v => v * 100)

    onRxSpeedChanged: {
        rxSpeedHistory = rxSpeedHistory.concat([rxSpeed]).slice(-60);
        rxMaxSpeed = Math.max(...rxSpeedHistory, 1);
    }
    onTxSpeedChanged: {
        txSpeedHistory = txSpeedHistory.concat([txSpeed]).slice(-60);
        txMaxSpeed = Math.max(...txSpeedHistory, 1);
    }

    function formatSpeed(bytesPerSecond) {
        const b = Number(bytesPerSecond) || 0;
        if (b < 1024)
            return Math.round(b) + " B/s";
        if (b < 1024 * 1024)
            return (b / 1024).toFixed(1) + " KB/s";
        if (b < 1024 * 1024 * 1024)
            return (b / 1024 / 1024).toFixed(1) + " MB/s";
        return (b / 1024 / 1024 / 1024).toFixed(1) + " GB/s";
    }
}
