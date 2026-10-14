import QtQuick
import qs.Commons
import qs.Services
import qs.Widgets

Item {
    property string screenName
    implicitWidth: btn.width
    implicitHeight: btn.height

    FIconButton {
        id: btn
        size: Theme.barHeight - 10
        iconSize: 18
        icon: Notifs.dnd ? "notifications_off" : Notifs.unread > 0 ? "notifications_unread" : "notifications"
        active: Panels.current === "notifications"
        onClicked: Panels.toggle("notifications", parent.screenName, btn)
        onRightClicked: Notifs.setDnd(!Notifs.dnd)
    }

    Rectangle {
        width: 8; height: 8; radius: 4
        color: Theme.accent
        anchors.right: btn.right
        anchors.top: btn.top
        anchors.margins: 6
        scale: Notifs.unread > 0 && !Notifs.dnd ? 1 : 0
        Behavior on scale { Anim { easing.bezierCurve: Theme.curves.springFast } }
    }
}
