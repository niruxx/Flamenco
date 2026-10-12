import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets

Page {
    id: page
    title: "About"
    property var checks: []

    Component.onCompleted: doctor.running = true

    Process {
        id: doctor
        command: [Paths.bin, "doctor", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    page.checks = JSON.parse(text);
                } catch (e) {}
            }
        }
    }

    RowLayout {
        spacing: Theme.sp4
        Rectangle {
            width: 72; height: 72; radius: Theme.rXl
            gradient: Gradient {
                GradientStop { position: 0; color: Theme.accent }
                GradientStop { position: 1; color: Theme.accent2 }
            }
            FIcon { anchors.centerIn: parent; icon: "local_fire_department"; size: 40; fill: 1; color: Theme.onAccent }
        }
        ColumnLayout {
            FText { text: "Flamenco Shell"; font.pixelSize: Theme.fsXl; font.weight: Font.Bold }
            FText { text: "A Quickshell desktop shell for niri"; dim: true }
            FText { text: "Config: " + Paths.configDir; dim: true; font.pixelSize: Theme.fsSm; mono: true }
        }
    }

    Group {
        title: "Dependencies"
        Repeater {
            model: page.checks
            SettingRow {
                required property var modelData
                title: modelData.name
                subtitle: modelData.purpose
                icon: modelData.ok ? "check_circle" : modelData.required ? "error" : "radio_button_unchecked"
                FText {
                    text: modelData.ok ? "found" : modelData.required ? "missing" : "optional"
                    color: modelData.ok ? Theme.success : modelData.required ? Theme.error : Theme.textDim
                    font.weight: Font.DemiBold
                }
            }
        }
        SettingRow {
            visible: page.checks.length === 0
            title: "Running `flamenco doctor`…"
            icon: "hourglass_empty"
        }
    }
}
