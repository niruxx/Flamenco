pragma Singleton

import QtQuick
import Quickshell
import qs.Services as FS

// Flamenco shim for DMS's DgopService (system monitor), from Flamenco's stats.
Singleton {
    readonly property real cpuUsage: FS.SystemStats.cpu * 100
    readonly property real cpuTemperature: FS.SystemStats.temp
    readonly property real memoryUsage: FS.SystemStats.mem * 100
    readonly property real usedMemoryMB: FS.SystemStats.memUsed * 1024
    readonly property real totalMemoryMB: FS.SystemStats.memTotal * 1024
    readonly property real networkRxRate: FS.SystemStats.netDown
    readonly property real networkTxRate: FS.SystemStats.netUp
    readonly property var diskMounts: FS.SystemStats.disks.map(d => ({ mount: d.mount, size: d.size, used: d.used, percent: d.size ? d.used / d.size * 100 : 0 }))
    readonly property var processes: FS.SystemStats.processes
    readonly property var availableGpus: []
    function addRef(modules) {}
    function removeRef(modules) {}
    function setSortBy(key) {}
    function addGpuPciId(id) {}
    function removeGpuPciId(id) {}
}
