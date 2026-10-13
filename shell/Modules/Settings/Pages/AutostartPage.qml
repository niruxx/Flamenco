import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: "Auto-start"
    subtitle: "Apps and commands that start when you log in, from the standard XDG autostart folders."

    property var entries: []
    property string status: ""
    property string newName: ""
    property string newCmd: ""
    readonly property var addable: Apps.all.filter(a => !entries.some(e => e.id === a.id + ".desktop" && e.enabled)).map(a => ({ value: a.id, label: a.name }))

    Component.onCompleted: reload()

    function reload() {
        lister.running = true;
    }
    function run(cmd) {
        runner.command = cmd;
        runner.running = true;
    }

    Process {
        id: lister
        command: [Paths.bin, "autostart", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    page.entries = JSON.parse(text).filter(e => e.thisDesktop || e.user);
                } catch (e) {}
            }
        }
    }

    Process {
        id: runner
        stdout: StdioCollector {
            onStreamFinished: page.status = text.trim()
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) page.status = text.trim().split("\n").pop()
        }
        onExited: page.reload()
    }

    Group {
        SwitchRow {
            title: "Start auto-start apps"
            subtitle: "Flamenco launches these at login. Turn off if systemd or another tool already does"
            icon: "rocket_launch"
            target: Settings.data.autostart
            key: "runEntries"
        }
    }

    Group {
        title: "At login"
        Repeater {
            model: page.entries
            delegate: SettingRow {
                id: row
                required property var modelData
                title: modelData.name || modelData.id
                subtitle: (modelData.comment || modelData.exec) + (modelData.system ? "" : " · added by you")
                icon: ""
                RowLayout {
                    spacing: 6
                    AppIcon {
                        implicitSize: 24
                        name: row.modelData.icon
                    }
                    FSwitch {
                        checked: row.modelData.enabled
                        onToggled: c => page.run([Paths.bin, "autostart", "set", row.modelData.id, c ? "on" : "off"])
                    }
                    FIconButton {
                        icon: "delete"
                        visible: !row.modelData.system
                        onClicked: page.run([Paths.bin, "autostart", "remove", row.modelData.id])
                    }
                }
            }
        }
        SettingRow {
            visible: page.entries.length === 0
            title: "Nothing starts at login yet"
            icon: "info"
        }
    }

    Group {
        title: "Add"
        SettingRow {
            title: "An app"
            icon: "apps"
            FDropdown {
                implicitWidth: 280
                options: page.addable
                placeholder: "Choose an app…"
                searchable: true
                onSelected: v => page.run([Paths.bin, "autostart", "add", v])
            }
        }
        SettingRow {
            title: "A command"
            subtitle: "Runs once at login, like a script or a tray app"
            icon: "terminal"
            ColumnLayout {
                spacing: 6
                FTextField {
                    implicitWidth: 280
                    placeholder: "Name"
                    text: page.newName
                    onEdited: t => page.newName = t
                }
                FTextField {
                    implicitWidth: 280
                    placeholder: "Command"
                    text: page.newCmd
                    onEdited: t => page.newCmd = t
                }
                FButton {
                    text: "Add command"
                    icon: "add"
                    variant: "tonal"
                    disabled: !page.newName.trim() || !page.newCmd.trim()
                    onClicked: {
                        page.run([Paths.bin, "autostart", "add-command", page.newName.trim(), page.newCmd.trim()]);
                        page.newName = "";
                        page.newCmd = "";
                    }
                }
            }
        }
    }

    FText {
        Layout.fillWidth: true
        visible: page.status !== ""
        text: page.status
        dim: true
        wrapMode: Text.Wrap
    }
}
