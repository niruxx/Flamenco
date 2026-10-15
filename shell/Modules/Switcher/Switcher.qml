import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services
import qs.Widgets

// The app switcher (Switcher service): the open windows as cards, most recent
// first. Keep Alt held and press Tab to move along (Shift+Tab back); let go of
// Alt to switch. Arrows, Enter, a click and Esc work too.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win

        required property ShellScreen modelData
        readonly property bool shown: Switcher.open && Panels.screen === modelData.name
        readonly property real p: pAnim.v
        readonly property int cardW: Math.max(150, Math.min(196, (width - 160) / Math.max(1, Switcher.list.length) - 12))

        screen: modelData
        visible: shown || p > 0.01
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "flamenco-switcher"
        WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        onShownChanged: if (shown) keys.forceActiveFocus()

        // animated value lives on an Item: Behaviors on the window itself crash Qt 6.12
        Item {
            id: pAnim
            property real v: win.shown ? 1 : 0
            Behavior on v { Anim { duration: Theme.durA("panels", 220); easing.bezierCurve: Theme.curves.emphasizedDecel } }
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.alpha(Theme.shadow, 0.3)
            opacity: win.p
            MouseArea {
                anchors.fill: parent
                onClicked: Switcher.cancel()
            }
        }

        Item {
            id: keys
            focus: true
            Keys.onPressed: event => {
                const k = event.key;
                if (k === Qt.Key_Escape)
                    Switcher.cancel();
                else if (k === Qt.Key_Backtab || (k === Qt.Key_Tab && event.modifiers & Qt.ShiftModifier) || k === Qt.Key_Left)
                    Switcher.step(-1);
                else if (k === Qt.Key_Tab || k === Qt.Key_Right)
                    Switcher.step(1);
                else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space)
                    Switcher.activate();
                else
                    return;
                event.accepted = true;
            }
            // letting go of the switcher's modifier switches
            Keys.onReleased: event => {
                if (event.key === Qt.Key_Alt || event.key === Qt.Key_Meta || event.key === Qt.Key_Super_L || event.key === Qt.Key_Super_R) {
                    Switcher.activate();
                    event.accepted = true;
                }
            }
        }

        Rectangle {
            id: card
            anchors.centerIn: parent
            width: Math.min(parent.width - 80, row.width + 32)
            height: row.height + 76
            radius: Theme.rXl
            color: Theme.panelBg
            border.width: 1
            border.color: Theme.alpha(Theme.border, 0.7)
            opacity: win.p
            scale: 0.94 + 0.06 * win.p

            FText {
                anchors.top: parent.top
                anchors.topMargin: 14
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 40
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: Switcher.selected?.title || Switcher.selected?.app_id || ""
                font.weight: Font.Bold
            }

            ListView {
                id: row
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 16
                anchors.horizontalCenter: parent.horizontalCenter
                orientation: ListView.Horizontal
                spacing: 12
                width: Math.min(contentWidth, win.width - 112)
                height: win.cardW + 34
                interactive: contentWidth > width
                model: Switcher.list
                currentIndex: Switcher.index
                highlightFollowsCurrentItem: true
                highlightMoveDuration: Theme.durShort
                clip: true

                delegate: Rectangle {
                    id: tile
                    required property var modelData
                    required property int index
                    readonly property bool sel: index === Switcher.index
                    readonly property var ws: Niri.workspaces.find(w => w.id === modelData.workspace_id)
                    width: win.cardW
                    height: win.cardW + 34
                    radius: Theme.rLg
                    color: sel ? Theme.alpha(Theme.accent, 0.18) : hover.hovered ? Theme.alpha(Theme.text, 0.06) : "transparent"
                    border.width: sel ? 2 : 0
                    border.color: Theme.accent
                    scale: sel ? 1 : 0.94
                    Behavior on scale { Anim { duration: Theme.durShort; easing.bezierCurve: Theme.curves.springFast } }
                    Behavior on color { CAnim {} }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 6

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            AppIcon {
                                anchors.centerIn: parent
                                implicitSize: Math.round(win.cardW * 0.46)
                                name: Apps.iconFor(tile.modelData.app_id)
                            }
                            // which workspace it's on
                            Rectangle {
                                visible: !!tile.ws
                                anchors.right: parent.right
                                anchors.top: parent.top
                                width: 22
                                height: 22
                                radius: 11
                                color: tile.sel ? Theme.accent : Theme.surfaceHigh
                                FText {
                                    anchors.centerIn: parent
                                    text: tile.ws ? (tile.ws.name || tile.ws.idx) : ""
                                    font.pixelSize: Theme.fsXs
                                    font.weight: Font.Bold
                                    color: tile.sel ? Theme.onAccent : Theme.text
                                }
                            }
                        }
                        FText {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: Apps.lookup(tile.modelData.app_id)?.name ?? tile.modelData.app_id ?? ""
                            font.pixelSize: Theme.fsSm
                            font.weight: tile.sel ? Font.Bold : Font.DemiBold
                            elide: Text.ElideRight
                        }
                        FText {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: tile.modelData.title || ""
                            dim: true
                            font.pixelSize: Theme.fsXs
                            elide: Text.ElideRight
                        }
                    }

                    HoverHandler {
                        id: hover
                        cursorShape: Qt.PointingHandCursor
                    }
                    TapHandler {
                        onTapped: {
                            Switcher.index = tile.index;
                            Switcher.activate();
                        }
                    }
                }
            }
        }
    }
}
