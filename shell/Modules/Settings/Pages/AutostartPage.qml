import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: I18n.tr("Auto-start")
    subtitle: I18n.tr("Apps and commands that start when you log in, from the standard XDG autostart folders.")

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
            title: I18n.tr("Start auto-start apps")
            subtitle: I18n.tr("Flamenco launches these at login. Turn off if systemd or another tool already does")
            icon: "rocket_launch"
            target: Settings.data.autostart
            key: "runEntries"
        }
    }

    Group {
        title: I18n.tr("At login")
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
            title: I18n.tr("Nothing starts at login yet")
            icon: "info"
        }
    }

    Group {
        title: I18n.tr("Add")
        SettingRow {
            title: I18n.tr("An app")
            icon: "apps"
            FDropdown {
                implicitWidth: 280
                options: page.addable
                placeholder: I18n.tr("Choose an app…")
                searchable: true
                onSelected: v => page.run([Paths.bin, "autostart", "add", v])
            }
        }
        SettingRow {
            title: I18n.tr("A command")
            subtitle: I18n.tr("Runs once at login, like a script or a tray app")
            icon: "terminal"
            ColumnLayout {
                spacing: 6
                FTextField {
                    implicitWidth: 280
                    placeholder: I18n.tr("Name")
                    text: page.newName
                    onEdited: t => page.newName = t
                }
                FTextField {
                    implicitWidth: 280
                    placeholder: I18n.tr("Command")
                    text: page.newCmd
                    onEdited: t => page.newCmd = t
                }
                FButton {
                    text: I18n.tr("Add command")
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

    Group {
        title: I18n.tr("Hooks")
        FText {
            Layout.fillWidth: true
            Layout.margins: Theme.sp3
            text: I18n.tr("Commands Flamenco runs when something happens. They get FLAMENCO_WALLPAPER, FLAMENCO_MODE (dark or light), FLAMENCO_PALETTE, FLAMENCO_ACCENT and FLAMENCO_EVENT, e.g. to theme another app: pywal -i \"$FLAMENCO_WALLPAPER\"")
            dim: true
            font.pixelSize: Theme.fsSm
            wrapMode: Text.Wrap
        }
        TextRow { title: I18n.tr("Wallpaper changes"); icon: "wallpaper"; target: Settings.data.hooks; key: "wallpaper"; placeholder: I18n.tr("A command") }
        TextRow { title: I18n.tr("Dark or light mode changes"); icon: "contrast"; target: Settings.data.hooks; key: "darkMode"; placeholder: I18n.tr("A command") }
        TextRow { title: I18n.tr("Colors come from a new wallpaper"); icon: "palette"; target: Settings.data.hooks; key: "colors"; placeholder: I18n.tr("A command") }
        TextRow { title: I18n.tr("The screen locks"); icon: "lock"; target: Settings.data.hooks; key: "lock"; placeholder: I18n.tr("A command") }
        TextRow { title: I18n.tr("The screen unlocks"); icon: "lock_open"; target: Settings.data.hooks; key: "unlock"; placeholder: I18n.tr("A command") }
        TextRow { title: I18n.tr("Flamenco starts"); icon: "rocket_launch"; target: Settings.data.hooks; key: "startup"; placeholder: I18n.tr("A command") }
    }
}
