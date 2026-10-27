import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

// Settings → System check → Monitoring levels: when the CPU/RAM widget, the
// Performance panel and the system hub turn the warning color, then the critical one.
Group {
    id: root
    title: I18n.tr("Monitoring levels")
    readonly property var m: Settings.data.monitor

    Repeater {
        model: [
            { k: "cpu", t: I18n.tr("Processor"), i: "memory", unit: "%", now: Math.round(SystemStats.cpu * 100) },
            { k: "mem", t: I18n.tr("Memory"), i: "developer_board", unit: "%", now: Math.round(SystemStats.mem * 100) },
            { k: "temp", t: I18n.tr("Temperature"), i: "thermostat", unit: "°C", now: Math.round(SystemStats.temp) },
            { k: "gpu", t: I18n.tr("Graphics card"), i: "videogame_asset", unit: "%", now: SystemStats.gpuBusy >= 0 ? Math.round(SystemStats.gpuBusy * 100) : -1 },
            { k: "disk", t: I18n.tr("Disk space used"), i: "hard_drive", unit: "%", now: -1 }
        ]
        SettingRow {
            id: lrow
            required property var modelData
            title: modelData.t
            subtitle: I18n.tr("Warning, then critical") + (modelData.now >= 0 ? " · now " + modelData.now + modelData.unit : "")
            icon: modelData.i
            Row {
                spacing: 6
                Repeater {
                    model: [{ s: "Warn", tone: Theme.warning }, { s: "Crit", tone: Theme.error }]
                    Row {
                        required property var modelData
                        spacing: 4
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 10; height: 10; radius: 5
                            color: parent.modelData.tone
                        }
                        FTextField {
                            implicitWidth: 70
                            implicitHeight: 34
                            text: String(root.m[lrow.modelData.k + parent.modelData.s] ?? "")
                            onEditingFinished: {
                                const v = parseInt(text);
                                if (!isNaN(v) && v > 0 && v <= 150)
                                    root.m[lrow.modelData.k + parent.modelData.s] = v;
                            }
                        }
                    }
                }
                FText { anchors.verticalCenter: parent.verticalCenter; text: lrow.modelData.unit; dim: true }
            }
        }
    }
    ColorChoiceRow {
        title: I18n.tr("Warning color")
        icon: "warning"
        target: root.m
        key: "warnColor"
        choices: [{ value: "", label: I18n.tr("Theme's") }]
        swatches: ["#f5c542", "#ff8a4c", "#efb73e", "#e6b450"]
    }
    ColorChoiceRow {
        title: I18n.tr("Critical color")
        icon: "error"
        target: root.m
        key: "critColor"
        choices: [{ value: "", label: I18n.tr("Theme's") }]
        swatches: ["#ff5d73", "#e5534b", "#df382c", "#ff4f8b"]
    }
}
