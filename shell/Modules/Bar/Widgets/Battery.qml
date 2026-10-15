import QtQuick
import qs.Commons
import qs.Services
import qs.Widgets

// Battery: an icon and the percent, or (Settings → Bar → Battery style) a
// battery shape that fills up, with the percent inside it.
BarChip {
    id: root
    property string screenName
    property int barLevel: 0
    property bool barVisible: Power.hasBattery
    readonly property bool shape: Settings.data.bar.batteryStyle === "battery" && !Theme.barVertical
    readonly property color level: Power.charging ? Theme.success : Power.percent <= 15 ? Theme.error : Theme.text
    onClicked: Panels.toggle("control", screenName, root)

    // low and not charging: blink
    SequentialAnimation on opacity {
        running: Power.percent <= 10 && !Power.charging
        loops: Animation.Infinite
        NumberAnimation { to: 0.35; duration: 700 }
        NumberAnimation { to: 1; duration: 700 }
        onRunningChanged: if (!running) root.opacity = 1
    }

    Loader {
        sourceComponent: root.shape ? shapeC : iconC
    }

    Component {
        id: iconC

        BarFlow {
            spacing: Theme.barVertical ? 0 : 4

            FIcon {
                icon: Power.icon
                size: 18
                rotation: Theme.barVertical ? 0 : 90
                fill: 1
                color: root.level
            }
            FText {
                visible: root.barLevel < 2
                text: Power.percent + (Theme.barVertical ? "" : "%")
                font.pixelSize: Theme.barVertical ? Theme.fsXs : Theme.fsSm
                font.weight: Font.DemiBold
            }
        }
    }

    Component {
        id: shapeC

        Row {
            spacing: 1
            Rectangle {
                id: body
                width: Math.round(Theme.barHeight * 0.9)
                height: Math.round(Theme.barHeight * 0.42)
                radius: Math.min(5, height / 3)
                color: "transparent"
                border.width: 1.5
                border.color: Theme.alpha(Theme.text, 0.6)

                Rectangle {
                    x: 2.5
                    y: 2.5
                    height: parent.height - 5
                    width: Math.max(0, (parent.width - 5) * Math.min(100, Power.percent) / 100)
                    radius: Math.max(1, parent.radius - 2)
                    color: Power.charging ? Theme.success : Power.percent <= 15 ? Theme.error : Theme.accent
                    Behavior on width { Anim {} }
                }
                Row {
                    anchors.centerIn: parent
                    spacing: 0
                    FIcon {
                        visible: Power.charging
                        anchors.verticalCenter: parent.verticalCenter
                        icon: "bolt"
                        size: Math.round(body.height * 0.8)
                        fill: 1
                        color: Theme.onAccent
                    }
                    FText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Power.percent
                        font.pixelSize: Math.max(8, Math.round(body.height * 0.68))
                        font.weight: Font.Bold
                        color: Theme.onAccent
                        style: Text.Outline
                        styleColor: Theme.alpha(Theme.shadow, 0.25)
                    }
                }
            }
            // the battery's terminal
            Rectangle {
                anchors.verticalCenter: body.verticalCenter
                width: 2.5
                height: body.height * 0.4
                radius: 1
                color: Theme.alpha(Theme.text, 0.6)
            }
        }
    }
}
