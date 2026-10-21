import QtQuick
import qs.Commons
import qs.Services
import qs.Widgets

FIconButton {
    id: root
    property string screenName
    property string tip
    property bool barVisible: true
    property int barLevel: 0
    // control-center page this icon opens ("" = main page)
    property string detail: ""
    // a popout of its own (e.g. "volume") instead of the control center
    property string panel: ""
    size: Theme.barItem
    iconSize: 18
    active: panel ? Panels.current === panel : Panels.current === "control" && Panels.controlDetail === detail && detail !== ""
    onClicked: panel ? Panels.toggle(panel, screenName, root) : Panels.openControl(detail, screenName, root)
}
