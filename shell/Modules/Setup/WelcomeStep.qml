import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

Item {
    id: root
    property var steps: []
    signal start

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(560, parent.width - 80)
        spacing: Theme.sp4

        // animated badge
        Rectangle {
            id: badge
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 104
            Layout.preferredHeight: 104
            radius: Theme.rXl * 1.3
            gradient: Gradient {
                GradientStop { position: 0; color: Theme.accent }
                GradientStop { position: 1; color: Theme.accent2 }
            }
            scale: 0.6
            Component.onCompleted: scale = 1
            Behavior on scale { Anim { duration: Theme.durXl; easing.bezierCurve: Theme.curves.spring } }
            FIcon { anchors.centerIn: parent; icon: "local_fire_department"; size: 60; fill: 1; color: Theme.onAccent }

            SequentialAnimation on rotation {
                running: Theme.speed > 0
                loops: Animation.Infinite
                NumberAnimation { to: 4; duration: 1600; easing.type: Easing.InOutSine }
                NumberAnimation { to: -4; duration: 1600; easing.type: Easing.InOutSine }
            }
        }

        FText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: I18n.tr("Let's get you set up")
            font.pixelSize: Theme.fsXxl
            font.weight: Font.Bold
        }
        FText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            dim: true
            text: I18n.tr("A few quick steps to make Flamenco yours. Every change applies right away, and you can skip anything. Running on ") + (Niri.hyprland ? I18n.tr("Hyprland") : "niri") + "."
        }

        Flow {
            Layout.fillWidth: true
            Layout.topMargin: Theme.sp2
            spacing: 8
            Repeater {
                model: root.steps.slice(1, -1)
                Rectangle {
                    required property var modelData
                    width: chip.implicitWidth + 24
                    height: 34
                    radius: 17
                    color: Theme.surfaceHigh
                    Row {
                        id: chip
                        anchors.centerIn: parent
                        spacing: 6
                        FIcon { icon: modelData.icon; size: 16; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                        FText { text: modelData.label; font.pixelSize: Theme.fsSm; anchors.verticalCenter: parent.verticalCenter }
                    }
                }
            }
        }

        FButton {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Theme.sp4
            implicitHeight: 44
            text: I18n.tr("Get started")
            icon: "arrow_forward"
            onClicked: root.start()
        }
    }
}
