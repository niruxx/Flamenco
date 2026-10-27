import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: I18n.tr("About")

    property var sys: null

    Component.onCompleted: about.running = true

    function bytes(n) {
        if (!n)
            return "";
        const gb = n / 1073741824;
        return gb >= 1000 ? (gb / 1024).toFixed(1) + " TB" : gb >= 10 ? Math.round(gb) + " GB" : gb.toFixed(1) + " GB";
    }
    function since(s) {
        const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60);
        return (d ? d + " d " : "") + (d || h ? h + " h " : "") + m + " min";
    }
    readonly property var rows: !sys ? [] : [
        { icon: "computer", label: I18n.tr("Computer"), value: sys.model ? sys.model + " · " + sys.hostname : sys.hostname },
        { icon: "deployed_code", label: I18n.tr("System"), value: sys.os + " · " + sys.arch },
        { icon: "memory", label: I18n.tr("Processor"), value: sys.cpu + (sys.cores ? " · " + sys.cores + " threads" : "") },
        { icon: "developer_board", label: I18n.tr("Graphics"), value: sys.gpus.join("\n") },
        { icon: "memory_alt", label: I18n.tr("Memory"), value: bytes(sys.memTotal) + (sys.memAvailable ? " · " + bytes(sys.memAvailable) + " free" : "") },
        { icon: "hard_drive", label: I18n.tr("Disk"), value: sys.diskTotal ? bytes(sys.diskUsed) + " of " + bytes(sys.diskTotal) + " used" : "" },
        { icon: "terminal", label: I18n.tr("Kernel"), value: sys.kernel },
        { icon: "view_quilt", label: I18n.tr("Compositor"), value: (sys.compositor + " " + sys.compositorVersion).trim() + (sys.session ? " · " + sys.session : "") },
        { icon: "deployed_code_history", label: I18n.tr("Quickshell"), value: sys.quickshell },
        { icon: "inventory_2", label: I18n.tr("Packages"), value: sys.packages },
        { icon: "schedule", label: I18n.tr("Up for"), value: sys.uptime ? since(sys.uptime) : "" }
    ].filter(r => r.value)

    Process {
        id: about
        command: [Paths.bin, "about", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    page.sys = JSON.parse(text);
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
            FText { text: I18n.tr("Flamenco Shell"); font.pixelSize: Theme.fsXl; font.weight: Font.Bold }
            FText { text: I18n.tr("A Quickshell desktop shell for niri and Hyprland") + (page.sys ? " · version " + page.sys.flamenco : ""); dim: true }
            FText { text: I18n.tr("Config: ") + Paths.configDir; dim: true; font.pixelSize: Theme.fsSm; mono: true }
        }
    }

    Group {
        SettingRow {
            title: I18n.tr("What's new")
            subtitle: I18n.tr("The latest changes to Flamenco")
            icon: "auto_awesome"
            FButton { text: I18n.tr("Show"); variant: "tonal"; onClicked: { Panels.settingsOpen = false; Panels.whatsNew = true; } }
        }
    }

    Group {
        title: I18n.tr("This computer")
        visible: page.rows.length > 0
        Repeater {
            model: page.rows
            delegate: SettingRow {
                id: info
                required property var modelData
                title: modelData.label
                icon: modelData.icon
                FText {
                    width: Math.min(implicitWidth, 420)
                    text: info.modelData.value
                    horizontalAlignment: Text.AlignRight
                    wrapMode: Text.Wrap
                }
            }
        }
        SettingRow {
            title: I18n.tr("Copy the details")
            subtitle: I18n.tr("For bug reports")
            icon: "content_copy"
            FButton {
                text: I18n.tr("Copy")
                variant: "tonal"
                onClicked: Quickshell.execDetached(["wl-copy", page.rows.map(r => r.label + ": " + r.value.replace(/\n/g, ", ")).join("\n") + "\nFlamenco: " + page.sys.flamenco])
            }
        }
    }

    Group {
        title: I18n.tr("Setup")
        SettingRow {
            title: I18n.tr("Run the setup again")
            subtitle: I18n.tr("The first-run tour: displays, look, wallpaper, sound, Bluetooth, sharing and keyring")
            icon: "assistant"
            FButton {
                text: I18n.tr("Open setup")
                variant: "tonal"
                onClicked: {
                    Panels.settingsOpen = false;
                    Panels.setupOpen = true;
                }
            }
        }
    }

    Group {
        title: I18n.tr("Health")
        SettingRow {
            title: I18n.tr("System check")
            subtitle: I18n.tr("See which dependencies are installed and get the command for the rest")
            icon: "health_and_safety"
            FButton {
                text: I18n.tr("Open")
                variant: "tonal"
                onClicked: Panels.settingsPage = "system"
            }
        }
    }
}
