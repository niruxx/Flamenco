import QtQuick
import qs.Commons
import qs.Services
import qs.Widgets

FIconButton {
    property string screenName
    icon: "apps"
    size: Theme.barHeight - 10
    iconColor: Theme.accent
    active: Panels.current === "launcher"
    onClicked: Panels.toggle("launcher", screenName)
}
