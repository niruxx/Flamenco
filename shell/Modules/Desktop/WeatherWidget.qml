import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

// The weather now and the next days (more of them on a large widget).
ColumnLayout {
    id: root
    property real k: 1
    property var spec
    property bool editing: false
    readonly property bool on: Settings.data.weather.enabled && Weather.ready
    spacing: Math.round(Theme.sp3 * k)
    width: Math.round(270 * k)

    RowLayout {
        visible: root.on
        spacing: Math.round(Theme.sp3 * root.k)
        FIcon {
            icon: Weather.icon
            size: Math.round(52 * root.k)
            fill: 1
            color: Theme.accent
            // floats a few pixels up and down, slowly
            transform: Translate { id: drift }
            SequentialAnimation {
                running: root.visible && !root.editing && Theme.speed > 0
                loops: Animation.Infinite
                NumberAnimation { target: drift; property: "y"; to: -3 * root.k; duration: 2200; easing.type: Easing.InOutSine }
                NumberAnimation { target: drift; property: "y"; to: 3 * root.k; duration: 2200; easing.type: Easing.InOutSine }
            }
        }
        ColumnLayout {
            spacing: 0
            FText {
                text: Math.round(Weather.temp) + Weather.unit
                font.pixelSize: Math.round(38 * root.k)
                font.weight: Font.Light
            }
            FText {
                text: Weather.description
                font.pixelSize: Math.round(Theme.fsMd * root.k)
            }
        }
    }
    FText {
        visible: root.on && Weather.place !== ""
        text: Weather.place + " · feels like " + Math.round(Weather.feelsLike) + "°"
        dim: true
        font.pixelSize: Math.round(Theme.fsSm * root.k)
    }
    RowLayout {
        visible: root.on && Weather.daily.length > 1
        Layout.fillWidth: true
        spacing: 0
        Repeater {
            model: Weather.daily.slice(1, root.spec?.size === "l" ? 6 : 4)
            ColumnLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: Math.round(2 * root.k)
                FText {
                    Layout.alignment: Qt.AlignHCenter
                    text: I18n.locale.toString(new Date(modelData.date + "T12:00:00"), "ddd")
                    dim: true
                    font.pixelSize: Math.round(Theme.fsSm * root.k)
                }
                FIcon {
                    Layout.alignment: Qt.AlignHCenter
                    icon: Weather.iconFor(modelData.code, true)
                    size: Math.round(22 * root.k)
                }
                FText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Math.round(modelData.max) + "° " + Math.round(modelData.min) + "°"
                    font.pixelSize: Math.round(Theme.fsSm * root.k)
                }
            }
        }
    }
    FText {
        visible: !root.on
        Layout.preferredWidth: Math.round(240 * root.k)
        text: Settings.data.weather.enabled ? I18n.tr("Getting the weather…") : I18n.tr("Weather is off. Turn it on in Settings → Clock & Weather.")
        wrapMode: Text.Wrap
        dim: true
        font.pixelSize: Math.round(Theme.fsMd * root.k)
    }
}
