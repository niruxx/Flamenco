import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.Commons

// Themed application icon with a sane fallback. When neither the icon nor the
// fallback is in the icon theme (or a picture doesn't load), a question mark
// stands in, instead of Qt's black and purple "missing" checkerboard.
IconImage {
    id: root
    property string name: ""
    property string fallback: "application-x-executable"
    readonly property bool missing: String(source) === "" || backer.status === Image.Error

    implicitSize: 32
    // On the main thread: theme icons are looked up through Qt's icon theme, which
    // isn't safe on the background image thread ("Cannot create children for a parent
    // that is in a different thread" in the log). Lookups there could jam that thread,
    // and every image loading in the background (wallpapers, covers) waited forever.
    // Icons are small and cached, so this costs little.
    asynchronous: false
    source: {
        if (name.startsWith("/") || name.startsWith("file:") || name.startsWith("image:"))
            return name.startsWith("/") ? "file://" + name : name;
        // `true`: "" when the theme doesn't have it (a name alone always gives an address)
        return (name ? Quickshell.iconPath(name, true) : "") || Quickshell.iconPath(fallback, true) || "";
    }

    Rectangle {
        visible: root.missing
        anchors.fill: parent
        radius: width * 0.28
        color: Theme.alpha(Theme.text, 0.1)
        FIcon {
            anchors.centerIn: parent
            icon: "question_mark"
            size: Math.max(10, Math.round(parent.width * 0.62))
            color: Theme.textDim
        }
    }
}
