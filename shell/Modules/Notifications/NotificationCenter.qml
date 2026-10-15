import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

Variants {
    model: Quickshell.screens

    OverlayPanel {
        id: panel
        name: "notifications"
        hAlign: "right"
        cardWidth: 440
        onOpened: Notifs.markRead()

        // tallest the list may grow before it scrolls
        readonly property real maxListHeight: Math.max(240, panel.modelData.height * 0.7 - 120)

        ColumnLayout {
            width: parent.width
            spacing: Theme.sp3

            // header: a bubble, the title and what's waiting; Do not disturb and Clear as pills
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: 44
                    Layout.preferredHeight: 44
                    radius: 22
                    gradient: Gradient {
                        GradientStop { position: 0; color: Theme.accent }
                        GradientStop { position: 1; color: Theme.accent2 }
                    }
                    FIcon {
                        anchors.centerIn: parent
                        icon: Notifs.dnd ? "notifications_off" : "notifications"
                        size: 22
                        fill: 1
                        color: Theme.onAccent
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    FText {
                        text: "Notifications"
                        font.pixelSize: Theme.fsXl
                        font.weight: Font.Bold
                    }
                    FText {
                        text: (Notifs.history.count === 0 ? "Nothing new" : Notifs.history.count + (Notifs.history.count === 1 ? " notification" : " notifications"))
                            + (Notifs.dnd ? " · Do not disturb is on" : "")
                        dim: true
                        font.pixelSize: Theme.fsSm
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                FButton {
                    Layout.fillWidth: true
                    text: Notifs.dnd ? "Do not disturb: on" : "Do not disturb"
                    icon: Notifs.dnd ? "notifications_off" : "do_not_disturb_on"
                    variant: Notifs.dnd ? "filled" : "tonal"
                    onClicked: Notifs.setDnd(!Notifs.dnd)
                }
                FButton {
                    Layout.fillWidth: true
                    text: "Clear all"
                    icon: "delete_sweep"
                    variant: "tonal"
                    disabled: Notifs.history.count === 0
                    onClicked: Notifs.clearAll()
                }
            }

            // empty state, centered
            ColumnLayout {
                visible: Notifs.history.count === 0
                Layout.fillWidth: true
                Layout.topMargin: Theme.sp5
                Layout.bottomMargin: Theme.sp5
                spacing: 4
                FIcon {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.bottomMargin: 6
                    icon: Notifs.dnd ? "notifications_paused" : "done_all"
                    size: 44
                    color: Theme.accent
                }
                FText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: "You're all caught up"
                    font.pixelSize: Theme.fsLg
                    font.weight: Font.DemiBold
                }
                FText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: Notifs.dnd ? "Do Not Disturb is on" : "New notifications will show up here"
                    dim: true
                }
            }

            ListView {
                id: list
                visible: Notifs.history.count > 0
                Layout.fillWidth: true
                // grows with its content, scrolls past ~70% of the screen
                Layout.preferredHeight: Math.min(contentHeight, panel.maxListHeight)
                clip: true
                spacing: Theme.gap
                model: Notifs.history
                boundsBehavior: Flickable.OvershootBounds

                SmoothWheel {
                    view: list
                }

                delegate: NotificationCard {
                    width: list.width
                }

                add: Transition {
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.durMed }
                }
                remove: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "x"; to: 440; duration: Theme.durMed; easing.type: Easing.InCubic }
                        NumberAnimation { property: "opacity"; to: 0; duration: Theme.durMed }
                    }
                }
                displaced: Transition {
                    NumberAnimation { properties: "y"; duration: Theme.durLong; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curves.emphasizedDecel }
                }
            }
        }
    }
}
