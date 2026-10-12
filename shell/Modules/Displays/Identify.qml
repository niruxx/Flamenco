import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services
import qs.Widgets

// Big output name on every screen while Settings → Displays → Identify is active.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property ShellScreen modelData
        readonly property var info: Displays.outputs.find(o => o.name === modelData.name) ?? null

        screen: modelData
        visible: Displays.identifying
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        implicitWidth: card.width
        implicitHeight: card.height
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "flamenco-identify"
        mask: Region {}

        Rectangle {
            id: card
            width: col.implicitWidth + 64
            height: col.implicitHeight + 40
            radius: Theme.rXl
            color: Theme.accent

            Column {
                id: col
                anchors.centerIn: parent
                spacing: 2
                FText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: win.modelData.name
                    color: Theme.onAccent
                    font.pixelSize: 44
                    font.weight: Font.Black
                }
                FText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: win.info ? (win.info.make + " " + win.info.model).trim() : ""
                    color: Theme.onAccent
                    opacity: 0.8
                }
            }
        }
    }
}
