import QtQuick
import Quickshell
import Quickshell.Widgets

// Themed application icon with a sane fallback.
IconImage {
    property string name: ""
    property string fallback: "application-x-executable"

    implicitSize: 32
    asynchronous: true
    source: {
        if (!name)
            return Quickshell.iconPath(fallback);
        if (name.startsWith("/") || name.startsWith("file:") || name.startsWith("image:"))
            return name.startsWith("/") ? "file://" + name : name;
        return Quickshell.iconPath(name, fallback);
    }
}
