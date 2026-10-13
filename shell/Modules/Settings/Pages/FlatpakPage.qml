import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: "Flatpak permissions"
    subtitle: "Override what a Flatpak app can reach. Changes are saved as your own overrides and apply the next time the app starts."

    property bool available: true
    property var apps: []
    property string app: ""
    property var info: null
    property string status: ""

    readonly property var groups: [
        { key: "filesystems", title: "Files and folders" },
        { key: "shared", title: "Network & sharing" },
        { key: "sockets", title: "Display, sound & services" },
        { key: "devices", title: "Devices" },
        { key: "features", title: "Features" }
    ]
    readonly property var labels: ({
            "network": "Internet and network",
            "ipc": "Share memory with other apps (IPC)",
            "wayland": "Wayland display",
            "x11": "X11 display",
            "fallback-x11": "X11 when Wayland isn't there",
            "pulseaudio": "Sound (PulseAudio / PipeWire)",
            "session-bus": "Full session bus (D-Bus)",
            "system-bus": "Full system bus (D-Bus)",
            "ssh-auth": "SSH agent",
            "pcsc": "Smart cards",
            "cups": "Printing (CUPS)",
            "gpg-agent": "GPG agent",
            "dri": "GPU acceleration",
            "input": "Input devices (game controllers)",
            "usb": "USB devices",
            "kvm": "Virtualization (KVM)",
            "shm": "Shared memory",
            "all": "All devices (webcams, controllers…)",
            "bluetooth": "Bluetooth",
            "devel": "Development syscalls (debuggers)",
            "multiarch": "Run 32-bit programs",
            "canbus": "CAN bus",
            "per-app-dev-shm": "Private /dev/shm",
            "home": "Home folder",
            "host": "All files",
            "host-os": "System libraries and programs",
            "host-etc": "System configuration (/etc)",
            "xdg-download": "Downloads",
            "xdg-documents": "Documents",
            "xdg-pictures": "Pictures",
            "xdg-music": "Music",
            "xdg-videos": "Videos",
            "xdg-desktop": "Desktop",
            "xdg-config": "App configuration (~/.config)",
            "xdg-run/pipewire-0": "PipeWire (screen and camera)"
        })

    Component.onCompleted: lister.running = true

    function select(id) {
        app = id;
        info = null;
        loadInfo();
    }
    function loadInfo() {
        if (!app)
            return;
        infoProc.command = [Paths.bin, "flatpak", "info", app];
        infoProc.running = true;
    }
    function change(key, name, want) {
        const c = {};
        c[key] = {};
        c[key][name] = want;
        run([Paths.bin, "flatpak", "set", app, "--json", JSON.stringify(c)]);
    }
    function run(cmd) {
        setter.command = cmd;
        setter.running = true;
    }
    function stateOf(row, key) {
        if (key === "filesystems" && row.state === "allow" && row.access === "ro")
            return "ro";
        return row.state;
    }

    Process {
        id: lister
        command: [Paths.bin, "flatpak", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    page.available = d.available;
                    page.apps = d.apps;
                    if (!page.app && d.apps.length)
                        page.select(d.apps[0].id);
                } catch (e) {}
            }
        }
    }

    Process {
        id: infoProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    page.info = JSON.parse(text);
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
        onExited: page.loadInfo()
    }

    Group {
        visible: !page.available
        SettingRow {
            title: "Flatpak isn't installed"
            subtitle: "Install the flatpak package to manage Flatpak apps here"
            icon: "inventory_2"
        }
    }

    Group {
        visible: page.available
        SettingRow {
            title: page.apps.length ? "App" : "No Flatpak apps installed"
            subtitle: page.info ? page.app + (page.info.hasOverrides ? " · has your overrides" : "") : ""
            icon: "apps"
            RowLayout {
                spacing: 8
                visible: page.apps.length > 0
                AppIcon {
                    implicitSize: 28
                    name: page.app
                }
                FDropdown {
                    implicitWidth: 260
                    options: page.apps.map(a => ({ value: a.id, label: a.name || a.id }))
                    current: page.app
                    searchable: true
                    onSelected: v => page.select(v)
                }
            }
        }
        SettingRow {
            visible: page.info !== null && page.info.hasOverrides
            title: "Reset this app"
            subtitle: "Drop your overrides and use what the app asks for"
            icon: "restart_alt"
            FButton {
                text: "Reset"
                variant: "tonal"
                onClicked: page.run([Paths.bin, "flatpak", "reset", page.app])
            }
        }
    }

    Repeater {
        model: page.info ? page.groups : []
        delegate: Group {
            id: grp
            required property var modelData
            title: modelData.title
            Repeater {
                model: page.info.permissions[grp.modelData.key] || []
                delegate: SettingRow {
                    id: prow
                    required property var modelData
                    title: page.labels[modelData.name] || modelData.name
                    subtitle: (modelData.requested ? "Requested by the app" : "Not requested") + " · " + (modelData.effective ? (modelData.access === "ro" ? "read-only" : "allowed") : "blocked")
                    icon: modelData.effective ? "check_circle" : "block"
                    FSegmented {
                        readonly property bool fs: grp.modelData.key === "filesystems"
                        implicitWidth: options.length * 82
                        options: fs ? [{ value: "default", label: "Default" }, { value: "ro", label: "Read" }, { value: "allow", label: "Allow" }, { value: "deny", label: "Deny" }]
                                    : [{ value: "default", label: "Default" }, { value: "allow", label: "Allow" }, { value: "deny", label: "Deny" }]
                        current: page.stateOf(prow.modelData, grp.modelData.key)
                        onSelected: v => page.change(grp.modelData.key, prow.modelData.name, v === "allow" && fs ? "rw" : v)
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
