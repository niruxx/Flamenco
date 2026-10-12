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

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                FText {
                    text: "Notifications"
                    font.pixelSize: Theme.fsXl
                    font.weight: Font.Bold
                }
                Rectangle {
                    visible: Notifs.history.count > 0
                    implicitWidth: countText.implicitWidth + 14
                    implicitHeight: 22
                    radius: 11
                    color: Theme.alpha(Theme.accent, 0.18)
                    FText {
                        id: countText
                        anchors.centerIn: parent
                        text: Notifs.history.count
                        color: Theme.accent
                        font.pixelSize: Theme.fsXs
                        font.weight: Font.Bold
                    }
                }
                Item { Layout.fillWidth: true }
                FIconButton {
                    icon: Notifs.dnd ? "notifications_off" : "do_not_disturb_on"
                    active: Notifs.dnd
                    onClicked: Notifs.setDnd(!Notifs.dnd)
                }
                FIconButton {
                    icon: "delete_sweep"
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
                boundsBehavior: Flickable.StopAtBounds

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
