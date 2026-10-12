import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: "Printers"
    subtitle: "Printing goes through CUPS. Starting or enabling the service needs your password, so those open a terminal."

    property var st: ({ installed: true, service: {}, socket: {}, printers: [], jobs: [], configTool: "" })
    property bool loaded: false
    readonly property bool running: (st.service?.active ?? false) || (st.socket?.active ?? false)
    readonly property string bin: Paths.shellQuote(Paths.bin)

    function refresh() {
        if (!proc.running)
            proc.running = true;
    }
    function cli(args) {
        Quickshell.execDetached([Paths.bin, "printers", ...args]);
        later.restart();
    }
    function inTerminal(args) {
        Quickshell.execDetached(Paths.termHold(page.bin + " printers " + args.join(" ")));
        later.restart();
    }

    Component.onCompleted: refresh()

    Process {
        id: proc
        command: [Paths.bin, "printers", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    page.st = JSON.parse(text);
                    page.loaded = true;
                } catch (e) {}
            }
        }
    }
    Timer { interval: 5000; running: true; repeat: true; onTriggered: page.refresh() }
    Timer { id: later; interval: 1500; onTriggered: page.refresh() }

    // not installed
    Group {
        visible: page.loaded && !page.st.installed
        title: "CUPS isn't installed"
        SettingRow {
            title: "Install printing support"
            subtitle: "cups, cups-pdf (print to PDF) and system-config-printer (adding printers)"
            icon: "print_disabled"
            FButton {
                text: "Install"
                icon: "download"
                onClicked: Quickshell.execDetached(Paths.termHold("sudo pacman -S --needed cups cups-pdf system-config-printer && sudo systemctl enable --now cups.socket"))
            }
        }
    }

    Group {
        visible: page.st.installed
        title: "Service"
        SettingRow {
            title: page.running ? "CUPS is running" : "CUPS is stopped"
            subtitle: "cups.service " + (page.st.service?.raw ?? "?") + " · cups.socket " + (page.st.socket?.raw ?? "?") + ((page.st.socket?.enabled || page.st.service?.enabled) ? " · starts at boot" : " · doesn't start at boot")
            icon: page.running ? "print" : "print_disabled"
            Row {
                spacing: 6
                FButton {
                    visible: !page.running
                    text: "Start"
                    onClicked: page.inTerminal(["service", "start"])
                }
                FButton {
                    visible: page.running
                    text: "Stop"
                    variant: "outlined"
                    onClicked: page.inTerminal(["service", "stop"])
                }
                FButton {
                    text: (page.st.socket?.enabled || page.st.service?.enabled) ? "Disable at boot" : "Enable at boot"
                    variant: "tonal"
                    onClicked: page.inTerminal(["service", (page.st.socket?.enabled || page.st.service?.enabled) ? "disable" : "enable"])
                }
            }
        }
    }

    Group {
        visible: page.st.installed && page.running
        title: "Printers"

        SettingRow {
            visible: page.st.printers.length === 0
            title: "No printers yet"
            subtitle: "Add one with " + (page.st.configTool || "the CUPS web interface")
            icon: "print_add"
        }

        Repeater {
            model: page.st.printers
            SettingRow {
                id: prow
                required property var modelData
                title: modelData.name.replace(/_/g, " ") + (modelData.default ? "  (default)" : "")
                subtitle: modelData.state + (modelData.uri ? " · " + modelData.uri : "")
                icon: modelData.state === "disabled" ? "print_disabled" : modelData.state === "printing" ? "print_connect" : "print"
                Row {
                    spacing: 4
                    FIconButton {
                        icon: "star"
                        active: prow.modelData.default
                        onClicked: page.cli(["default", prow.modelData.name])
                    }
                    FButton {
                        text: "Test page"
                        variant: "tonal"
                        implicitHeight: 32
                        onClicked: page.cli(["test", prow.modelData.name])
                    }
                }
            }
        }

        SettingRow {
            title: "Add a printer"
            subtitle: page.st.configTool ? "Opens " + page.st.configTool : "Opens the CUPS web interface (http://localhost:631)"
            icon: "add"
            FButton {
                text: "Add printer"
                icon: "print_add"
                onClicked: page.cli(["add"])
            }
        }
    }

    Group {
        visible: page.st.installed && page.running
        title: "Queue"

        SettingRow {
            visible: page.st.jobs.length === 0
            title: "Nothing waiting to print"
            icon: "inbox"
        }

        Repeater {
            model: page.st.jobs
            SettingRow {
                id: jrow
                required property var modelData
                title: modelData.id
                subtitle: modelData.user + " · " + SystemStats.formatBytes(modelData.size) + " · " + modelData.when
                icon: "description"
                FIconButton {
                    icon: "cancel"
                    iconColor: Theme.error
                    onClicked: page.cli(["cancel", jrow.modelData.id])
                }
            }
        }

        SettingRow {
            visible: page.st.jobs.length > 1
            title: "Cancel everything"
            icon: "clear_all"
            FButton {
                text: "Cancel all"
                variant: "outlined"
                onClicked: page.cli(["cancel", "all"])
            }
        }
    }
}
