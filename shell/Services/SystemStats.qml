pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// CPU, memory, temperatures, disks, network and processes.
// Cheap stats always update; the expensive ones (sensors, disks, processes,
// frequency) only while `detailed` is on, i.e. while the performance popout is open.
Singleton {
    id: root

    property bool detailed: false

    // ── always on ──
    property real cpu: 0
    property real mem: 0
    property real memUsed: 0     // GiB
    property real memTotal: 0    // GiB
    property real swapUsed: 0    // GiB
    property real swapTotal: 0   // GiB
    property real temp: 0        // °C, hottest CPU-ish sensor
    property real uptime: 0
    property var load: [0, 0, 0]
    property int cores: 1
    property real netDown: 0     // bytes/s
    property real netUp: 0
    property var cpuHistory: []  // last 60 samples, 0..1
    property var memHistory: []
    property var netHistory: []  // down+up bytes/s

    // ── detailed ──
    property real cpuFreq: 0     // MHz, average
    property var sensors: []     // [{ chip, label, temp }]
    property var disks: []       // [{ mount, size, used }]
    property var processes: []   // [{ pid, name, cpu, mem }]

    property var _prevCpu: null
    property var _prevNet: null
    readonly property int interval: 2000
    readonly property int historyLength: 60

    readonly property string uptimeText: {
        const d = Math.floor(uptime / 86400), h = Math.floor(uptime % 86400 / 3600), m = Math.floor(uptime % 3600 / 60);
        return (d > 0 ? d + "d " : "") + (h > 0 ? h + "h " : "") + m + "m";
    }

    function push(list, v) {
        const l = list.concat([v]);
        return l.length > historyLength ? l.slice(l.length - historyLength) : l;
    }

    function formatBytes(b, perSecond) {
        const units = ["B", "KB", "MB", "GB", "TB"];
        let i = 0;
        while (b >= 1024 && i < units.length - 1) {
            b /= 1024;
            i++;
        }
        return (i === 0 ? Math.round(b) : b.toFixed(b < 10 ? 1 : 0)) + " " + units[i] + (perSecond ? "/s" : "");
    }

    Timer {
        interval: root.interval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
            up.reload();
            loadavg.reload();
            netdev.reload();
            if (!sensorsProc.running)
                sensorsProc.running = true;
            if (root.detailed) {
                cpuinfo.reload();
                if (!procs.running)
                    procs.running = true;
            }
        }
    }

    // disks change slowly
    Timer {
        interval: 30000
        running: root.detailed
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!df.running) df.running = true
    }

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const lines = text().split("\n");
            const f = lines[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = f[3] + (f[4] || 0);
            const total = f.reduce((a, b) => a + b, 0);
            if (root._prevCpu) {
                const dt = total - root._prevCpu.total;
                if (dt > 0) {
                    root.cpu = Math.max(0, Math.min(1, 1 - (idle - root._prevCpu.idle) / dt));
                    root.cpuHistory = root.push(root.cpuHistory, root.cpu);
                }
            }
            root._prevCpu = { idle, total };
            root.cores = Math.max(1, lines.filter(l => /^cpu\d+ /.test(l)).length);
        }
    }

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: {
            const t = text();
            const kb = k => parseInt(t.match(new RegExp(k + ":\\s+(\\d+)"))?.[1] ?? 0);
            const total = kb("MemTotal"), avail = kb("MemAvailable");
            if (total > 0) {
                root.mem = 1 - avail / total;
                root.memTotal = total / 1048576;
                root.memUsed = (total - avail) / 1048576;
                root.memHistory = root.push(root.memHistory, root.mem);
            }
            root.swapTotal = kb("SwapTotal") / 1048576;
            root.swapUsed = (kb("SwapTotal") - kb("SwapFree")) / 1048576;
        }
    }

    FileView {
        id: up
        path: "/proc/uptime"
        onLoaded: root.uptime = parseFloat(text())
    }

    FileView {
        id: loadavg
        path: "/proc/loadavg"
        onLoaded: root.load = text().trim().split(/\s+/).slice(0, 3).map(Number)
    }

    FileView {
        id: netdev
        path: "/proc/net/dev"
        onLoaded: {
            let rx = 0, tx = 0;
            for (const line of text().split("\n").slice(2)) {
                const m = line.trim().match(/^([^:]+):\s*(.*)$/);
                if (!m || m[1] === "lo")
                    continue;
                const f = m[2].trim().split(/\s+/).map(Number);
                rx += f[0];
                tx += f[8];
            }
            const now = Date.now();
            if (root._prevNet) {
                const dt = (now - root._prevNet.t) / 1000;
                if (dt > 0) {
                    root.netDown = Math.max(0, (rx - root._prevNet.rx) / dt);
                    root.netUp = Math.max(0, (tx - root._prevNet.tx) / dt);
                    root.netHistory = root.push(root.netHistory, root.netDown + root.netUp);
                }
            }
            root._prevNet = { rx, tx, t: now };
        }
    }

    FileView {
        id: cpuinfo
        path: "/proc/cpuinfo"
        onLoaded: {
            const mhz = (text().match(/^cpu MHz\s*:\s*([\d.]+)/gm) ?? []).map(l => parseFloat(l.split(":")[1]));
            root.cpuFreq = mhz.length ? mhz.reduce((a, b) => a + b, 0) / mhz.length : 0;
        }
    }

    // every hwmon temperature sensor: "chip|label|millidegrees"
    Process {
        id: sensorsProc
        command: ["sh", "-c", "for d in /sys/class/hwmon/hwmon*; do n=$(cat \"$d/name\" 2>/dev/null); for t in \"$d\"/temp*_input; do [ -r \"$t\" ] || continue; l=$(cat \"${t%_input}_label\" 2>/dev/null); echo \"$n|$l|$(cat \"$t\" 2>/dev/null)\"; done; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const list = [];
                for (const line of text.trim().split("\n")) {
                    const [chip, label, v] = line.split("|");
                    const t = parseInt(v) / 1000;
                    if (chip && !isNaN(t) && t > 0 && t < 150)
                        list.push({ chip, label: label || chip, temp: t });
                }
                root.sensors = list;
                // prefer CPU package sensors for the headline number
                const cpuish = list.filter(s => /k10temp|coretemp|zenpower|cpu|acpitz/i.test(s.chip) || /package|tctl|tdie/i.test(s.label));
                const pool = cpuish.length ? cpuish : list;
                root.temp = pool.length ? Math.max(...pool.map(s => s.temp)) : 0;
            }
        }
    }

    Process {
        id: df
        command: ["df", "-B1", "--output=target,size,used", "-x", "tmpfs", "-x", "devtmpfs", "-x", "efivarfs", "-x", "overlay", "-x", "squashfs"]
        stdout: StdioCollector {
            onStreamFinished: {
                const seen = {};
                const out = [];
                for (const line of text.trim().split("\n").slice(1)) {
                    const [mount, size, used] = line.trim().split(/\s+/);
                    const key = size + ":" + used;   // same filesystem mounted twice (btrfs subvolumes)
                    if (!mount || seen[key] || mount.startsWith("/boot") || mount.startsWith("/snap"))
                        continue;
                    seen[key] = true;
                    out.push({ mount, size: Number(size), used: Number(used) });
                }
                root.disks = out.slice(0, 4);
            }
        }
    }

    Process {
        id: procs
        command: ["ps", "-eo", "pid=,comm=,%cpu=,%mem=", "--sort=-%cpu"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.processes = text.trim().split("\n").slice(0, 6).map(l => {
                    const f = l.trim().split(/\s+/);
                    const n = f.length;
                    return { pid: Number(f[0]), name: f.slice(1, n - 2).join(" "), cpu: Number(f[n - 2]), mem: Number(f[n - 1]) };
                });
            }
        }
    }
}
