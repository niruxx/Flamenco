import QtQuick
import qs.Commons
import qs.Services
import qs.Widgets

FIconButton {
    property string screenName
    property string tip
    property bool barVisible: true
    // control-center page this icon opens ("" = main page)
    property string detail: ""
    size: Theme.barHeight - 10
    iconSize: 18
    active: Panels.current === "control" && Panels.controlDetail === detail && detail !== ""
    onClicked: Panels.openControl(detail, screenName)
}
