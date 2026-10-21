import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

// Settings → Bar → Style: each style as a small picture of a screen with that bar,
// then the bar's shape (thickness, distance from the edge, rounding, spacing,
// outline, shadow).
Group {
    id: root
    title: "Style"
    readonly property var b: Settings.data.bar
    readonly property var styles: [
        { value: "islands", label: "Islands", hint: "Separate floating groups" },
        { value: "floating", label: "Floating", hint: "One rounded bar" },
        { value: "attached", label: "Attached", hint: "Flush with the edge" },
        { value: "framed", label: "Framed", hint: "Solid bar, pill groups" },
        { value: "capsule", label: "Capsule", hint: "One pill, centered" },
        { value: "minimal", label: "Minimal", hint: "No bar, just widgets" },
        { value: "outline", label: "Outline", hint: "See-through, outlined" }
    ]

    Item {
        Layout.fillWidth: true
        Layout.margins: Theme.sp3
        implicitHeight: tiles.implicitHeight

        Flow {
            id: tiles
            width: parent.width
            spacing: Theme.sp2
            readonly property int cols: Math.max(2, Math.floor((width + spacing) / (150 + spacing)))
            readonly property real tileW: (width - spacing * (cols - 1)) / cols

            Repeater {
                model: root.styles
                Rectangle {
                    id: tile
                    required property var modelData
                    readonly property string st: modelData.value
                    readonly property bool on: (root.b.style || "islands") === st
                    width: tiles.tileW
                    height: shot.height + 52
                    radius: Theme.rLg
                    color: on ? Theme.alpha(Theme.accent, 0.14) : Theme.alpha(Theme.text, 0.04)
                    border.width: on ? 2 : 1
                    border.color: on ? Theme.accent : Theme.alpha(Theme.text, 0.08)
                    Behavior on color { CAnim {} }

                    // a little screen: wallpaper colors, a window, and the bar in this style
                    Rectangle {
                        id: shot
                        x: 8
                        y: 8
                        width: parent.width - 16
                        height: Math.round(width * 0.5)
                        radius: Math.max(4, Theme.rMd - 8)
                        clip: true
                        gradient: Gradient {
                            GradientStop { position: 0; color: Theme.mix(Theme.accent3, Theme.bg, 0.45) }
                            GradientStop { position: 1; color: Theme.mix(Theme.accent2, Theme.bg, 0.6) }
                        }
                        readonly property int bh: 9
                        readonly property int m: tile.st === "attached" || tile.st === "framed" ? 0 : 3
                        // a window
                        Rectangle {
                            x: 10
                            y: shot.bh + shot.m * 2 + 4
                            width: parent.width - 20
                            height: parent.height - y - 8
                            radius: 3
                            color: Theme.alpha(Theme.surface, 0.85)
                        }
                        // minimal: the shade
                        Rectangle {
                            visible: tile.st === "minimal"
                            width: parent.width
                            height: shot.bh * 2.4
                            gradient: Gradient {
                                GradientStop { position: 0; color: Theme.alpha(Theme.shadow, 0.4) }
                                GradientStop { position: 1; color: "transparent" }
                            }
                        }
                        // whole-width bars
                        Rectangle {
                            visible: ["floating", "attached", "framed", "outline"].includes(tile.st)
                            x: shot.m
                            y: shot.m
                            width: parent.width - shot.m * 2
                            height: shot.bh
                            radius: tile.st === "attached" || tile.st === "framed" ? 0 : height / 2
                            color: tile.st === "outline" ? Theme.alpha(Theme.bg, 0.2) : Theme.bg
                            border.width: tile.st === "outline" ? 1 : 0
                            border.color: Theme.alpha(Theme.text, 0.5)
                        }
                        // capsule
                        Rectangle {
                            visible: tile.st === "capsule"
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: shot.m
                            width: parent.width * 0.62
                            height: shot.bh
                            radius: height / 2
                            color: Theme.bg
                        }
                        // the groups: islands float, framed pills sit on the bar, the rest are dots of content
                        Repeater {
                            model: [{ at: 0, w: 0.26 }, { at: 0.5, w: 0.16 }, { at: 1, w: 0.3 }]
                            Rectangle {
                                required property var modelData
                                readonly property bool cap: tile.st === "capsule"
                                readonly property real span: cap ? shot.width * 0.62 - 6 : shot.width - shot.m * 2 - (tile.st === "islands" ? 0 : 6)
                                readonly property real start: cap ? (shot.width - shot.width * 0.62) / 2 + 3 : shot.m + (tile.st === "islands" ? 0 : 3)
                                width: span * modelData.w * (cap ? 0.95 : 1)
                                height: tile.st === "islands" ? shot.bh : tile.st === "framed" ? shot.bh - 3 : 3
                                x: start + (span - width) * modelData.at
                                y: shot.m + (shot.bh - height) / 2
                                radius: height / 2
                                color: tile.st === "islands" ? Theme.bg : tile.st === "framed" ? Theme.surfaceHighest : Theme.alpha(Theme.text, tile.st === "minimal" ? 0.9 : 0.55)
                            }
                        }
                    }
                    Column {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 10
                        spacing: 0
                        Row {
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
                                text: tile.modelData.label
                                font.weight: tile.on ? Font.Bold : Font.DemiBold
                                color: tile.on ? Theme.accent : Theme.text
                            }
                        }
                        FText {
                            width: parent.width
                            text: tile.modelData.hint
                            dim: true
                            font.pixelSize: Theme.fsXs
                            elide: Text.ElideRight
                        }
                    }
                    StateLayer {
                        radius: parent.radius
                        onClicked: root.b.style = tile.st
                    }
                }
            }
        }
    }

    SliderRow { title: "Thickness"; icon: "height"; target: root.b; key: "height"; from: 28; to: 56; stepSize: 2; suffix: " px" }
    SettingRow {
        visible: !Theme.barFlush
        title: "Distance from the edge"
        subtitle: (root.b.margin ?? -1) < 0 ? "Matching the windows' gap (" + Theme.edge + " px), so the bar, panels and windows line up" : "Its own distance"
        icon: "border_outer"
        Row {
            spacing: 8
            FSlider {
                anchors.verticalCenter: parent.verticalCenter
                width: 200
                from: 0
                to: 32
                stepSize: 1
                value: (root.b.margin ?? -1) < 0 ? Theme.edge : root.b.margin
                showValue: true
                valueText: (root.b.margin ?? -1) < 0 ? "auto" : Math.round(value) + " px"
                onMoved: v => root.b.margin = Math.round(v)
            }
            FIconButton {
                visible: (root.b.margin ?? -1) >= 0
                anchors.verticalCenter: parent.verticalCenter
                icon: "link"
                size: 30
                iconSize: 16
                onClicked: root.b.margin = -1
            }
        }
    }
    SettingRow {
        visible: !Theme.barFlush && root.b.style !== "minimal"
        title: "Corner radius"
        subtitle: (root.b.radius ?? -1) < 0 ? "Following Appearance → Corner roundness" : "Its own rounding (never more than fully round ends)"
        icon: "rounded_corner"
        Row {
            spacing: 8
            FSlider {
                anchors.verticalCenter: parent.verticalCenter
                width: 200
                from: 0
                to: 28
                stepSize: 1
                value: (root.b.radius ?? -1) < 0 ? Theme.barRadius : root.b.radius
                showValue: true
                valueText: (root.b.radius ?? -1) < 0 ? "auto" : Math.round(value) + " px"
                onMoved: v => root.b.radius = Math.round(v)
            }
            FIconButton {
                visible: (root.b.radius ?? -1) >= 0
                anchors.verticalCenter: parent.verticalCenter
                icon: "link"
                size: 30
                iconSize: 16
                onClicked: root.b.radius = -1
            }
        }
    }
    ChoiceRow {
        title: "Widget spacing"
        icon: "space_bar"
        target: root.b
        key: "spacing"
        segWidth: 100
        options: [{ value: 0.6, label: "Compact" }, { value: 1, label: "Normal" }, { value: 1.5, label: "Roomy" }]
    }
    SwitchRow { visible: ["floating", "islands", "capsule"].includes(root.b.style); title: "Outline"; subtitle: "A thin border around the bar"; icon: "border_style"; target: root.b; key: "border" }
    SwitchRow { visible: !Theme.barFlush && !["minimal", "outline"].includes(root.b.style); title: "Shadow"; subtitle: Settings.data.appearance.shadows ? "" : "Drop shadows are off in Appearance"; icon: "shadow"; target: root.b; key: "shadow" }
}
