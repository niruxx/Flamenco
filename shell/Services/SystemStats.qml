pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real cpu: 0
    property real mem: 0
    property real memUsed: 0     // GiB
    property real memTotal: 0    // GiB
    property real temp: 0
    property real uptime: 0
    property var _prev: null

    readonly property string uptimeText: {
        const d = Math.floor(uptime / 86400), h = Math.floor(uptime % 86400 / 3600), m = Math.floor(uptime % 3600 / 60);
        return (d > 0 ? d + "d " : "") + (h > 0 ? h + "h " : "") + m + "m";
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
            thermal.reload();
            up.reload();
        }
    }

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const f = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = f[3] + (f[4] || 0);
            const total = f.reduce((a, b) => a + b, 0);
            if (root._prev) {
                const dt = total - root._prev.total;
                if (dt > 0)
                    root.cpu = 1 - (idle - root._prev.idle) / dt;
            }
            root._prev = { idle, total };
        }
    }

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: {
            const t = text();
            const total = parseInt(t.match(/MemTotal:\s+(\d+)/)?.[1] ?? 0);
            const avail = parseInt(t.match(/MemAvailable:\s+(\d+)/)?.[1] ?? 0);
            if (total > 0) {
                root.mem = 1 - avail / total;
                root.memTotal = total / 1048576;
                root.memUsed = (total - avail) / 1048576;
            }
        }
    }

    FileView {
        id: thermal
        path: "/sys/class/thermal/thermal_zone0/temp"
        onLoaded: root.temp = parseInt(text()) / 1000
    }

    FileView {
        id: up
        path: "/proc/uptime"
        onLoaded: root.uptime = parseFloat(text())
    }
}
