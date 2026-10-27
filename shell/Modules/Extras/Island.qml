import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services

// The floating Dynamic island (Settings → Desktop widgets → Dynamic island), at the
// top or bottom, left, center or right of the screen in use. "In the bar" puts the
// pill in the bar instead (the island bar widget), and this stays hidden.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property ShellScreen modelData
        readonly property var cfg: Settings.data.island
        readonly property string pos: cfg.position || "top-center"
        readonly property bool atTop: pos.startsWith("top")
        readonly property bool here: modelData.name === Panels.targetScreen("")

        screen: modelData
        visible: (cfg.enabled ?? false) && (cfg.place || "float") === "float" && here
        color: "transparent"
        anchors {
            top: win.atTop
            bottom: !win.atTop
            left: win.pos.endsWith("left")
            right: win.pos.endsWith("right")
        }
        margins.top: Theme.edge
        margins.bottom: Theme.edge
        margins.left: Theme.edge
        margins.right: Theme.edge
        implicitWidth: 460
        implicitHeight: 150
        exclusionMode: ExclusionMode.Normal
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "flamenco-island"
        mask: Region { item: pill }

        IslandPill {
            id: pill
            screenName: win.modelData.name
            growsDown: win.atTop
            x: win.pos.endsWith("left") ? 0 : win.pos.endsWith("right") ? parent.width - width : (parent.width - width) / 2
            y: win.atTop ? 0 : parent.height - height
        }
    }
}
