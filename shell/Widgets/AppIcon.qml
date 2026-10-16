import QtQuick
import Quickshell
import Quickshell.Widgets

// Themed application icon with a sane fallback.
IconImage {
    property string name: ""
    property string fallback: "application-x-executable"

    implicitSize: 32
    // On the main thread: theme icons are looked up through Qt's icon theme, which
    // isn't safe on the background image thread ("Cannot create children for a parent
    // that is in a different thread" in the log). Lookups there could jam that thread,
    // and every image loading in the background (wallpapers, covers) waited forever.
    // Icons are small and cached, so this costs little.
    asynchronous: false
    source: {
        if (!name)
            return Quickshell.iconPath(fallback);
        if (name.startsWith("/") || name.startsWith("file:") || name.startsWith("image:"))
            return name.startsWith("/") ? "file://" + name : name;
        return Quickshell.iconPath(name, fallback);
    }
}
