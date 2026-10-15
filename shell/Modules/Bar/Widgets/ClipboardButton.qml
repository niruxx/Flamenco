import QtQuick
import qs.Commons
import qs.Services
import qs.Widgets

// Bar widget "clipboard": opens the clipboard history.
FIconButton {
    id: root
    property string screenName
    icon: "content_paste"
    size: Theme.barHeight - 10
    active: Panels.current === "clipboard" && Panels.screen === screenName
    onClicked: Panels.toggle("clipboard", screenName, root)
}
