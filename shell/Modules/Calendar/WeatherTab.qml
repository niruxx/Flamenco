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
        FText { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: root.w.enabled ? I18n.tr("No location set") : I18n.tr("Weather is turned off"); font.pixelSize: Theme.fsLg; font.weight: Font.Bold }
        FButton { Layout.alignment: Qt.AlignHCenter; text: I18n.tr("Weather settings"); icon: "settings"; variant: "tonal"; onClicked: root.openSettings("clock") }
    }

    ColumnLayout {
        visible: root.w.enabled && root.w.city !== ""
        Layout.fillWidth: true
        spacing: Theme.sp3

        // now: centered hero
        FCard {
            Layout.fillWidth: true
            implicitHeight: nowCol.implicitHeight + Theme.sp5 * 2
            ColumnLayout {
                id: nowCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Theme.sp4
                spacing: 2

                FIcon { Layout.alignment: Qt.AlignHCenter; icon: Weather.icon; size: 72; fill: 1; color: Theme.accent2 }
                FText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: Weather.ready ? Math.round(Weather.temp) + Weather.unit : I18n.tr("Loading…")
                    font.pixelSize: 44
                    font.weight: Font.Bold
                }
                FText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: Weather.description + (Weather.place ? " · " + Weather.place : "")
                    font.pixelSize: Theme.fsLg
                }
                FText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    visible: root.w.showFeelsLike && Weather.ready
                    text: I18n.tr("Feels like ") + Math.round(Weather.feelsLike) + Weather.unit
                    dim: true
                }
                Row {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: Theme.sp3
                    spacing: Theme.sp5
                    Row {
                        visible: root.w.showWind
                        spacing: 6
                        FIcon { icon: "air"; size: 18; color: Theme.textDim; anchors.verticalCenter: parent.verticalCenter }
                        FText { text: Math.round(Weather.wind) + (root.w.fahrenheit ? " mph" : " km/h"); anchors.verticalCenter: parent.verticalCenter }
                    }
                    Row {
                        visible: root.w.showHumidity
                        spacing: 6
                        FIcon { icon: "humidity_percentage"; size: 18; color: Theme.textDim; anchors.verticalCenter: parent.verticalCenter }
                        FText { text: Weather.humidity + "%"; anchors.verticalCenter: parent.verticalCenter }
                    }
                    Row {
                        visible: root.w.showSunTimes
                        spacing: 6
                        FIcon { icon: "wb_twilight"; size: 18; color: Theme.textDim; anchors.verticalCenter: parent.verticalCenter }
                        FText { text: root.hm(Weather.sunrise) + " – " + root.hm(Weather.sunset); anchors.verticalCenter: parent.verticalCenter }
                    }
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
                        FText { Layout.alignment: Qt.AlignHCenter; text: Qt.formatTime(new Date(modelData.time), Time.use24h ? I18n.tr("HH") : "h AP"); dim: true; font.pixelSize: Theme.fsXs }
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
                        FText { Layout.preferredWidth: 48; text: index === 0 ? I18n.tr("Today") : I18n.locale.toString(new Date(modelData.date + "T12:00"), "ddd"); font.weight: index === 0 ? Font.Bold : Font.Normal }
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
                text: Weather.ready ? I18n.tr("Open-Meteo · updated ") + Qt.formatTime(Weather.updated, Time.use24h ? I18n.tr("HH:mm") : "h:mm AP") : ""
                dim: true
                font.pixelSize: Theme.fsXs
            }
            FIconButton { icon: "refresh"; size: 30; onClicked: Weather.refresh() }
            FIconButton { icon: "tune"; size: 30; onClicked: root.openSettings("clock") }
        }
    }
}
