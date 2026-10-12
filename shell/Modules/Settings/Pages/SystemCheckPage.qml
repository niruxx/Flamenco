import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services
import qs.Widgets

// Runs `flamenco doctor` and shows what's missing, with the command to install it.
Page {
    id: page
    title: "System check"
    subtitle: "Checks everything Flamenco uses. Required items must be fixed; the rest enable optional features."

    property var checks: []
    property string install: ""
    property bool ran: false
    readonly property var categories: [...new Set(checks.map(c => c.category))]
    readonly property int missingRequired: checks.filter(c => !c.ok && c.required).length
    readonly property int missingOptional: checks.filter(c => !c.ok && !c.required).length

    function run() {
        if (!doctor.running)
            doctor.running = true;
    }

    Component.onCompleted: run()

    Process {
        id: doctor
        command: [Paths.bin, "doctor", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    page.checks = d.checks;
                    page.install = d.install;
                    page.ran = true;
                } catch (e) {}
            }
        }
    }

    // summary
    FCard {
        Layout.fillWidth: true
        implicitHeight: sumRow.implicitHeight + Theme.sp4 * 2
        color: page.missingRequired > 0 ? Theme.alpha(Theme.error, 0.15) : Theme.alpha(Theme.success, 0.12)

        RowLayout {
            id: sumRow
            anchors.fill: parent
            anchors.margins: Theme.sp4
            spacing: Theme.sp3
            FIcon {
                icon: !page.ran ? "hourglass_empty" : page.missingRequired > 0 ? "error" : page.missingOptional > 0 ? "check_circle" : "verified"
                size: 32
                fill: 1
                color: page.missingRequired > 0 ? Theme.error : Theme.success
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                FText {
                    text: !page.ran ? "Checking…" : page.missingRequired > 0 ? page.missingRequired + " required item(s) need attention" : "Everything required is in place"
                    font.pixelSize: Theme.fsLg
                    font.weight: Font.Bold
                }
                FText {
                    visible: page.ran
                    text: page.missingOptional + " optional feature(s) not installed"
                    dim: true
                }
            }
            FIconButton {
                icon: "refresh"
                flat: false
                onClicked: page.run()
                RotationAnimation on rotation { running: doctor.running; from: 0; to: 360; duration: 900; loops: Animation.Infinite }
            }
        }
    }

    // install command
    Group {
        visible: page.install !== ""
        title: "Install what's missing"
        Rectangle {
            Layout.fillWidth: true
            Layout.margins: 12
            implicitHeight: cmdText.implicitHeight + 24
            radius: Theme.rMd
            color: Theme.bg
            FText {
                id: cmdText
                anchors.fill: parent
                anchors.margins: 12
                text: page.install
                mono: true
                wrapMode: Text.WrapAnywhere
                font.pixelSize: Theme.fsSm
            }
        }
        RowLayout {
            Layout.margins: 12
            Layout.topMargin: 0
            spacing: 8
            FButton {
                text: "Install in terminal"
                icon: "terminal"
                onClicked: Quickshell.execDetached(Paths.termHold(page.install + " && echo && echo 'Done. Re-run the check in Flamenco Settings.'"))
            }
            FButton {
                text: "Copy command"
                icon: "content_copy"
                variant: "tonal"
                onClicked: Quickshell.execDetached(["wl-copy", page.install])
            }
        }
    }

    // results by category
    Repeater {
        model: page.categories
        Group {
            id: grp
            required property string modelData
            title: modelData
            Repeater {
                model: page.checks.filter(c => c.category === grp.modelData)
                SettingRow {
                    id: crow
                    required property var modelData
                    title: modelData.name
                    subtitle: modelData.purpose + (!modelData.ok && modelData.hint ? "\n→ " + modelData.hint : "")
                    icon: modelData.ok ? "check_circle" : modelData.required ? "error" : "radio_button_unchecked"
                    FText {
                        text: crow.modelData.ok ? "OK" : crow.modelData.package ? crow.modelData.package + (crow.modelData.aur ? " (AUR)" : "") : crow.modelData.required ? "fix" : "optional"
                        color: crow.modelData.ok ? Theme.success : crow.modelData.required ? Theme.error : Theme.textDim
                        font.weight: Font.DemiBold
                        mono: !crow.modelData.ok && crow.modelData.package !== ""
                    }
                }
            }
        }
    }

    Group {
        title: "Logs"
        SettingRow {
            title: "Shell log"
            subtitle: "~/.cache/flamenco/shell.log, written when niri starts the shell"
            icon: "receipt_long"
            FButton {
                text: "View log"
                variant: "tonal"
                onClicked: Quickshell.execDetached(Paths.term(["sh", "-c", Paths.shellQuote(Paths.bin) + " logs | less +G"]))
            }
        }
        SettingRow {
            title: "niri config"
            subtitle: "Replace ~/.config/niri/config.kdl with a complete Flamenco config (your current one is backed up)"
            icon: "settings_applications"
            FButton {
                text: "Write config"
                variant: "outlined"
                onClicked: Quickshell.execDetached(Paths.termHold(Paths.shellQuote(Paths.bin) + " niri-config"))
            }
        }
    }
}
