import QtQuick
import qs.Commons

// A thin line between groups of bar widgets (widget "separator").
Item {
    property string screenName
    implicitWidth: Theme.barVertical ? Theme.barHeight - 16 : 9
    implicitHeight: Theme.barVertical ? 9 : Theme.barHeight - 16

    Rectangle {
        anchors.centerIn: parent
        width: Theme.barVertical ? parent.width : 1
        height: Theme.barVertical ? 1 : parent.height
        color: Theme.alpha(Theme.text, 0.18)
    }
}
