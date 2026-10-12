import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

Variants {
    model: Quickshell.screens

    OverlayPanel {
        id: panel
        name: "calendar"
        cardWidth: 400

        property int monthOffset: 0
        property int slideDir: 0
        readonly property date shown: {
            const n = Time.now;
            return new Date(n.getFullYear(), n.getMonth() + monthOffset, 1);
        }
        onOpened: monthOffset = 0

        function go(d) {
            slideDir = d;
            monthOffset += d;
            gridAnim.restart();
        }

        ColumnLayout {
            width: parent.width
            spacing: Theme.sp4

            // big clock
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                RowLayout {
                    spacing: 0
                    FText { text: Time.hours; font.pixelSize: 56; font.weight: Font.Bold }
                    FText {
                        text: ":"
                        font.pixelSize: 56
                        font.weight: Font.Bold
                        color: Theme.accent
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            running: panel.shouldShow
                            NumberAnimation { to: 0.25; duration: 500; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1; duration: 500; easing.type: Easing.InOutSine }
                        }
                    }
                    FText { text: Time.minutes; font.pixelSize: 56; font.weight: Font.Bold }
                }
                FText { text: Time.date; dim: true; font.pixelSize: Theme.fsLg }
            }

            // weather
            FCard {
                Layout.fillWidth: true
                visible: Weather.ready
                implicitHeight: wcol.implicitHeight + Theme.sp4 * 2

                ColumnLayout {
                    id: wcol
                    anchors.fill: parent
                    anchors.margins: Theme.sp4
                    spacing: Theme.sp3

                    RowLayout {
                        spacing: Theme.sp3
                        FIcon { icon: Weather.icon; size: 44; fill: 1; color: Theme.accent2 }
                        ColumnLayout {
                            spacing: 0
                            FText { text: Math.round(Weather.temp) + Weather.unit + "  " + Weather.description; font.pixelSize: Theme.fsLg; font.weight: Font.Bold }
                            FText { text: Weather.place + " · 💧" + Weather.humidity + "% · " + Math.round(Weather.wind) + (Settings.data.weather.fahrenheit ? " mph" : " km/h"); dim: true; font.pixelSize: Theme.fsSm }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Repeater {
                            model: Weather.daily
                            ColumnLayout {
                                required property var modelData
                                Layout.fillWidth: true
                                spacing: 2
                                FText { Layout.alignment: Qt.AlignHCenter; text: Qt.formatDate(new Date(modelData.date + "T12:00"), "ddd"); dim: true; font.pixelSize: Theme.fsXs }
                                FIcon { Layout.alignment: Qt.AlignHCenter; icon: Weather.iconFor(modelData.code, true); size: 22 }
                                FText { Layout.alignment: Qt.AlignHCenter; text: Math.round(modelData.max) + "° " + Math.round(modelData.min) + "°"; font.pixelSize: Theme.fsXs }
                            }
                        }
                    }
                }
            }

            // month header
            RowLayout {
                Layout.fillWidth: true
                FText {
                    Layout.fillWidth: true
                    text: Qt.formatDate(panel.shown, "MMMM yyyy")
                    font.pixelSize: Theme.fsLg
                    font.weight: Font.Bold
                }
                FIconButton { icon: "today"; visible: panel.monthOffset !== 0; onClicked: panel.go(-panel.monthOffset) }
                FIconButton { icon: "chevron_left"; onClicked: panel.go(-1) }
                FIconButton { icon: "chevron_right"; onClicked: panel.go(1) }
            }

            GridLayout {
                id: grid
                Layout.fillWidth: true
                columns: 7
                rowSpacing: 4
                columnSpacing: 4

                ParallelAnimation {
                    id: gridAnim
                    NumberAnimation { target: grid; property: "opacity"; from: 0; to: 1; duration: Theme.durMed }
                    NumberAnimation { target: gridShift; property: "x"; from: panel.slideDir * 40; to: 0; duration: Theme.durLong; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curves.emphasizedDecel }
                }
                transform: Translate { id: gridShift }

                Repeater {
                    model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                    FText {
                        required property string modelData
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        dim: true
                        font.pixelSize: Theme.fsXs
                        font.weight: Font.Bold
                    }
                }

                Repeater {
                    model: 42
                    Rectangle {
                        id: cell
                        required property int index
                        readonly property int lead: (panel.shown.getDay() + 6) % 7
                        readonly property date day: new Date(panel.shown.getFullYear(), panel.shown.getMonth(), index - lead + 1)
                        readonly property bool inMonth: day.getMonth() === panel.shown.getMonth()
                        readonly property bool today: day.toDateString() === Time.now.toDateString()

                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        radius: today ? Theme.rMd : height / 2
                        color: today ? Theme.accent : hover.hovered ? Theme.surfaceHigh : "transparent"

                        Behavior on color { CAnim { duration: Theme.durShort } }

                        FText {
                            anchors.centerIn: parent
                            text: cell.day.getDate()
                            color: cell.today ? Theme.onAccent : cell.inMonth ? Theme.text : Theme.textDim
                            opacity: cell.inMonth ? 1 : 0.45
                            font.weight: cell.today ? Font.Bold : Font.Normal
                        }
                        HoverHandler { id: hover }
                    }
                }
            }
        }
    }
}
