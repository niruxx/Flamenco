import QtQuick
import qs.Commons
import qs.Services
import qs.Widgets

FIconButton {
    property string screenName
    property string tip
    property bool barVisible: true
    size: Theme.barHeight - 10
    iconSize: 18
    onClicked: Panels.toggle("control", screenName)
}
