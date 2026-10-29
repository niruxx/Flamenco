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
        // the drop-down; the shade (Settings → Notifications → Style) is NotificationShade
        name: Settings.data.notifications.style === "shade" ? "notifications-panel" : "notifications"
        hAlign: "right"
        cardWidth: Math.round(440 * Theme.scale)
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
                    Layout.preferredWidth: Theme.fieldHeight
                    Layout.preferredHeight: Theme.fieldHeight
                    radius: height / 2
                    color: Theme.accentContainer
                    FIcon {
                        anchors.centerIn: parent
                        icon: Notifs.dnd ? "notifications_off" : "notifications"
                        size: 22
                        fill: 1
                        color: Theme.onAccentContainer
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    FText {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: I18n.tr("Notifications")
                        font.pixelSize: Theme.fsXl
                        font.weight: Font.Bold
                    }
                    FText {
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        text: (Notifs.history.count === 0 ? I18n.tr("Nothing new") : Notifs.history.count + (Notifs.history.count === 1 ? " notification" : " notifications"))
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
                    text: Notifs.dnd ? I18n.tr("Do not disturb: on") : I18n.tr("Do not disturb")
                    icon: Notifs.dnd ? "notifications_off" : "do_not_disturb_on"
                    variant: Notifs.dnd ? "filled" : "tonal"
                    onClicked: Notifs.setDnd(!Notifs.dnd)
                }
                FButton {
                    Layout.fillWidth: true
                    text: I18n.tr("Clear all")
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
                    text: I18n.tr("You're all caught up")
                    font.pixelSize: Theme.fsLg
                    font.weight: Font.DemiBold
                }
                FText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: Notifs.dnd ? I18n.tr("Do Not Disturb is on") : I18n.tr("New notifications will show up here")
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
                    Anim { property: "opacity"; from: 0; to: 1; motionRole: "fade"; area: "notifications" }
                }
                remove: Transition {
                    ParallelAnimation {
                        Anim { property: "x"; to: Theme.spatialMotion("notifications") ? list.width : 0; motionRole: "exit"; area: "notifications" }
                        Anim { property: "opacity"; to: 0; motionRole: "exit"; area: "notifications" }
                    }
                }
                displaced: Transition {
                    Anim { properties: "y"; area: "notifications"; easing.bezierCurve: Theme.curves.emphasizedDecel }
                }
            }
        }
    }
}
