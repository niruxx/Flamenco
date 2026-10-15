pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Flamenco shim for Noctalia's HostService: the user and the distro (os-release).
Singleton {
    id: root

    readonly property string username: Quickshell.env("USER") || ""
    property string osPretty: ""
    property string osId: ""
    property string osLogo: ""
    property string hostname: ""

    FileView {
        path: "/etc/os-release"
        onLoaded: {
            const get = k => (text().split("\n").find(l => l.startsWith(k + "=")) ?? "").slice(k.length + 1).replace(/^["']|["']$/g, "");
            root.osPretty = get("PRETTY_NAME");
            root.osId = get("ID");
            const logo = get("LOGO");
            root.osLogo = logo ? Quickshell.iconPath(logo, true) : "";
        }
    }
    FileView {
        path: "/etc/hostname"
        onLoaded: root.hostname = text().trim()
    }
}
