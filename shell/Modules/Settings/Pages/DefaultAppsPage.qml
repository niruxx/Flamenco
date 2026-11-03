import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: I18n.tr("Default apps")
    subtitle: I18n.tr("Which app opens links, files and the terminal. Saved to mimeapps.list, which every desktop app reads.")

    property var categories: []
    property string status: ""

    Component.onCompleted: getter.running = true

    function choose(cat, app) {
        setter.command = [Paths.bin, "defaults", "set", cat.id, app, "--no-settings"];
        setter.running = true;
        const c = cat.candidates.find(x => x.id === app);
        if (cat.id === "terminal" && c && c.command)
            Settings.data.general.terminal = c.command;
    }

    // any terminal command (gnome-console is `kgx`, `konsole`, `foot -o …`); Mod+T follows it
    function setTerminal(cmd) {
        if (!cmd)
            return;
        pendingTerminal = cmd;
        setter.command = [Paths.bin, "terminal", "set", cmd, "--no-settings"];
        setter.running = true;
    }
    // saved once `flamenco terminal set` has checked it's installed
    property string pendingTerminal: ""

    Process {
        id: getter
        command: [Paths.bin, "defaults", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    page.categories = JSON.parse(text).categories;
                } catch (e) {}
            }
        }
    }

    Process {
        id: setter
        stdout: StdioCollector {
            onStreamFinished: page.status = text.trim()
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) page.status = text.trim().split("\n").pop()
        }
        onExited: code => {
            if (code === 0 && page.pendingTerminal)
                Settings.data.general.terminal = page.pendingTerminal;
            page.pendingTerminal = "";
            getter.running = true;
        }
    }

    Group {
        title: I18n.tr("Links")
        SwitchRow {
            title: I18n.tr("Ask which browser")
            subtitle: Settings.data.general.browserPicker ? I18n.tr("Links you click elsewhere ask which browser opens them (with \"always\" to stop asking)") : I18n.tr("Off: links open in the default browser")
            icon: "travel_explore"
            target: Settings.data.general
            key: "browserPicker"
            onEdited: Quickshell.execDetached([Paths.bin, "browser-picker", Settings.data.general.browserPicker ? "on" : "off"])
        }
    }

    Group {
        Repeater {
            model: page.categories
            delegate: SettingRow {
                id: row
                required property var modelData
                title: modelData.label
                subtitle: modelData.candidates.length ? "" : I18n.tr("No installed app handles this")
                icon: modelData.icon
                RowLayout {
                    spacing: 8
                    AppIcon {
                        implicitSize: 24
                        visible: !!row.modelData.current
                        name: (row.modelData.candidates.find(c => c.id === row.modelData.current) || {}).icon || ""
                    }
                    FDropdown {
                        implicitWidth: 260
                        options: row.modelData.candidates.map(c => ({ value: c.id, label: c.name }))
                        current: row.modelData.current
                        placeholder: I18n.tr("Not set")
                        onSelected: v => page.choose(row.modelData, v)
                    }
                }
            }
        }
    }

    Group {
        title: I18n.tr("Terminal")
        SettingRow {
            title: I18n.tr("Terminal command")
            subtitle: I18n.tr("Any terminal, with options if you like: kgx (GNOME Console), konsole, ptyxis, foot… Super+T and Super+Return open it, and so do apps that need a terminal.")
            icon: "terminal"
            Row {
                spacing: 8
                FTextField {
                    id: termField
                    implicitWidth: 220
                    icon: "terminal"
                    placeholder: "kgx"
                    text: Settings.data.general.terminal
                    onAccepted: page.setTerminal(text.trim())
                }
                FButton {
                    text: I18n.tr("Set")
                    variant: "tonal"
                    implicitHeight: 38
                    disabled: setter.running || termField.text.trim() === "" || termField.text.trim() === Settings.data.general.terminal
                    onClicked: page.setTerminal(termField.text.trim())
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
