import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

// Settings → Bar → Battery: the indicator's theme, picked from live previews,
// and how it's colored. The previews show your battery as it is (or a sample
// on a computer without one); "Preview" tries other levels and charging.
Group {
    id: root
    title: "Battery"
    readonly property var b: Settings.data.bar
    readonly property var themes: [
        { value: "battery", label: "Battery" }, { value: "pill", label: "Capsule" }, { value: "outline", label: "Outline" },
        { value: "cells", label: "Cells" }, { value: "vertical", label: "Upright" }, { value: "ring", label: "Ring" },
        { value: "icon", label: "Symbol" }, { value: "dot", label: "Dot" }, { value: "line", label: "Line" }, { value: "text", label: "Text" }
    ]
    // what the previews show
    property string sample: "live"             // live | low | half | charging
    readonly property real demoPct: sample === "low" ? 9 : sample === "half" ? 52 : sample === "charging" ? 71 : Power.hasBattery ? Power.percent : 76
    readonly property bool demoCharging: sample === "charging" || sample === "live" && Power.charging

    SettingRow {
        title: "Preview"
        subtitle: Power.hasBattery ? "The previews show your battery now, or try a level" : "No battery here: the previews show a sample"
        icon: "preview"
        FSegmented {
            implicitWidth: 360
            options: [{ value: "live", label: Power.hasBattery ? "Now" : "Sample" }, { value: "half", label: "Half" }, { value: "low", label: "Low" }, { value: "charging", label: "Charging" }]
            current: root.sample
            onSelected: v => root.sample = v
        }
    }

    // the themes, each drawn as it would be in the bar
    Item {
        Layout.fillWidth: true
        Layout.leftMargin: Theme.sp4
        Layout.rightMargin: Theme.sp4
        Layout.bottomMargin: Theme.sp3
        implicitHeight: tiles.implicitHeight

        Flow {
            id: tiles
            width: parent.width
            spacing: Theme.sp2
            readonly property int cols: Math.max(2, Math.floor((width + spacing) / (128 + spacing)))
            readonly property real tileW: (width - spacing * (cols - 1)) / cols

            Repeater {
                model: root.themes
                Rectangle {
                    id: tile
                    required property var modelData
                    readonly property bool on: (root.b.batteryStyle || "battery") === modelData.value
                    width: tiles.tileW
                    height: 92
                    radius: Theme.rLg
                    color: on ? Theme.alpha(Theme.accent, 0.16) : Theme.alpha(Theme.text, 0.04)
                    border.width: on ? 2 : 1
                    border.color: on ? Theme.accent : Theme.alpha(Theme.text, 0.08)
                    Behavior on color { CAnim {} }

                    // a strip of bar behind the preview
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 12
                        width: parent.width - 24
                        height: Theme.barItem
                        radius: height / 2
                        color: Theme.alpha(Theme.bg, 0.7)
                        BatteryGlyph {
                            anchors.centerIn: parent
                            percent: root.demoPct
                            charging: root.demoCharging
                            theme: tile.modelData.value
                            colors: root.b.batteryColors || "theme"
                            showPercent: root.b.batteryPercent ?? true
                            low: root.b.batteryLow || 15
                            animate: root.b.batteryChargeAnim ?? true
                        }
                    }
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 12
                        spacing: 4
                        FIcon {
                            visible: tile.on
                            anchors.verticalCenter: parent.verticalCenter
                            icon: "check_circle"
                            size: 15
                            fill: 1
                            color: Theme.accent
                        }
                        FText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: tile.modelData.label
                            font.pixelSize: Theme.fsSm
                            font.weight: tile.on ? Font.Bold : Font.Normal
                            color: tile.on ? Theme.accent : Theme.text
                        }
                    }
                    StateLayer {
                        radius: parent.radius
                        onClicked: root.b.batteryStyle = tile.modelData.value
                    }
                }
            }
        }
    }

    ChoiceRow {
        title: "Colors"
        subtitle: root.b.batteryColors === "level" ? "Green when full, amber halfway, red when low" : root.b.batteryColors === "mono" ? "The bar's text color; red only when low" : "Your accent color; red when low, green while charging"
        icon: "palette"
        target: root.b
        key: "batteryColors"
        segWidth: 110
        options: [{ value: "theme", label: "Accent" }, { value: "level", label: "By level" }, { value: "mono", label: "Plain" }]
    }
    SwitchRow { title: "Show the percent"; icon: "percent"; target: root.b; key: "batteryPercent" }
    SliderRow { title: "Low battery"; subtitle: "Turns red at this level"; icon: "battery_alert"; target: root.b; key: "batteryLow"; from: 5; to: 40; stepSize: 1; suffix: "%" }
    SwitchRow { title: "Blink when nearly empty"; subtitle: "Five points below low, while not charging"; icon: "emergency_home"; target: root.b; key: "batteryBlink" }
    SwitchRow { title: "Charging animation"; subtitle: "A sweep through the fill (cells light up, the ring turns)"; icon: "bolt"; target: root.b; key: "batteryChargeAnim" }
}
