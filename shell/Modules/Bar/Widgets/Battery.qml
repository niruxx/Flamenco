import QtQuick
import qs.Commons
import qs.Services
import qs.Widgets

BarChip {
    property string screenName
    property bool barVisible: Power.hasBattery
    onClicked: Panels.toggle("control", screenName)

    BarFlow {
        spacing: Theme.barVertical ? 0 : 4

        FIcon {
            icon: Power.icon
            size: 18
            rotation: Theme.barVertical ? 0 : 90
            fill: 1
            color: Power.charging ? Theme.success : Power.percent <= 15 ? Theme.error : Theme.text

            SequentialAnimation on opacity {
                running: Power.percent <= 10 && !Power.charging
                loops: Animation.Infinite
                NumberAnimation { to: 0.35; duration: 700 }
                NumberAnimation { to: 1; duration: 700 }
            }
        }
        FText {
            text: Power.percent + (Theme.barVertical ? "" : "%")
            font.pixelSize: Theme.barVertical ? Theme.fsXs : Theme.fsSm
            font.weight: Font.DemiBold
        }
    }
}
