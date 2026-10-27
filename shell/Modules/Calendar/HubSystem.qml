import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

// The Hub's System page: CPU, memory, temperatures, every core, the network,
// the GPU, the busiest processes and the machine, each with its history.
GridLayout {
    id: root

    property bool live: false                  // showing right now: collect the detailed stats
    columns: 3
    rowSpacing: Theme.sp3
    columnSpacing: Theme.sp3

    onLiveChanged: {
        SystemStats.hold(live);
    }
    Component.onDestruction: if (live) SystemStats.hold(false)

    readonly property var rootDisk: SystemStats.disks.find(d => d.mount === "/") ?? SystemStats.disks[0] ?? null
    function gb(v) {
        return v >= 100 ? Math.round(v) + "G" : v.toFixed(1) + "G";
    }

    // a card: an icon in a tinted square, the title, a big value on the right
    component Panel: Rectangle {
        id: pnl
        property string icon
        property string title
        property string value
        property color tint: Theme.accent
        default property alias content: body.data
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredWidth: 1
        implicitHeight: head.height + body.childrenRect.height + 36
        radius: Theme.rXl
        color: Theme.alpha(Theme.text, 0.035)
        border.width: 1
        border.color: Theme.alpha(Theme.text, 0.07)

        Row {
            id: head
            x: 16
            y: 14
            spacing: 10
            Rectangle {
                width: 28
                height: 28
                radius: 8
                color: Theme.alpha(pnl.tint, 0.18)
                FIcon { anchors.centerIn: parent; icon: pnl.icon; size: 17; color: pnl.tint; fill: 1 }
            }
            FText { anchors.verticalCenter: parent.verticalCenter; text: pnl.title; font.weight: Font.Bold; font.pixelSize: Theme.fsMd }
        }
        FText {
            anchors.right: parent.right
            anchors.rightMargin: 16
            y: 10
            text: pnl.value
            color: pnl.tint
            font.pixelSize: Theme.fsXl
            font.weight: Font.Bold
        }
        Item {
            id: body
            x: 16
            y: head.y + head.height + 10
            width: pnl.width - 32
            height: pnl.height - y - 14
        }
    }

    // "label ……… value" rows
    component Facts: Column {
        property var rows: []                  // [[label, value]]
        width: parent ? parent.width : 0
        spacing: 3
        Repeater {
            model: parent.rows
            Item {
                required property var modelData
                width: parent.width
                height: 18
                FText { text: modelData[0]; dim: true; font.pixelSize: Theme.fsSm }
                FText { anchors.right: parent.right; text: modelData[1]; mono: true; font.pixelSize: Theme.fsSm; font.weight: Font.DemiBold }
            }
        }
    }

    // ── CPU ──
    Panel {
        icon: "memory"
        title: I18n.tr("CPU")
        value: Math.round(SystemStats.cpu * 100) + "%"
        tint: Theme.accent
        Column {
            width: parent.width
            spacing: 8
            FText { width: parent.width; text: (SystemStats.cpuModel || "Processor") + " · " + SystemStats.cores + " threads"; dim: true; font.pixelSize: Theme.fsXs; elide: Text.ElideRight }
            Facts {
                rows: [["Clock", SystemStats.cpuFreq ? (SystemStats.cpuFreq / 1000).toFixed(2) + " GHz avg" : "—"],
                    ["Load (1/5/15)", SystemStats.load.map(v => v.toFixed(2)).join("  ")],
                    ["Processes", String(SystemStats.processCount || "—")],
                    ["Busiest core", SystemStats.coreUsage.length ? Math.round(Math.max(...SystemStats.coreUsage) * 100) + "%" : "—"],
                    ["Temperature", Math.round(SystemStats.temp) + " °C"]]
            }
            FLineGraph { width: parent.width; height: 44; values: SystemStats.cpuHistory; color: Theme.accent }
        }
    }

    // ── memory ──
    Panel {
        icon: "developer_board"
        title: I18n.tr("Memory")
        value: Math.round(SystemStats.mem * 100) + "%"
        tint: Theme.warning
        Column {
            width: parent.width
            spacing: 8
            FText { text: root.gb(SystemStats.memUsed) + " / " + root.gb(SystemStats.memTotal) + (SystemStats.swapTotal > 0 ? " · swap " + Math.round(SystemStats.swapUsed / SystemStats.swapTotal * 100) + "%" : ""); dim: true; font.pixelSize: Theme.fsXs }
            Facts {
                rows: [["Used", root.gb(SystemStats.memUsed) + " / " + root.gb(SystemStats.memTotal)],
                    ["Available", root.gb(SystemStats.memAvailable)],
                    ["Cache", root.gb(SystemStats.memCached)],
                    ["Shared", SystemStats.memShared < 1 ? Math.round(SystemStats.memShared * 1024) + "M" : root.gb(SystemStats.memShared)],
                    ["Swap", root.gb(SystemStats.swapUsed) + " / " + root.gb(SystemStats.swapTotal)]]
            }
            FLineGraph { width: parent.width; height: 44; values: SystemStats.memHistory; color: Theme.warning }
        }
    }

    // ── temperatures ──
    Panel {
        icon: "thermostat"
        title: I18n.tr("Temperature")
        value: Math.round(SystemStats.temp) + "°C"
        tint: Theme.accent2
        Column {
            width: parent.width
            spacing: 8
            Facts {
                rows: SystemStats.sensors.slice().sort((a, b) => b.temp - a.temp).slice(0, 4).map(s => [s.label === s.chip ? s.chip : s.label, Math.round(s.temp) + " °C"])
                    .concat([["Power profile", Power.profileName], ["Peak (last 90 s)", Math.round(SystemStats.tempPeak) + " °C"]])
            }
            FLineGraph { width: parent.width; height: 44; values: SystemStats.tempHistory; max: 100; color: Theme.accent2 }
        }
    }

    // ── cores ──
    Panel {
        icon: "grid_view"
        title: I18n.tr("Cores")
        value: SystemStats.cores + ""
        tint: Theme.accent
        Grid {
            id: coreGrid
            width: parent.width
            columns: Math.min(8, Math.max(4, Math.ceil(Math.sqrt(SystemStats.cores * 1.6))))
            spacing: 6
            readonly property real cell: (width - (columns - 1) * spacing) / columns
            Repeater {
                model: SystemStats.coreUsage
                Rectangle {
                    required property real modelData
                    width: coreGrid.cell
                    height: 32
                    radius: 8
                    color: Theme.alpha(modelData > 0.85 ? Theme.error : Theme.accent, 0.08 + modelData * 0.5)
                    FText {
                        anchors.centerIn: parent
                        text: Math.round(modelData * 100)
                        mono: true
                        font.pixelSize: Theme.fsXs
                        font.weight: Font.Bold
                        color: modelData > 0.55 ? Theme.onAccent : Theme.text
                    }
                }
            }
        }
    }

    // ── network ──
    Panel {
        icon: "swap_vert"
        title: I18n.tr("Network")
        tint: Theme.accent3
        Column {
            width: parent.width
            spacing: 8
            Item {
                width: parent.width
                height: 22
                FText { text: "↓ " + SystemStats.formatBytes(SystemStats.netDown, true); mono: true; font.weight: Font.Bold }
                FText { anchors.right: parent.right; text: "↑ " + SystemStats.formatBytes(SystemStats.netUp, true); mono: true; font.weight: Font.Bold }
            }
            Facts {
                rows: [["Connection", Network.label],
                    ["Signal", Network.ethernet ? "wired" : Network.signal + "%"],
                    ["Interface", SystemStats.netIface || "—"],
                    ["IP address", SystemStats.netIp || "—"],
                    ["Since shell start", "↓ " + SystemStats.formatBytes(SystemStats.netRxTotal) + "  ↑ " + SystemStats.formatBytes(SystemStats.netTxTotal)]]
            }
            FLineGraph { width: parent.width; height: 44; values: SystemStats.netHistory; max: 0; color: Theme.accent3 }
        }
    }

    // ── GPU ──
    Panel {
        icon: "videogame_asset"
        title: I18n.tr("GPU")
        value: SystemStats.gpuBusy >= 0 ? Math.round(SystemStats.gpuBusy * 100) + "%" : ""
        tint: SystemStats.gpuBusy >= 0 ? SystemStats.colorFor("gpu", SystemStats.gpuBusy * 100, Theme.accent2) : Theme.accent2
        Column {
            width: parent.width
            spacing: 8
            // NVIDIA: asking it keeps the card awake, so it's off until switched on
            Item {
                visible: SystemStats.gpuName === "NVIDIA" || SystemStats.gpuNvidia
                width: parent.width
                height: 30
                FText { anchors.verticalCenter: parent.verticalCenter; text: I18n.tr("Watch the NVIDIA GPU"); font.pixelSize: Theme.fsSm }
                FSwitch {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    checked: SystemStats.gpuNvidia
                    onToggled: c => SystemStats.gpuNvidia = c
                }
            }
            FText {
                visible: SystemStats.gpuBusy < 0
                width: parent.width
                wrapMode: Text.Wrap
                dim: true
                font.pixelSize: Theme.fsSm
                text: SystemStats.gpuName === "NVIDIA" ? I18n.tr("Asking nvidia-smi keeps the GPU awake (and using power), so it's off until you switch it on.")
                    : "No GPU usage to show: AMD and Intel cards report it through the kernel, NVIDIA through nvidia-smi."
            }
            Facts {
                visible: SystemStats.gpuBusy >= 0
                rows: [["Card", SystemStats.gpuName || "GPU"],
                    ["Busy", Math.round(SystemStats.gpuBusy * 100) + "%"],
                    ["Video memory", SystemStats.gpuMemTotal ? root.gb(SystemStats.gpuMemUsed) + " / " + root.gb(SystemStats.gpuMemTotal) : "—"],
                    ["Temperature", SystemStats.gpuTemp ? Math.round(SystemStats.gpuTemp) + " °C" : "—"]]
            }
        }
    }

    // ── top processes ──
    Panel {
        Layout.columnSpan: 2
        Layout.preferredWidth: 2
        icon: "list"
        title: I18n.tr("Top processes")
        tint: Theme.accent
        Column {
            width: parent.width
            spacing: 6
            Repeater {
                model: SystemStats.processes
                Item {
                    required property var modelData
                    width: parent.width
                    height: 20
                    FText { width: 160; text: modelData.name; mono: true; font.pixelSize: Theme.fsSm; elide: Text.ElideRight }
                    Rectangle {
                        x: 170
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 170 - 130
                        height: 5
                        radius: 3
                        color: Theme.alpha(Theme.text, 0.08)
                        Rectangle {
                            width: Math.max(5, parent.width * Math.min(1, modelData.cpu / Math.max(1, ...SystemStats.processes.map(p => p.cpu))))
                            height: parent.height
                            radius: 3
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0; color: Theme.accent3 }
                                GradientStop { position: 1; color: Theme.accent }
                            }
                        }
                    }
                    FText { anchors.right: parent.right; anchors.rightMargin: 60; text: modelData.cpu.toFixed(1) + "%"; mono: true; font.pixelSize: Theme.fsSm; color: Theme.accent }
                    FText { anchors.right: parent.right; text: modelData.mem.toFixed(1) + "%"; mono: true; dim: true; font.pixelSize: Theme.fsSm }
                }
            }
        }
    }

    // ── the machine ──
    Panel {
        icon: "info"
        title: SystemStats.hostname || "This computer"
        tint: Theme.accent3
        Facts {
            rows: [["Kernel", SystemStats.kernel || "—"],
                ["Uptime", SystemStats.uptimeText],
                ["Disk " + (root.rootDisk?.mount ?? "/"), root.rootDisk ? SystemStats.formatBytes(root.rootDisk.used) + " / " + SystemStats.formatBytes(root.rootDisk.size) : "—"],
                ["Battery", Power.hasBattery ? Power.percent + "% · " + (Power.charging ? "charging" : Power.onBattery ? "on battery" : "plugged in") : "none"],
                ["Profile", Power.profileName],
                ["Draw", Power.device?.changeRate ? Math.abs(Power.device.changeRate).toFixed(1) + " W" : "—"]]
        }
    }
}
