import QtQuick
import qs.Commons
import qs.Services
import qs.Widgets

BarChip {
    property string screenName
    property bool barVisible: Weather.ready
    onClicked: Panels.toggle("calendar", screenName)

    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4
        FIcon { icon: Weather.icon; size: 18; fill: 1; color: Theme.accent2; anchors.verticalCenter: parent.verticalCenter }
        FText { text: Math.round(Weather.temp) + "°"; font.pixelSize: Theme.fsSm; anchors.verticalCenter: parent.verticalCenter }
    }
}
