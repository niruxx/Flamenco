import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

// Opened from the CPU/RAM bar widget: usage history, temperatures, memory,
// disks, network and the busiest processes.
Variants {
    model: Quickshell.screens

    OverlayPanel {
        id: panel
        name: "performance"
        hAlign: "right"
        cardWidth: 440

        // sensors / disks / processes are only polled while this is open
        // separate Connections so OverlayPanel's own shouldShow handler keeps running
        Connections {
            target: panel
            function onShouldShowChanged() {
                SystemStats.detailed = panel.shouldShow;
            }
        }

        ColumnLayout {
            width: parent.width
            spacing: Theme.sp3

            RowLayout {
                Layout.fillWidth: true
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    FText { text: "Performance"; font.pixelSize: Theme.fsXl; font.weight: Font.Bold }
                    FText { text: "Up " + SystemStats.uptimeText; dim: true; font.pixelSize: Theme.fsSm }
                }
                FButton {
                    text: "btop"
                    icon: "monitoring"
                    variant: "tonal"
                    implicitHeight: 32
                    onClicked: {
                        Panels.close();
                        Quickshell.execDetached(Paths.term(["btop"]));
                    }
                }
            }

            FScroll {
                Layout.fillWidth: true
                implicitHeight: Math.min(contentHeight, 620)
                contentHeight: body.implicitHeight

                ColumnLayout {
                    id: body
                    width: parent.width
                    spacing: Theme.sp3

                    PerfSection {
                        title: "CPU"
                        icon: "memory"
                        RowLayout {
                            Layout.fillWidth: true
                            FText { text: Math.round(SystemStats.cpu * 100) + "%"; font.pixelSize: Theme.fsXxl; font.weight: Font.Bold; color: SystemStats.cpu > 0.85 ? Theme.error : Theme.text }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                FText { Layout.alignment: Qt.AlignRight; text: SystemStats.cores + " cores" + (SystemStats.cpuFreq > 0 ? " · " + (SystemStats.cpuFreq / 1000).toFixed(2) + " GHz" : ""); dim: true; font.pixelSize: Theme.fsSm }
                                FText { Layout.alignment: Qt.AlignRight; text: "load " + SystemStats.load.map(v => v.toFixed(2)).join("  "); dim: true; mono: true; font.pixelSize: Theme.fsSm }
                            }
                        }
                        FSparkline {
                            Layout.fillWidth: true
                            implicitHeight: 54
                            values: SystemStats.cpuHistory
                            color: Theme.accent
                        }
                    }

                    PerfSection {
                        title: "Temperatures"
                        icon: "thermostat"
                        FText {
                            visible: SystemStats.sensors.length === 0
                            text: "No temperature sensors reported (common in virtual machines)"
                            dim: true
                            wrapMode: Text.Wrap
                            Layout.fillWidth: true
                        }
                        Repeater {
                            model: SystemStats.sensors.slice(0, 8)
                            PerfMeter {
                                required property var modelData
                                label: modelData.chip + (modelData.label !== modelData.chip ? " · " + modelData.label : "")
                                detail: Math.round(modelData.temp) + " °C"
                                value: modelData.temp / 100
                                barColor: modelData.temp > 80 ? Theme.error : modelData.temp > 65 ? Theme.warning : Theme.success
                            }
                        }
                    }

                    PerfSection {
                        title: "Memory"
                        icon: "developer_board"
                        PerfMeter {
                            label: "RAM"
                            detail: SystemStats.memUsed.toFixed(1) + " / " + SystemStats.memTotal.toFixed(1) + " GiB"
                            value: SystemStats.mem
                            barColor: Theme.accent2
                        }
                        PerfMeter {
                            visible: SystemStats.swapTotal > 0
                            label: "Swap"
                            detail: SystemStats.swapUsed.toFixed(1) + " / " + SystemStats.swapTotal.toFixed(1) + " GiB"
                            value: SystemStats.swapTotal > 0 ? SystemStats.swapUsed / SystemStats.swapTotal : 0
                            barColor: Theme.accent3
                        }
                        FSparkline {
                            Layout.fillWidth: true
                            implicitHeight: 32
                            values: SystemStats.memHistory
                            color: Theme.accent2
                        }
                    }

                    PerfSection {
                        title: "Disks"
                        icon: "hard_drive"
                        visible: SystemStats.disks.length > 0
                        Repeater {
                            model: SystemStats.disks
                            PerfMeter {
                                required property var modelData
                                label: modelData.mount
                                detail: SystemStats.formatBytes(modelData.used) + " / " + SystemStats.formatBytes(modelData.size)
                                value: modelData.size > 0 ? modelData.used / modelData.size : 0
                            }
                        }
                    }

                    PerfSection {
                        title: "Network"
                        icon: "swap_vert"
                        RowLayout {
                            Layout.fillWidth: true
                            FIcon { icon: "arrow_downward"; size: 16; color: Theme.success }
                            FText { text: SystemStats.formatBytes(SystemStats.netDown, true); mono: true; Layout.fillWidth: true }
                            FIcon { icon: "arrow_upward"; size: 16; color: Theme.accent }
                            FText { text: SystemStats.formatBytes(SystemStats.netUp, true); mono: true }
                        }
                        FSparkline {
                            Layout.fillWidth: true
                            implicitHeight: 32
                            values: SystemStats.netHistory
                            max: Math.max(1024, ...SystemStats.netHistory)
                            color: Theme.success
                        }
                    }

                    PerfSection {
                        title: "Top processes"
                        icon: "list"
                        Repeater {
                            model: SystemStats.processes
                            RowLayout {
                                required property var modelData
                                Layout.fillWidth: true
                                spacing: 8
                                FText { text: modelData.name; Layout.fillWidth: true; elide: Text.ElideRight }
                                FText { text: modelData.cpu.toFixed(1) + "%"; mono: true; dim: true; font.pixelSize: Theme.fsSm; Layout.preferredWidth: 56; horizontalAlignment: Text.AlignRight }
                                FText { text: modelData.mem.toFixed(1) + "%"; mono: true; dim: true; font.pixelSize: Theme.fsSm; Layout.preferredWidth: 56; horizontalAlignment: Text.AlignRight }
                            }
                        }
                        FText {
                            visible: SystemStats.processes.length === 0
                            text: "Loading…"
                            dim: true
                        }
                    }
                }
            }
        }
    }
}
