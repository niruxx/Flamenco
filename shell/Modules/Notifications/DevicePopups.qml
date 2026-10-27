import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services
import qs.Widgets

// Pop-ups for drives and accessories plugged in or taken out, GNOME-style, at their
// own spot (Settings → Notifications → Devices). A drive gets Open (mounted, then
// shown in the file manager) and Eject (safe to pull out); each goes after a few
// seconds, or stays while the pointer is on it.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win

        required property ShellScreen modelData
        readonly property string pos: Settings.data.devices.position || "top-center"
        readonly property bool atTop: pos.startsWith("top")
        readonly property bool here: modelData.name === Panels.targetScreen("")
        readonly property int count: Devices.popups.count
        onCountChanged: if (count === 0) linger.restart()

        Timer {
            id: linger
            interval: Theme.durLong + 100
        }

        screen: modelData
        visible: here && (count > 0 || linger.running)
        color: "transparent"
        anchors {
            top: win.atTop
            bottom: !win.atTop
            right: win.pos.endsWith("right")
            left: win.pos.endsWith("left")
        }
        implicitWidth: 360 + Theme.edge * 2
        implicitHeight: Math.max(1, list.contentHeight + Theme.edge * 2)
        exclusionMode: ExclusionMode.Normal
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "flamenco-devices"

        ListView {
            id: list
            anchors.fill: parent
            anchors.margins: Theme.edge
            interactive: false
            spacing: Theme.gap
            verticalLayoutDirection: win.atTop ? ListView.TopToBottom : ListView.BottomToTop
            model: Devices.popups

            delegate: Rectangle {
                id: card
                required property int uid
                required property string action
                required property string kind
                required property string name
                required property string detail
                required property string dev
                required property string note
                readonly property var info: Devices.kinds[kind] ?? Devices.kinds.device
                readonly property bool added: action === "added"
                readonly property bool drive: kind === "drive" && added && dev !== ""

                width: list.width
                implicitHeight: body.implicitHeight + Theme.sp3 * 2
                radius: Math.max(14, Theme.rLg)
                color: Theme.popupBg
                border.width: 1
                border.color: Theme.alpha(Theme.border, 0.6)

                Finish {}

                // goes by itself; the pointer on it keeps it
                Timer {
                    running: !hover.hovered && card.note === ""
                    interval: Math.max(2, Settings.data.devices.timeout ?? 5) * 1000 * (card.drive ? 2 : 1)
                    onTriggered: Devices.dismiss(card.uid)
                }
                HoverHandler { id: hover }

                RowLayout {
                    id: body
                    x: Theme.sp3
                    y: Theme.sp3
                    width: parent.width - Theme.sp3 * 2
                    spacing: Theme.sp3

                    Rectangle {
                        Layout.alignment: Qt.AlignTop
                        implicitWidth: 42
                        implicitHeight: 42
                        radius: 13
                        color: card.added ? Theme.alpha(Theme.accent, 0.18) : Theme.alpha(Theme.text, 0.08)
                        FIcon {
                            anchors.centerIn: parent
                            icon: card.info.icon
                            size: 24
                            fill: 1
                            color: card.added ? Theme.accent : Theme.textDim
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        FText {
                            Layout.fillWidth: true
                            text: card.info.label + (card.added ? " connected" : " disconnected")
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }
                        FText {
                            Layout.fillWidth: true
                            text: card.name
                            dim: true
                            elide: Text.ElideRight
                        }
                        FText {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: card.note !== "" ? card.note : card.detail
                            dim: card.note === ""
                            color: card.note !== "" ? Theme.accent : Theme.textDim
                            font.pixelSize: Theme.fsXs
                            wrapMode: Text.Wrap
                        }
                        RowLayout {
                            visible: card.drive
                            Layout.topMargin: Theme.sp1
                            spacing: Theme.sp2
                            FButton {
                                text: I18n.tr("Open")
                                icon: "folder_open"
                                implicitHeight: 32
                                disabled: card.note.endsWith("…")
                                onClicked: Devices.open(card.uid, card.dev)
                            }
                            FButton {
                                text: I18n.tr("Eject")
                                icon: "eject"
                                variant: "tonal"
                                implicitHeight: 32
                                disabled: card.note.endsWith("…")
                                onClicked: Devices.eject(card.uid, card.dev)
                            }
                        }
                    }
                    FIconButton {
                        Layout.alignment: Qt.AlignTop
                        icon: "close"
                        size: 28
                        onClicked: Devices.dismiss(card.uid)
                    }
                }
            }

            add: Transition {
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.durA("notifications", 280) }
                    NumberAnimation { property: "y"; from: win.atTop ? -40 : 40; duration: Theme.durA("notifications", 450); easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curves.emphasizedDecel }
                    NumberAnimation { property: "scale"; from: 0.9; to: 1; duration: Theme.durA("notifications", 450); easing.type: Theme.motion === "expressive" ? Easing.OutBack : Easing.OutCubic }
                }
            }
            remove: Transition {
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; to: 0; duration: Theme.durA("notifications", 260) }
                    NumberAnimation { property: "scale"; to: 0.9; duration: Theme.durA("notifications", 260); easing.type: Easing.InCubic }
                }
            }
            displaced: Transition {
                NumberAnimation { properties: "x,y"; duration: Theme.durA("notifications", 400); easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curves.emphasizedDecel }
            }
        }
    }
}
