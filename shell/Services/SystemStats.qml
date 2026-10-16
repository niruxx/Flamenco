pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// CPU, memory, temperatures, disks, network and processes.
// Cheap stats always update; the expensive ones (sensors, disks, processes,
// frequency) only while `detailed` is on, i.e. while the performance popout is open.
Singleton {
    id: root

    // on while anything shows the detailed stats (the performance panel, the dashboard's
    // Home and System pages); each calls hold(true) when it starts showing, hold(false) after
    property int detailUsers: 0
    readonly property bool detailed: detailUsers > 0
    function hold(on) {
        detailUsers = Math.max(0, detailUsers + (on ? 1 : -1));
    }

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
    property var coreUsage: []   // 0..1 per logical core
    property string cpuModel: ""
    property real memAvailable: 0 // GiB
    property real memCached: 0
    property real memShared: 0
    property var tempHistory: [] // °C
    readonly property real tempPeak: tempHistory.length ? Math.max(...tempHistory.slice(-45)) : temp
    property int processCount: 0
    property real netRxTotal: 0  // bytes since the shell started
    property real netTxTotal: 0
    property string netIface: ""
    property string netIp: ""
    property string kernel: ""
    property string hostname: ""
    // GPU: AMD and Intel from sysfs; NVIDIA only while gpuNvidia is on (polling keeps it awake)
    property bool gpuNvidia: false
    property string gpuName: ""
    property real gpuBusy: -1    // 0..1, -1 = unknown
    property real gpuMemUsed: 0  // GiB
    property real gpuMemTotal: 0
    property real gpuTemp: 0
    property var _prevCores: []
    property var _netStart: null

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
            // the sensors found at startup, read directly (no process every 2 s)
            for (let i = 0; i < sensorFiles.count; i++)
                sensorFiles.objectAt(i)?.reload();
            if (root.detailed) {
                cpuinfo.reload();
                if (!procs.running)
                    procs.running = true;
            }
        }
    }

    // disks, the network interface and the machine change slowly
    Timer {
        interval: 30000
        running: root.detailed
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!df.running)
                df.running = true;
            if (!netInfo.running)
                netInfo.running = true;
            if (!hostInfo.running && root.kernel === "")
                hostInfo.running = true;
        }
    }

    // the GPU, every few seconds while detailed
    Timer {
        interval: 3000
        running: root.detailed
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!gpuProc.running) gpuProc.running = true
    }

    // the interface and address the default route uses
    Process {
        id: netInfo
        command: ["sh", "-c", "ip -4 route get 1.1.1.1 2>/dev/null | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.netIface = text.match(/\bdev (\S+)/)?.[1] ?? "";
                root.netIp = text.match(/\bsrc (\S+)/)?.[1] ?? "";
            }
        }
    }
    Process {
        id: hostInfo
        command: ["sh", "-c", "cat /proc/sys/kernel/osrelease /proc/sys/kernel/hostname"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.trim().split("\n");
                root.kernel = l[0] ?? "";
                root.hostname = l[1] ?? "";
            }
        }
    }
    // AMD / Intel: sysfs ("amd|busy%|vram used|vram total|temp"); NVIDIA: nvidia-smi when allowed
    Process {
        id: gpuProc
        command: ["sh", "-c", 'for c in /sys/class/drm/card[0-9]; do d="$c/device"; if [ -r "$d/gpu_busy_percent" ]; then t=$(cat "$d"/hwmon/hwmon*/temp1_input 2>/dev/null | head -1); echo "sysfs|$(cat "$d/gpu_busy_percent")|$(cat "$d/mem_info_vram_used" 2>/dev/null)|$(cat "$d/mem_info_vram_total" 2>/dev/null)|$t|$(cat "$d/product_name" 2>/dev/null)"; exit; fi; done; '
            + 'if [ "$1" = 1 ] && command -v nvidia-smi >/dev/null; then nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu,name --format=csv,noheader,nounits | head -1 | sed "s/, /|/g; s/^/nvidia|/"; '
            + 'elif command -v nvidia-smi >/dev/null; then echo "nvidia-off"; fi', "sh", root.gpuNvidia ? "1" : "0"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split("|");
                if (f[0] === "sysfs") {
                    root.gpuBusy = Number(f[1]) / 100;
                    root.gpuMemUsed = Number(f[2] || 0) / 1073741824;
                    root.gpuMemTotal = Number(f[3] || 0) / 1073741824;
                    root.gpuTemp = Number(f[4] || 0) / 1000;
                    root.gpuName = f[5] || "GPU";
                } else if (f[0] === "nvidia") {
                    root.gpuBusy = Number(f[1]) / 100;
                    root.gpuMemUsed = Number(f[2]) / 1024;
                    root.gpuMemTotal = Number(f[3]) / 1024;
                    root.gpuTemp = Number(f[4]);
                    root.gpuName = f[5] || "NVIDIA";
                } else {
                    root.gpuBusy = -1;
                    root.gpuName = text.trim() === "nvidia-off" ? "NVIDIA" : "";
                }
            }
        }
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
            const coreLines = lines.filter(l => /^cpu\d+ /.test(l));
            root.cores = Math.max(1, coreLines.length);
            if (root.detailed) {
                const now = coreLines.map(l => {
                    const c = l.trim().split(/\s+/).slice(1).map(Number);
                    return { idle: c[3] + (c[4] || 0), total: c.reduce((a, b) => a + b, 0) };
                });
                if (root._prevCores.length === now.length)
                    root.coreUsage = now.map((c, i) => {
                        const dt = c.total - root._prevCores[i].total;
                        return dt > 0 ? Math.max(0, Math.min(1, 1 - (c.idle - root._prevCores[i].idle) / dt)) : 0;
                    });
                root._prevCores = now;
            }
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
            root.memAvailable = avail / 1048576;
            root.memCached = (kb("Cached") + kb("Buffers")) / 1048576;
            root.memShared = kb("Shmem") / 1048576;
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
        onLoaded: {
            const f = text().trim().split(/\s+/);
            root.load = f.slice(0, 3).map(Number);
            root.processCount = Number((f[3] || "0/0").split("/")[1]) || 0;
        }
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
            if (!root._netStart)
                root._netStart = { rx, tx };
            root.netRxTotal = rx - root._netStart.rx;
            root.netTxTotal = tx - root._netStart.tx;
        }
    }

    FileView {
        id: cpuinfo
        path: "/proc/cpuinfo"
        onLoaded: {
            const mhz = (text().match(/^cpu MHz\s*:\s*([\d.]+)/gm) ?? []).map(l => parseFloat(l.split(":")[1]));
            root.cpuFreq = mhz.length ? mhz.reduce((a, b) => a + b, 0) / mhz.length : 0;
            root.cpuModel = (text().match(/^model name\s*:\s*(.+)$/m)?.[1] ?? "").replace(/\(R\)|\(TM\)|CPU @.*| Processor/g, "").replace(/\s+/g, " ").trim();
        }
    }

    // Temperature sensors: found once (and again every couple of minutes, for
    // hot-plugged ones) as "chip|label|path"; their files are then read directly
    // on each tick instead of starting a shell every 2 seconds.
    property var sensorPaths: []              // [{ chip, label, path }]
    property var sensorValues: ({})           // path → °C

    Process {
        id: sensorsProc
        running: true
        command: ["sh", "-c", "for d in /sys/class/hwmon/hwmon*; do n=$(cat \"$d/name\" 2>/dev/null); for t in \"$d\"/temp*_input; do [ -r \"$t\" ] || continue; l=$(cat \"${t%_input}_label\" 2>/dev/null); echo \"$n|$l|$t\"; done; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const list = [];
                for (const line of text.trim().split("\n")) {
                    const [chip, label, path] = line.split("|");
                    if (chip && path)
                        list.push({ chip, label: label || chip, path });
                }
                if (JSON.stringify(list) !== JSON.stringify(root.sensorPaths))
                    root.sensorPaths = list;
            }
        }
    }
    Timer {
        interval: 120000
        running: true
        repeat: true
        onTriggered: if (!sensorsProc.running) sensorsProc.running = true
    }

    Instantiator {
        id: sensorFiles
        model: root.sensorPaths
        delegate: FileView {
            required property var modelData
            path: modelData.path
            printErrors: false
            onLoaded: {
                const t = parseInt(text()) / 1000;
                const v = Object.assign({}, root.sensorValues);
                v[modelData.path] = t;
                root.sensorValues = v;
                sensorsDone.restart();
            }
        }
    }

    // once a round of readings is in: the list, and the headline temperature
    Timer {
        id: sensorsDone
        interval: 30
        onTriggered: {
            const list = [];
            for (const s of root.sensorPaths) {
                const t = root.sensorValues[s.path];
                if (!isNaN(t) && t > 0 && t < 150)
                    list.push({ chip: s.chip, label: s.label, temp: t });
            }
            root.sensors = list;
            // prefer CPU package sensors for the headline number
            const cpuish = list.filter(s => /k10temp|coretemp|zenpower|cpu|acpitz/i.test(s.chip) || /package|tctl|tdie/i.test(s.label));
            const pool = cpuish.length ? cpuish : list;
            root.temp = pool.length ? Math.max(...pool.map(s => s.temp)) : 0;
            root.tempHistory = root.push(root.tempHistory, root.temp);
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
                root.processes = text.trim().split("\n").slice(0, 8).map(l => {
                    const f = l.trim().split(/\s+/);
                    const n = f.length;
                    return { pid: Number(f[0]), name: f.slice(1, n - 2).join(" "), cpu: Number(f[n - 2]), mem: Number(f[n - 1]) };
                });
            }
        }
    }
}
