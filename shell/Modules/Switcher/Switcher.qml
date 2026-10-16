import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Commons
import qs.Services
import qs.Widgets

// The app switcher (Switcher service), in Material 3 cards: the open windows,
// most recent first, on a raised sheet. Keep Alt held and press Tab to move
// along (Shift+Tab back); let go of Alt to switch. Arrows, Enter, a click and
// Esc work too.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win

        required property ShellScreen modelData
        readonly property bool shown: Switcher.open && Panels.screen === modelData.name
        readonly property real p: pAnim.v
        readonly property int n: Switcher.list.length
        readonly property int cardW: Math.max(168, Math.min(212, (width - 200) / Math.max(1, n) - 14))
        readonly property int cardH: Math.round(cardW * 1.22)
        readonly property var tints: [Theme.accent, Theme.accent2, Theme.accent3]
        // window pictures (Settings → Overview → App switcher); never in a nested niri, whose
        // old dmabuf version makes capturing drop the whole shell
        readonly property bool previews: (Settings.data.switcher.previews ?? false) && !Quickshell.screens.some(s => s.name === "winit")

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
            Behavior on v { Anim { duration: Theme.durA("panels", 260); easing.bezierCurve: Theme.curves.emphasizedDecel } }
        }

        // the scrim
        Rectangle {
            anchors.fill: parent
            color: Theme.alpha(Theme.shadow, 0.32)
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

        // the sheet's shadow
        RectangularShadow {
            anchors.fill: sheet
            radius: sheet.radius
            blur: 36
            spread: 2
            offset: Qt.vector2d(0, 10)
            color: Theme.alpha(Theme.shadow, 0.35)
            opacity: win.p
            scale: sheet.scale
        }

        // ── the sheet ──
        Rectangle {
            id: sheet
            anchors.centerIn: parent
            width: Math.min(parent.width - 80, Math.max(row.width, header.implicitWidth) + 48)
            height: header.height + row.height + 72
            radius: 32
            color: Theme.surface
            border.width: 1
            border.color: Theme.alpha(Theme.border, 0.6)
            opacity: win.p
            scale: 0.92 + 0.08 * win.p

            // header: what this is, how many, and the keys as chips
            RowLayout {
                id: header
                x: 24
                y: 20
                width: sheet.width - 48
                spacing: 10

                Rectangle {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    radius: 14
                    color: Theme.alpha(Theme.accent, 0.18)
                    FIcon { anchors.centerIn: parent; icon: "select_window"; size: 22; fill: 1; color: Theme.accent }
                }
                ColumnLayout {
                    spacing: 0
                    FText { text: "Switch window"; font.pixelSize: Theme.fsLg; font.weight: Font.Bold }
                    FText { text: win.n + (win.n === 1 ? " window open" : " windows open"); dim: true; font.pixelSize: Theme.fsXs }
                }
                Item { Layout.fillWidth: true }
                Repeater {
                    model: [{ k: "Tab", t: "next" }, { k: "⇧ Tab", t: "back" }, { k: "Alt", t: "release to switch" }]
                    Rectangle {
                        required property var modelData
                        implicitWidth: chip.implicitWidth + 20
                        implicitHeight: 30
                        radius: 9
                        color: "transparent"
                        border.width: 1
                        border.color: Theme.alpha(Theme.text, 0.18)
                        Row {
                            id: chip
                            anchors.centerIn: parent
                            spacing: 6
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: kt.implicitWidth + 10
                                height: 20
                                radius: 6
                                color: Theme.alpha(Theme.text, 0.1)
                                FText { id: kt; anchors.centerIn: parent; text: modelData.k; mono: true; font.pixelSize: Theme.fsXs; font.weight: Font.Bold }
                            }
                            FText { anchors.verticalCenter: parent.verticalCenter; text: modelData.t; dim: true; font.pixelSize: Theme.fsXs }
                        }
                    }
                }
            }

            ListView {
                id: row
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 24
                anchors.horizontalCenter: parent.horizontalCenter
                orientation: ListView.Horizontal
                spacing: 14
                width: Math.min(contentWidth, win.width - 128)
                height: win.cardH + 16
                interactive: contentWidth > width
                model: Switcher.list
                currentIndex: Switcher.index
                highlightFollowsCurrentItem: true
                highlightMoveDuration: Theme.durShort
                preferredHighlightBegin: width / 2 - win.cardW / 2
                preferredHighlightEnd: width / 2 + win.cardW / 2
                highlightRangeMode: contentWidth > width ? ListView.ApplyRange : ListView.NoHighlightRange
                clip: true

                delegate: Item {
                    id: slot
                    required property var modelData
                    required property int index
                    readonly property bool sel: index === Switcher.index
                    readonly property var ws: Niri.workspaces.find(w => w.id === modelData.workspace_id)
                    readonly property color tint: win.tints[index % win.tints.length]
                    readonly property string appName: Apps.lookup(modelData.app_id)?.name ?? modelData.app_id ?? ""
                    width: win.cardW
                    height: win.cardH + 16

                    // an M3 card: tonal when picked, raised a little
                    Rectangle {
                        id: m3card
                        width: parent.width
                        height: win.cardH
                        y: slot.sel ? 0 : 8
                        radius: 24
                        color: slot.sel ? Theme.alpha(Theme.accent, 0.2) : Theme.surfaceHigh
                        border.width: slot.sel ? 2 : 1
                        border.color: slot.sel ? Theme.accent : Theme.alpha(Theme.text, 0.06)
                        Behavior on y { Anim { duration: Theme.durShort; easing.bezierCurve: Theme.curves.springFast } }
                        Behavior on color { CAnim {} }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8

                            // hero: the app on a soft wash of its tint
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 18
                                gradient: Gradient {
                                    GradientStop { position: 0; color: Theme.alpha(slot.tint, slot.sel ? 0.42 : 0.22) }
                                    GradientStop { position: 1; color: Theme.alpha(slot.tint, 0.06) }
                                }
                                // the window's picture, when previews are on and it can be captured
                                Loader {
                                    id: shot
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    readonly property var toplevel: win.previews && win.shown ? (ToplevelManager.toplevels.values.find(t => t.appId === slot.modelData.app_id && t.title === slot.modelData.title) ?? null) : null
                                    active: toplevel !== null
                                    sourceComponent: ClippingRectangle {
                                        readonly property bool got: pic.hasContent
                                        radius: 14
                                        color: "transparent"
                                        ScreencopyView {
                                            id: pic
                                            anchors.centerIn: parent
                                            readonly property real aspect: hasContent && sourceSize.height > 0 ? sourceSize.width / sourceSize.height : 16 / 10
                                            width: Math.min(parent.width, parent.height * aspect)
                                            height: width / aspect
                                            captureSource: shot.toplevel
                                            live: false
                                        }
                                    }
                                }
                                readonly property bool hasShot: shot.item?.got ?? false
                                AppIcon {
                                    // over the picture, it moves to a corner as a badge
                                    anchors.centerIn: parent.hasShot ? undefined : parent
                                    anchors.left: parent.hasShot ? parent.left : undefined
                                    anchors.bottom: parent.hasShot ? parent.bottom : undefined
                                    anchors.margins: 8
                                    implicitSize: parent.hasShot ? 30 : Math.round(win.cardW * (slot.sel ? 0.42 : 0.36))
                                    name: Apps.iconFor(slot.modelData.app_id)
                                    Behavior on implicitSize { Anim { duration: Theme.durShort } }
                                }
                                // the workspace, as an assist chip
                                Rectangle {
                                    visible: !!slot.ws
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    anchors.margins: 8
                                    width: wsRow.implicitWidth + 14
                                    height: 24
                                    radius: 8
                                    color: Theme.alpha(Theme.surface, 0.85)
                                    Row {
                                        id: wsRow
                                        anchors.centerIn: parent
                                        spacing: 3
                                        FIcon { anchors.verticalCenter: parent.verticalCenter; icon: "view_carousel"; size: 13; color: slot.tint }
                                        FText { anchors.verticalCenter: parent.verticalCenter; text: slot.ws ? (slot.ws.name || slot.ws.idx) : ""; font.pixelSize: Theme.fsXs; font.weight: Font.Bold }
                                    }
                                }
                                // floating windows get a badge
                                FIcon {
                                    visible: !!slot.modelData.is_floating
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: 10
                                    icon: "picture_in_picture"
                                    size: 16
                                    color: slot.tint
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.leftMargin: 6
                                Layout.rightMargin: 6
                                Layout.bottomMargin: 4
                                spacing: 1
                                FText {
                                    Layout.fillWidth: true
                                    text: slot.modelData.title || slot.appName
                                    font.pixelSize: Theme.fsSm
                                    font.weight: Font.Bold
                                    elide: Text.ElideRight
                                }
                                FText {
                                    Layout.fillWidth: true
                                    text: slot.appName
                                    font.pixelSize: Theme.fsXs
                                    color: slot.sel ? Theme.accent : Theme.textDim
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        // M3 state layer
                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: Theme.text
                            opacity: hover.hovered && !slot.sel ? 0.06 : 0
                            Behavior on opacity { Anim { duration: Theme.durShort } }
                        }
                    }

                    HoverHandler {
                        id: hover
                        cursorShape: Qt.PointingHandCursor
                    }
                    TapHandler {
                        onTapped: {
                            Switcher.index = slot.index;
                            Switcher.activate();
                        }
                    }
                }
            }
        }
    }
}
