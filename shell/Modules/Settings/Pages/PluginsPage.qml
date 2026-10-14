import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: "Plugins"
    subtitle: "Bar widgets and launcher extensions made by others, or by you. Plugins live in ~/.config/flamenco/plugins and run with your permissions, so only turn on ones you trust."

    property string status: ""
    Component.onCompleted: Plugins.refresh()

    function cli(args) {
        status = "";
        runner.command = [Paths.bin, "plugins"].concat(args);
        runner.running = true;
    }

    Process {
        id: runner
        stdout: StdioCollector { id: out }
        stderr: StdioCollector { id: err }
        onExited: {
            page.status = (err.text.trim() || out.text.trim()).replace(/^flamenco: /, "");
            Plugins.refresh();
        }
    }

    Group {
        title: "Installed"
        SettingRow {
            visible: Plugins.all.length === 0
            title: "No plugins yet"
            subtitle: "Install one below, or create an example to start from"
            icon: "extension"
        }
        Repeater {
            model: Plugins.all
            SettingRow {
                id: pr
                required property var modelData
                readonly property bool on: Plugins.enabledIds.includes(modelData.id)
                title: (modelData.name || modelData.id) + (modelData.version ? " " + modelData.version : "")
                subtitle: modelData.error ? "⚠ " + modelData.error
                    : (modelData.description || "") + " · " + [modelData.bar ? "bar widget" : "", modelData.launcher ? "launcher: type " + modelData.launcher.prefix : ""].filter(Boolean).join(", ")
                    + (modelData.author ? " · by " + modelData.author : "")
                icon: modelData.error ? "extension_off" : "extension"
                Row {
                    spacing: 4
                    FIconButton {
                        icon: "folder_open"
                        size: 32
                        onClicked: Quickshell.execDetached(["xdg-open", pr.modelData.dir])
                    }
                    FIconButton {
                        icon: "delete"
                        size: 32
                        iconColor: Theme.error
                        onClicked: {
                            Plugins.setEnabled(pr.modelData.id, false);
                            page.cli(["remove", pr.modelData.id]);
                        }
                    }
                    FSwitch {
                        anchors.verticalCenter: parent.verticalCenter
                        enabled: pr.modelData.ok
                        checked: pr.on
                        onToggled: c => Plugins.setEnabled(pr.modelData.id, c)
                    }
                }
            }
        }
        SettingRow {
            title: "Reload"
            subtitle: "After editing a plugin's files"
            icon: "refresh"
            FButton {
                text: "Reload"
                variant: "tonal"
                onClicked: Plugins.refresh()
            }
        }
    }

    Group {
        title: "Add"
        SettingRow {
            title: "Install"
            subtitle: "A git address (https://…) or a folder with a manifest.json. It starts turned off."
            icon: "download"
            Row {
                spacing: 8
                FTextField { id: src; implicitWidth: 300; placeholder: "https://github.com/someone/flamenco-plugin" }
                FButton {
                    text: "Install"
                    disabled: src.text.trim() === "" || runner.running
                    onClicked: {
                        page.cli(["install", src.text.trim()]);
                        src.text = "";
                    }
                }
            }
        }
        SettingRow {
            title: "Create a plugin"
            subtitle: "Makes a working example (a bar widget and a launcher extension) to edit"
            icon: "add_circle"
            Row {
                spacing: 8
                FTextField { id: newId; implicitWidth: 160; placeholder: "my-plugin" }
                FButton {
                    text: "Create"
                    variant: "tonal"
                    disabled: newId.text.trim() === "" || runner.running
                    onClicked: {
                        page.cli(["new", newId.text.trim().toLowerCase()]);
                        newId.text = "";
                    }
                }
            }
        }
        SettingRow {
            visible: page.status !== ""
            title: page.status
            icon: "info"
        }
        SettingRow {
            title: "Writing plugins"
            subtitle: "docs/plugins.md in Flamenco's source describes the manifest, the api object bar widgets get, and the launcher's JSON results."
            icon: "menu_book"
        }
    }
}
