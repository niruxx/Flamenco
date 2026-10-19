import QtQuick
import qs.Commons
import qs.Widgets

// A battery indicator in one of the themes (Settings → Bar → Battery):
//   icon      Material battery symbol and the percent
//   battery   a battery shape filling up, the percent inside
//   outline   a slim battery outline, the percent beside it
//   cells     a battery of five cells
//   vertical  an upright battery
//   ring      a ring gauge, the percent (or a bolt) inside
//   pill      a capsule filling up, the percent inside
//   dot       a dot in the level's color and the percent
//   text      just the percent (with a bolt while charging)
//   line      the percent over a thin level line
// The bar and the settings previews both draw it, so what you pick is what you get.
Item {
    id: root

    property real percent: 100
    property bool charging: false
    property string theme: "battery"
    property string colors: "theme"          // theme | level | mono
    property bool showPercent: true
    property int low: 15
    property bool animate: true               // the charging sweep
    property real size: Theme.barHeight       // what it's sized from (the bar's thickness)
    property bool compact: false              // a vertical bar: the percent goes under it, without "%"

    readonly property real p: Math.max(0, Math.min(100, percent))
    readonly property bool isLow: p <= low && !charging
    readonly property color fill: {
        if (charging)
            return colors === "mono" ? Theme.text : Theme.success;
        if (isLow)
            return Theme.error;
        if (colors === "level")
            return p < 50 ? Theme.mix(Theme.error, Theme.warning, Math.max(0, (p - low) / Math.max(1, 50 - low))) : Theme.mix(Theme.warning, Theme.success, (p - 50) / 50);
        return colors === "mono" ? Theme.text : Theme.accent;
    }
    // on the fill (inside shapes)
    readonly property color onFill: colors === "mono" && !isLow ? Theme.bg : Theme.onAccent
    readonly property color frame: Theme.alpha(Theme.text, 0.6)
    readonly property string pctText: Math.round(p) + (compact ? "" : "%")
    readonly property bool textBeside: showPercent && ["icon", "outline", "cells", "vertical", "dot", "text", "line"].includes(theme)

    implicitWidth: lay.implicitWidth
    implicitHeight: lay.implicitHeight

    // ── a sweep of light through a fill while charging ──
    component Sweep: Item {
        id: sweep
        anchors.fill: parent
        clip: true
        visible: root.charging && root.animate
        Rectangle {
            width: sweep.width * 0.6
            height: sweep.height
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.45) }
                GradientStop { position: 1; color: "transparent" }
            }
            NumberAnimation on x {
                running: sweep.visible && root.visible
                from: -sweep.width * 0.6
                to: sweep.width
                duration: 1600
                loops: Animation.Infinite
            }
        }
    }

    Grid {
        id: lay
        anchors.centerIn: parent
        columns: root.compact ? 1 : 2
        spacing: root.compact ? 1 : root.theme === "text" ? 2 : 4
        horizontalItemAlignment: Grid.AlignHCenter
        verticalItemAlignment: Grid.AlignVCenter

        Loader {
            sourceComponent: ({
                    icon: iconC, battery: shapeC, outline: shapeC, cells: cellsC, vertical: verticalC,
                    ring: ringC, pill: pillC, dot: dotC, text: boltC, line: lineC
                })[root.theme] ?? shapeC
        }
        FText {
            visible: root.textBeside && root.theme !== "line"
            text: root.pctText
            font.pixelSize: root.compact ? Theme.fsXs : Theme.fsSm
            font.weight: root.theme === "text" ? Font.Bold : Font.DemiBold
            color: root.theme === "text" || root.theme === "dot" ? (root.colors === "mono" && !root.isLow ? Theme.text : root.fill) : Theme.text
        }
    }

    // Material symbol
    Component {
        id: iconC
        FIcon {
            icon: root.charging ? "battery_charging_full" : root.p >= 95 ? "battery_full" : "battery_" + Math.max(0, Math.min(6, Math.floor(root.p / 15))) + "_bar"
            size: Math.round(root.size * 0.5)
            rotation: root.compact ? 0 : 90
            fill: 1
            color: root.charging || root.isLow || root.colors !== "mono" && root.colors !== "theme" ? root.fill : Theme.text
        }
    }

    // battery (percent inside) and outline (slim, percent beside)
    Component {
        id: shapeC
        Row {
            readonly property bool slim: root.theme === "outline"
            spacing: 1
            Rectangle {
                id: body
                width: Math.round(root.size * (parent.slim ? 0.66 : 0.9))
                height: Math.round(root.size * (parent.slim ? 0.34 : 0.42))
                radius: Math.min(5, height / 3)
                color: "transparent"
                border.width: parent.slim ? 1.25 : 1.5
                border.color: root.frame
                Rectangle {
                    x: 2.5
                    y: 2.5
                    height: parent.height - 5
                    width: Math.max(0, (parent.width - 5) * root.p / 100)
                    radius: Math.max(1, parent.radius - 2)
                    color: root.fill
                    Behavior on width { Anim {} }
                    Sweep {}
                }
                Row {
                    visible: !body.parent.slim
                    anchors.centerIn: parent
                    FIcon {
                        visible: root.charging
                        anchors.verticalCenter: parent.verticalCenter
                        icon: "bolt"
                        size: Math.round(body.height * 0.8)
                        fill: 1
                        color: root.onFill
                    }
                    FText {
                        visible: root.showPercent
                        anchors.verticalCenter: parent.verticalCenter
                        text: Math.round(root.p)
                        font.pixelSize: Math.max(8, Math.round(body.height * 0.68))
                        font.weight: Font.Bold
                        color: root.onFill
                        style: Text.Outline
                        styleColor: Theme.alpha(Theme.shadow, 0.25)
                    }
                }
                FIcon {
                    visible: body.parent.slim && root.charging
                    anchors.centerIn: parent
                    icon: "bolt"
                    size: Math.round(body.height * 1.1)
                    fill: 1
                    color: Theme.text
                    style: Text.Outline
                    styleColor: Theme.bg
                }
            }
            Rectangle {
                anchors.verticalCenter: body.verticalCenter
                width: 2.5
                height: body.height * 0.4
                radius: 1
                color: root.frame
            }
        }
    }

    // five cells
    Component {
        id: cellsC
        Row {
            spacing: 1
            Rectangle {
                id: cbody
                width: Math.round(root.size * 0.82)
                height: Math.round(root.size * 0.4)
                radius: 4
                color: "transparent"
                border.width: 1.5
                border.color: root.frame
                Row {
                    anchors.fill: parent
                    anchors.margins: 3
                    spacing: 1.5
                    Repeater {
                        model: 5
                        Rectangle {
                            required property int index
                            width: (parent.width - 6) / 5
                            height: parent.height
                            radius: 1.5
                            color: root.fill
                            // the last cell fills partly
                            opacity: root.p >= (index + 1) * 20 ? 1 : root.p > index * 20 ? 0.35 + 0.65 * (root.p - index * 20) / 20 : 0.1
                            Behavior on opacity { Anim {} }
                            // charging: the cells light up one after another
                            SequentialAnimation on scale {
                                running: root.charging && root.animate && root.visible
                                loops: Animation.Infinite
                                PauseAnimation { duration: index * 160 }
                                NumberAnimation { to: 0.7; duration: 200 }
                                NumberAnimation { to: 1; duration: 200 }
                                PauseAnimation { duration: (4 - index) * 160 + 400 }
                                onRunningChanged: if (!running) parent.scale = 1
                            }
                        }
                    }
                }
            }
            Rectangle {
                anchors.verticalCenter: cbody.verticalCenter
                width: 2.5
                height: cbody.height * 0.4
                radius: 1
                color: root.frame
            }
        }
    }

    // upright
    Component {
        id: verticalC
        Column {
            spacing: 1
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: vbody.width * 0.42
                height: 2.5
                radius: 1
                color: root.frame
            }
            Rectangle {
                id: vbody
                width: Math.round(root.size * 0.3)
                height: Math.round(root.size * 0.5)
                radius: 3
                color: "transparent"
                border.width: 1.5
                border.color: root.frame
                Rectangle {
                    x: 2.5
                    width: parent.width - 5
                    height: Math.max(0, (parent.height - 5) * root.p / 100)
                    y: parent.height - 2.5 - height
                    radius: 1.5
                    color: root.fill
                    Behavior on height { Anim {} }
                }
                FIcon {
                    visible: root.charging
                    anchors.centerIn: parent
                    icon: "bolt"
                    size: Math.round(vbody.width * 1.05)
                    fill: 1
                    color: Theme.text
                    style: Text.Outline
                    styleColor: Theme.bg
                }
            }
        }
    }

    // ring gauge
    Component {
        id: ringC
        Item {
            width: Math.round(root.size * 0.64)
            height: width
            Canvas {
                id: arc
                anchors.fill: parent
                readonly property real v: root.p / 100
                readonly property color col: root.fill
                readonly property color track: Theme.alpha(Theme.text, 0.15)
                property real spin: 0
                onVChanged: requestPaint()
                onColChanged: requestPaint()
                onTrackChanged: requestPaint()
                onSpinChanged: requestPaint()
                onWidthChanged: requestPaint()
                NumberAnimation on spin {
                    running: root.charging && root.animate && root.visible
                    from: 0
                    to: Math.PI * 2
                    duration: 2400
                    loops: Animation.Infinite
                }
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    const c = width / 2, lw = Math.max(2.5, width / 9), r = c - lw / 2 - 0.5;
                    ctx.lineWidth = lw;
                    ctx.lineCap = "round";
                    ctx.strokeStyle = track;
                    ctx.beginPath();
                    ctx.arc(c, c, r, 0, Math.PI * 2);
                    ctx.stroke();
                    if (v > 0) {
                        const start = -Math.PI / 2 + (root.charging && root.animate ? spin : 0);
                        ctx.strokeStyle = col;
                        ctx.beginPath();
                        ctx.arc(c, c, r, start, start + Math.PI * 2 * v);
                        ctx.stroke();
                    }
                }
            }
            FIcon {
                visible: root.charging || !root.showPercent
                anchors.centerIn: parent
                icon: root.charging ? "bolt" : "battery_full"
                size: Math.round(parent.width * 0.5)
                fill: 1
                color: root.charging ? root.fill : Theme.textDim
            }
            FText {
                visible: !root.charging && root.showPercent
                anchors.centerIn: parent
                text: Math.round(root.p)
                font.pixelSize: Math.max(7, Math.round(parent.width * (root.p >= 100 ? 0.3 : 0.38)))
                font.weight: Font.Bold
            }
        }
    }

    // capsule
    Component {
        id: pillC
        Rectangle {
            id: cap
            width: Math.round(root.size * (root.showPercent ? 1.05 : 0.8))
            height: Math.round(root.size * 0.48)
            radius: height / 2
            color: Theme.alpha(Theme.text, 0.14)
            Item {
                anchors.fill: parent
                clip: true
                Rectangle {
                    width: Math.max(cap.height, cap.width * root.p / 100)
                    height: cap.height
                    radius: cap.radius
                    color: root.fill
                    Behavior on width { Anim {} }
                    Sweep {}
                }
            }
            Row {
                anchors.centerIn: parent
                spacing: 1
                FIcon {
                    visible: root.charging
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "bolt"
                    size: Math.round(cap.height * 0.72)
                    fill: 1
                    color: root.p > 45 ? root.onFill : Theme.text
                }
                FText {
                    visible: root.showPercent
                    anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(root.p)
                    font.pixelSize: Math.max(8, Math.round(cap.height * 0.6))
                    font.weight: Font.Black
                    color: root.p > 45 ? root.onFill : Theme.text
                }
            }
        }
    }

    // dot
    Component {
        id: dotC
        Rectangle {
            width: Math.round(root.size * 0.26)
            height: width
            radius: width / 2
            color: root.fill
            border.width: root.charging ? 2 : 0
            border.color: Theme.alpha(root.fill, 0.4)
            SequentialAnimation on scale {
                running: root.charging && root.animate && root.visible
                loops: Animation.Infinite
                NumberAnimation { to: 1.35; duration: 700; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutSine }
                onRunningChanged: if (!running) parent.scale = 1
            }
        }
    }

    // text: a bolt while charging (otherwise nothing before the percent)
    Component {
        id: boltC
        FIcon {
            visible: root.charging || !root.showPercent
            icon: root.charging ? "bolt" : "battery_full"
            size: Math.round(root.size * 0.46)
            fill: 1
            color: root.fill
        }
    }

    // the percent over a thin line
    Component {
        id: lineC
        Column {
            spacing: 2
            Row {
                id: lineLabel
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 1
                FIcon {
                    visible: root.charging
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "bolt"
                    size: Theme.fsSm
                    fill: 1
                    color: root.fill
                }
                FText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.showPercent ? root.pctText : ""
                    font.pixelSize: root.compact ? Theme.fsXs : Theme.fsSm
                    font.weight: Font.DemiBold
                }
            }
            Rectangle {
                width: Math.max(Math.round(root.size * 0.7), lineLabel.width)
                height: 3
                radius: 1.5
                color: Theme.alpha(Theme.text, 0.15)
                Rectangle {
                    width: parent.width * root.p / 100
                    height: parent.height
                    radius: parent.radius
                    color: root.fill
                    Behavior on width { Anim {} }
                    Sweep {}
                }
            }
        }
    }
}
