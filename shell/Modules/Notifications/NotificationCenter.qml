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
        cardWidth: 420
        onOpened: Notifs.markRead()

        ColumnLayout {
            width: parent.width
            implicitHeight: 560
            height: implicitHeight
            spacing: Theme.sp3

            RowLayout {
                Layout.fillWidth: true
                FText {
                    Layout.fillWidth: true
                    text: "Notifications"
                    font.pixelSize: Theme.fsXl
                    font.weight: Font.Bold
                }
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

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Column {
                    anchors.centerIn: parent
                    spacing: 8
                    opacity: Notifs.history.count === 0 ? 1 : 0
                    Behavior on opacity { Anim {} }
                    FIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        icon: "notifications_paused"
                        size: 56
                        color: Theme.textDim
                    }
                    FText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "You're all caught up"
                        dim: true
                    }
                }

                ListView {
                    id: list
                    anchors.fill: parent
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
                            NumberAnimation { property: "x"; to: 420; duration: Theme.durMed; easing.type: Easing.InCubic }
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
}
