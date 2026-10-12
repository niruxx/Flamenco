import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

ColumnLayout {
    id: root
    readonly property var w: Settings.data.weather
    signal openSettings(string page)
    spacing: Theme.sp3

    function hm(iso) {
        return iso ? Qt.formatTime(new Date(iso), Time.use24h ? "HH:mm" : "h:mm AP") : "–";
    }

    // not configured
    ColumnLayout {
        visible: !root.w.enabled || !root.w.city
        Layout.fillWidth: true
        Layout.topMargin: Theme.sp5
        Layout.bottomMargin: Theme.sp5
        spacing: Theme.sp2
        FIcon { Layout.alignment: Qt.AlignHCenter; icon: "location_off"; size: 48; color: Theme.textDim }
        FText { Layout.alignment: Qt.AlignHCenter; text: root.w.enabled ? "No location set" : "Weather is turned off"; font.pixelSize: Theme.fsLg; font.weight: Font.Bold }
        FButton { Layout.alignment: Qt.AlignHCenter; text: "Weather settings"; icon: "settings"; variant: "tonal"; onClicked: root.openSettings("clock") }
    }

    ColumnLayout {
        visible: root.w.enabled && root.w.city !== ""
        Layout.fillWidth: true
        spacing: Theme.sp3

        // now
        FCard {
            Layout.fillWidth: true
            implicitHeight: nowRow.implicitHeight + Theme.sp4 * 2
            RowLayout {
                id: nowRow
                anchors.fill: parent
                anchors.margins: Theme.sp4
                spacing: Theme.sp4
                FIcon { icon: Weather.icon; size: 64; fill: 1; color: Theme.accent2 }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    FText { text: Weather.ready ? Math.round(Weather.temp) + Weather.unit : "Loading…"; font.pixelSize: Theme.fsXxl; font.weight: Font.Bold }
                    FText { text: Weather.description + (Weather.place ? " · " + Weather.place : ""); dim: true }
                    FText {
                        visible: root.w.showFeelsLike && Weather.ready
                        text: "Feels like " + Math.round(Weather.feelsLike) + Weather.unit
                        dim: true
                        font.pixelSize: Theme.fsSm
                    }
                }
                GridLayout {
                    columns: 2
                    rowSpacing: 4
                    columnSpacing: 8
                    FIcon { visible: root.w.showWind; icon: "air"; size: 16; color: Theme.textDim }
                    FText { visible: root.w.showWind; text: Math.round(Weather.wind) + (root.w.fahrenheit ? " mph" : " km/h"); font.pixelSize: Theme.fsSm }
                    FIcon { visible: root.w.showHumidity; icon: "humidity_percentage"; size: 16; color: Theme.textDim }
                    FText { visible: root.w.showHumidity; text: Weather.humidity + "%"; font.pixelSize: Theme.fsSm }
                    FIcon { visible: root.w.showSunTimes; icon: "wb_twilight"; size: 16; color: Theme.textDim }
                    FText { visible: root.w.showSunTimes; text: root.hm(Weather.sunrise) + " – " + root.hm(Weather.sunset); font.pixelSize: Theme.fsSm }
                }
            }
        }

        // next hours
        FCard {
            visible: root.w.showHourly && Weather.hourly.length > 0
            Layout.fillWidth: true
            implicitHeight: 104
            RowLayout {
                anchors.fill: parent
                anchors.margins: Theme.sp3
                spacing: 0
                Repeater {
                    model: Weather.hourly
                    ColumnLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 2
                        FText { Layout.alignment: Qt.AlignHCenter; text: Qt.formatTime(new Date(modelData.time), Time.use24h ? "HH" : "h AP"); dim: true; font.pixelSize: Theme.fsXs }
                        FIcon { Layout.alignment: Qt.AlignHCenter; icon: Weather.iconFor(modelData.code, modelData.day); size: 20 }
                        FText { Layout.alignment: Qt.AlignHCenter; text: Math.round(modelData.temp) + "°"; font.pixelSize: Theme.fsSm }
                        FText { Layout.alignment: Qt.AlignHCenter; text: modelData.rain > 0 ? modelData.rain + "%" : " "; color: Theme.accent; font.pixelSize: Theme.fsXs }
                    }
                }
            }
        }

        // days
        FCard {
            id: daysCard
            Layout.fillWidth: true
            implicitHeight: days.implicitHeight + Theme.sp3 * 2
            readonly property real lo: Math.min(...Weather.daily.map(d => d.min))
            readonly property real hi: Math.max(...Weather.daily.map(d => d.max))
            ColumnLayout {
                id: days
                anchors.fill: parent
                anchors.margins: Theme.sp3
                spacing: 4
                Repeater {
                    model: Weather.daily
                    RowLayout {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        spacing: 10
                        FText { Layout.preferredWidth: 48; text: index === 0 ? "Today" : Qt.formatDate(new Date(modelData.date + "T12:00"), "ddd"); font.weight: index === 0 ? Font.Bold : Font.Normal }
                        FIcon { icon: Weather.iconFor(modelData.code, true); size: 20 }
                        FText { Layout.preferredWidth: 36; text: modelData.rain > 0 ? modelData.rain + "%" : ""; color: Theme.accent; font.pixelSize: Theme.fsXs }
                        FText { Layout.preferredWidth: 34; horizontalAlignment: Text.AlignRight; text: Math.round(modelData.min) + "°"; dim: true }
                        // temperature range bar
                        Item {
                            Layout.fillWidth: true
                            implicitHeight: 6
                            readonly property real span: Math.max(1, daysCard.hi - daysCard.lo)
                            Rectangle { anchors.fill: parent; radius: 3; color: Theme.surfaceHighest }
                            Rectangle {
                                height: parent.height
                                radius: 3
                                x: parent.width * (modelData.min - daysCard.lo) / parent.span
                                width: Math.max(6, parent.width * (modelData.max - modelData.min) / parent.span)
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0; color: Theme.accent3 }
                                    GradientStop { position: 1; color: Theme.accent2 }
                                }
                            }
                        }
                        FText { Layout.preferredWidth: 34; text: Math.round(modelData.max) + "°" }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            FText {
                Layout.fillWidth: true
                text: Weather.ready ? "Open-Meteo · updated " + Qt.formatTime(Weather.updated, Time.use24h ? "HH:mm" : "h:mm AP") : ""
                dim: true
                font.pixelSize: Theme.fsXs
            }
            FIconButton { icon: "refresh"; size: 30; onClicked: Weather.refresh() }
            FIconButton { icon: "tune"; size: 30; onClicked: root.openSettings("clock") }
        }
    }
}
