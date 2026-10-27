import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Commons
import qs.Services
import qs.Widgets

// "Share your screen": an app asked to share the screen (through the wlr portal),
// and this asks which one. Each screen as a card with a live picture of it; click
// one (or ← → and Enter) to share it, Esc or Don't share to say no. Shown on the
// screen you're working on.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property ShellScreen modelData
        readonly property bool shown: Share.asking && modelData.name === (Niri.focusedOutput || Quickshell.screens[0]?.name)
        readonly property var screens: Share.outputs.map(n => Quickshell.screens.find(s => s.name === n) ?? null)
        // no live pictures in a nested niri (its dmabuf version makes capture drop the shell)
        readonly property bool previews: !Quickshell.screens.some(s => s.name === "winit")
        property int sel: 0
        onShownChanged: if (shown) {
            sel = 0;
            keys.forceActiveFocus();
        }

        screen: modelData
        visible: shown
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "flamenco-share"
        WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        Rectangle {
            anchors.fill: parent
            color: Theme.alpha(Theme.shadow, 0.45)
            MouseArea { anchors.fill: parent; onClicked: Share.answer("") }
        }

        Item {
            id: keys
            focus: true
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape)
                    Share.answer("");
                else if (event.key === Qt.Key_Left)
                    win.sel = Math.max(0, win.sel - 1);
                else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab)
                    win.sel = Math.min(Share.outputs.length - 1, win.sel + 1);
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                    Share.answer(Share.outputs[win.sel] ?? "");
                else
                    return;
                event.accepted = true;
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width - 80, col.implicitWidth + 56)
            height: col.implicitHeight + 56
            radius: Theme.rXl
            color: Theme.panelBg
            border.width: 1
            border.color: Theme.alpha(Theme.border, 0.7)
            MouseArea { anchors.fill: parent }

            ColumnLayout {
                id: col
                anchors.centerIn: parent
                spacing: Theme.sp4

                RowLayout {
                    spacing: Theme.sp3
                    Rectangle {
                        Layout.preferredWidth: 44
                        Layout.preferredHeight: 44
                        radius: 14
                        color: Theme.alpha(Theme.accent, 0.18)
                        FIcon { anchors.centerIn: parent; icon: "screen_share"; size: 24; fill: 1; color: Theme.accent }
                    }
                    ColumnLayout {
                        spacing: 0
                        FText { text: I18n.tr("Share your screen"); font.pixelSize: Theme.fsXl; font.weight: Font.Bold }
                        FText { text: I18n.tr("An app wants to see a screen. Pick the one to share."); dim: true }
                    }
                }

                Row {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Theme.sp3
                    Repeater {
                        model: Share.outputs
                        Rectangle {
                            id: card
                            required property string modelData
                            required property int index
                            readonly property var scr: win.screens[index]
                            readonly property bool on: win.sel === index
                            width: 300
                            height: 230
                            radius: Theme.rLg
                            color: on ? Theme.alpha(Theme.accent, 0.16) : Theme.alpha(Theme.text, 0.05)
                            border.width: on ? 2 : 1
                            border.color: on ? Theme.accent : Theme.alpha(Theme.text, 0.1)
                            Behavior on color { CAnim {} }
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8
                                // the screen, live
                                ClippingRectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: Theme.rMd
                                    color: Theme.alpha(Theme.shadow, 0.3)
                                    ScreencopyView {
                                        anchors.centerIn: parent
                                        readonly property real aspect: card.scr && card.scr.height > 0 ? card.scr.width / card.scr.height : 16 / 9
                                        width: Math.min(parent.width, parent.height * aspect)
                                        height: width / aspect
                                        captureSource: win.previews && win.shown ? card.scr : null
                                        live: true
                                    }
                                    FIcon {
                                        anchors.centerIn: parent
                                        visible: !win.previews || !card.scr
                                        icon: "monitor"
                                        size: 48
                                        color: Theme.textDim
                                    }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    FText { Layout.fillWidth: true; text: card.modelData; font.weight: Font.Bold; elide: Text.ElideRight }
                                    FText {
                                        Layout.fillWidth: true
                                        text: card.scr ? card.scr.width + " × " + card.scr.height + (card.scr.model ? " · " + card.scr.model : "") : ""
                                        dim: true
                                        font.pixelSize: Theme.fsXs
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                            StateLayer {
                                radius: card.radius
                                onClicked: {
                                    win.sel = card.index;
                                    Share.answer(card.modelData);
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    FText { Layout.fillWidth: true; text: I18n.tr("← → pick · Enter share · Esc don't"); dim: true; font.pixelSize: Theme.fsXs }
                    FButton { text: I18n.tr("Don't share"); variant: "text"; onClicked: Share.answer("") }
                    FButton { text: I18n.tr("Share"); icon: "screen_share"; onClicked: Share.answer(Share.outputs[win.sel] ?? "") }
                }
            }
        }
    }
}
