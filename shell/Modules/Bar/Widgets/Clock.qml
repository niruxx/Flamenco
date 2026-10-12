import QtQuick
import qs.Commons
import qs.Services
import qs.Widgets

BarChip {
    property string screenName
    highlighted: Panels.current === "calendar"
    onClicked: Panels.toggle("calendar", screenName)

    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        FText {
            text: Time.time
            font.weight: Font.Bold
            font.pixelSize: Theme.fsMd
            anchors.verticalCenter: parent.verticalCenter
        }
        Rectangle {
            width: 4; height: 4; radius: 2
            color: Theme.accent
            anchors.verticalCenter: parent.verticalCenter
        }
        FText {
            text: Time.shortDate
            dim: true
            font.pixelSize: Theme.fsSm
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
