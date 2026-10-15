import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services
import qs.Widgets

// The start button (bar widget "launcher"). Settings → Bar → Start button sets
// its icon (the apps grid, your distro's logo, Flamenco's flame or your own),
// an optional label, and what a click opens: the overview when it's turned on
// (Settings → Overview), otherwise the app launcher.
BarChip {
    id: root
    property string screenName
    readonly property var b: Settings.data.bar
    readonly property string kind: b.startIcon || "apps"
    readonly property string label: Theme.barVertical ? "" : (b.startLabel || "")
    readonly property string opens: b.startAction === "launcher" ? "launcher"
        : b.startAction === "overview" || Settings.data.overview.enabled ? "overview" : "launcher"
    // an image to show instead of a Material Symbols icon: the distro logo (from
    // os-release, through the icon theme), the flame, or a custom picture
    readonly property string image: {
        if (kind === "distro")
            return logo ? Quickshell.iconPath(logo, true) : "";
        if (kind === "flamenco")
            return Qt.resolvedUrl("../../../assets/flame.svg");
        if (kind === "custom" && /^(\/|~\/|file:)/.test(b.startCustom || ""))
            return Paths.toUrl(b.startCustom);
        return "";
    }
    readonly property string symbol: kind === "custom" && !image && b.startCustom ? b.startCustom : "apps"
    property string logo: ""

    padding: label ? 10 : (cross - glyph.width) / 2
    highlighted: Panels.current === opens && Panels.screen === screenName
    onClicked: Panels.toggle(opens, screenName, root)
    // right-click: the other one, so the launcher stays a click away with the overview on
    onRightClicked: Panels.toggle(opens === "overview" ? "launcher" : "overview", screenName, root)

    Row {
        spacing: 7
        Item {
            id: glyph
            width: root.cross - 14
            height: width
            anchors.verticalCenter: parent.verticalCenter

            FIcon {
                anchors.centerIn: parent
                visible: !root.image
                icon: root.symbol
                size: Math.round(root.cross * 0.6)
                color: Theme.accent
                fill: root.highlighted ? 1 : 0
            }
            Image {
                id: pic
                anchors.fill: parent
                visible: !!root.image && root.kind !== "flamenco"
                source: root.image
                sourceSize: Qt.size(width * 2, height * 2)
                fillMode: Image.PreserveAspectFit
                smooth: true
                asynchronous: true
            }
            // the flame takes the accent color
            Image {
                id: flame
                anchors.fill: parent
                visible: false
                source: root.kind === "flamenco" ? root.image : ""
                sourceSize: Qt.size(width * 2, height * 2)
                fillMode: Image.PreserveAspectFit
            }
            MultiEffect {
                anchors.fill: parent
                visible: root.kind === "flamenco"
                source: flame
                colorization: 1
                colorizationColor: Theme.accent
            }
        }
        FText {
            visible: root.label !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            font.weight: Font.DemiBold
            color: root.highlighted ? Theme.accent : Theme.text
        }
    }

    // LOGO= in os-release names the distro's logo icon (e.g. archlinux-logo)
    FileView {
        path: root.kind === "distro" ? "/etc/os-release" : ""
        onLoaded: {
            const line = text().split("\n").find(l => l.startsWith("LOGO="));
            // without its quotes
            root.logo = line ? line.slice(5).replace(/^\W+|\W+$/g, "") : "";
        }
    }
}
