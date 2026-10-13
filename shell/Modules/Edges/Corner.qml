import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services

// One hot corner of one screen.
PanelWindow {
    id: corner

    required property ShellScreen output
    required property string key
    required property bool atTop
    required property bool atLeft
    readonly property var cfg: Settings.data.edges
    readonly property string action: cfg[key]

    visible: action !== "none"
    screen: output
    color: "transparent"
    anchors {
        top: corner.atTop
        bottom: !corner.atTop
        left: corner.atLeft
        right: !corner.atLeft
    }
    implicitWidth: Math.max(1, cfg.size)
    implicitHeight: Math.max(1, cfg.size)
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "flamenco-edge"

    Item {
        anchors.fill: parent

        HoverHandler {
            id: hover
            onHoveredChanged: {
                if (hovered)
                    dwell.restart();
                else
                    dwell.stop();
            }
        }
    }

    // fires once per visit to the corner
    Timer {
        id: dwell
        interval: Math.max(1, corner.cfg.delay)
        onTriggered: if (hover.hovered) Edges.run(corner.action, corner.output.name)
    }
}
