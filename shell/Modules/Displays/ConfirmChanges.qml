import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services
import qs.Widgets

// "Keep these display settings?" on every screen after applying a layout.
// Lives outside the settings window so the auto-revert always happens.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property ShellScreen modelData

        screen: modelData
        visible: Displays.confirming
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        implicitWidth: card.width
        implicitHeight: card.height
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "flamenco-display-confirm"
        WlrLayershell.keyboardFocus: Displays.confirming ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        onVisibleChanged: if (visible) card.forceActiveFocus()

        Rectangle {
            id: card
            width: 420
            height: col.implicitHeight + 40
            radius: Theme.rXl
            color: Theme.panelBg
            border.width: 1
            border.color: Theme.alpha(Theme.border, 0.7)

            Keys.onEscapePressed: Displays.revert()
            Keys.onReturnPressed: Displays.keep()

            ColumnLayout {
                id: col
                anchors.fill: parent
                anchors.margins: 20
                spacing: 14

                RowLayout {
                    spacing: 12
                    FIcon { icon: "monitor"; size: 28; color: Theme.accent }
                    ColumnLayout {
                        spacing: 0
                        FText { text: "Keep these display settings?"; font.pixelSize: Theme.fsLg; font.weight: Font.Bold }
                        FText { text: "Reverting in " + Displays.countdown + " s"; dim: true }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 4
                    radius: 2
                    color: Theme.surfaceHighest
                    Rectangle {
                        height: parent.height
                        radius: 2
                        width: parent.width * Displays.countdown / 15
                        color: Theme.accent
                        Behavior on width { Anim { duration: 1000; easing.type: Easing.Linear } }
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    spacing: 8
                    FButton { text: "Revert"; variant: "outlined"; onClicked: Displays.revert() }
                    FButton { text: "Keep changes"; icon: "check"; onClicked: Displays.keep() }
                }
            }
        }
    }
}
