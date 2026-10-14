import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

// Processor, memory and temperature as bars, and the uptime.
ColumnLayout {
    id: root
    property real k: 1
    property var spec
    property bool editing: false
    spacing: Math.round(Theme.sp3 * k)
    width: Math.round(250 * k)

    Repeater {
        model: [
            { icon: "memory", label: "Processor", value: SystemStats.cpu, text: Math.round(SystemStats.cpu * 100) + "%" },
            { icon: "memory_alt", label: "Memory", value: SystemStats.mem, text: SystemStats.memUsed.toFixed(1) + " / " + SystemStats.memTotal.toFixed(0) + " GiB" },
            { icon: "thermostat", label: "Temperature", value: Math.min(1, SystemStats.temp / 100), text: SystemStats.temp > 0 ? Math.round(SystemStats.temp) + "°C" : "–" }
        ]
        ColumnLayout {
            required property var modelData
            Layout.fillWidth: true
            spacing: Math.round(4 * root.k)
            RowLayout {
                Layout.fillWidth: true
                FIcon { icon: modelData.icon; size: Math.round(16 * root.k); color: Theme.accent }
                FText { Layout.fillWidth: true; text: modelData.label; font.pixelSize: Math.round(Theme.fsSm * root.k) }
                FText { text: modelData.text; mono: true; dim: true; font.pixelSize: Math.round(Theme.fsSm * root.k) }
            }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Math.round(6 * root.k)
                radius: height / 2
                color: Theme.alpha(Theme.text, 0.12)
                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, modelData.value))
                    height: parent.height
                    radius: height / 2
                    color: modelData.value > 0.85 ? Theme.error : Theme.accent
                    Behavior on width { Anim { duration: Theme.durLong } }
                }
            }
        }
    }
    FText {
        text: "Up " + SystemStats.uptimeText
        dim: true
        font.pixelSize: Math.round(Theme.fsXs * root.k)
    }
}
