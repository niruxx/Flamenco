import QtQuick
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

// Niri workspaces for this output, in a compact capsule.
// Empty = faint dot, occupied = bright dot, active = accent pill that glides.
// "apps" style: each workspace with windows shows their app icons.
Rectangle {
    id: root

    property string screenName
    readonly property var wcfg: Settings.data.workspaces
    readonly property var list: Niri.workspacesOn(screenName).filter(w => !wcfg.hideEmpty || w.is_active || Niri.windowsOn(w.id).length > 0)
    readonly property int windowCount: activeIndex >= 0 ? Niri.windowsOn(list[activeIndex].id).length : 0
    readonly property bool showCount: wcfg.showCount && barLevel < 2
    readonly property int activeIndex: list.findIndex(w => w.is_active)
    property int barLevel: 0
    readonly property string style: barLevel >= 2 ? "dots" : Settings.data.bar.workspaceStyle
    readonly property bool numbers: style === "numbers"
    readonly property bool apps: style === "apps" && !Theme.barVertical

    // geometry, all derived from the bar height
    readonly property int capsuleH: Theme.barItem - 2
    readonly property int dot: numbers ? capsuleH - 10 : style === "dots" ? Math.round(capsuleH * 0.26) : Math.round(capsuleH * 0.34)
    readonly property int activeW: numbers ? dot : style === "dots" ? dot * 2.2 : dot * 2.8
    readonly property int gap: numbers ? 2 : 4
    readonly property int tileR: Math.min(Theme.rXs, Math.floor(dot / 2))
    readonly property int pad: numbers ? Math.max(3, Math.ceil(endInset(capsuleH, dot, tileR)) + 1) : 8

    // how far from the capsule's end a square (side s, corner radius r) has to sit
    // so its corners stay inside the rounded end (radius h / 2)
    function endInset(h, s, r) {
        const R = h / 2, a = R - r, b = s / 2 - r;
        return R - r - Math.sqrt(Math.max(0, a * a - b * b));
    }
    readonly property bool vertical: Theme.barVertical

    readonly property real countSize: showCount ? (vertical ? count.implicitHeight : count.implicitWidth) + gap + 2 : 0
    implicitWidth: apps ? appsRow.implicitWidth + 8 : vertical ? capsuleH : row.implicitWidth + pad * 2 + countSize
    implicitHeight: vertical ? row.implicitHeight + pad * 2 + countSize : capsuleH
    radius: height / 2
    color: apps ? "transparent" : Theme.alpha(Theme.text, 0.06)
    property bool barVisible: list.length > 0

    Behavior on implicitWidth { enabled: !root.vertical; Anim { duration: Theme.durA("workspaces", 450); easing.bezierCurve: Theme.curves.emphasizedDecel } }
    Behavior on implicitHeight { enabled: root.vertical; Anim { duration: Theme.durA("workspaces", 450); easing.bezierCurve: Theme.curves.emphasizedDecel } }

    // the gliding highlight
    Rectangle {
        visible: target !== null && !root.apps
        readonly property Item target: rep.count > 0 && root.activeIndex >= 0 ? rep.itemAt(root.activeIndex) : null
        x: root.vertical ? (parent.width - width) / 2 : row.x + (target?.x ?? 0)
        y: root.vertical ? row.y + (target?.y ?? 0) : (parent.height - height) / 2
        width: root.vertical ? root.dot : target?.width ?? 0
        height: root.vertical ? target?.height ?? 0 : root.dot
        radius: root.numbers ? root.tileR : height / 2
        color: Theme.accent

        Behavior on x { Anim { duration: Theme.durA("workspaces", 450); easing.bezierCurve: Theme.curves.spring } }
        Behavior on width { Anim { duration: Theme.durA("workspaces", 450); easing.bezierCurve: Theme.curves.spring } }
        Behavior on y { Anim { duration: Theme.durA("workspaces", 450); easing.bezierCurve: Theme.curves.spring } }
        Behavior on height { Anim { duration: Theme.durA("workspaces", 450); easing.bezierCurve: Theme.curves.spring } }
    }

    Grid {
        id: row
        visible: !root.apps
        columns: root.vertical ? 1 : Math.max(1, root.list.length)
        x: root.vertical ? (parent.width - width) / 2 : root.pad
        y: root.vertical ? root.pad : (parent.height - height) / 2
        spacing: root.gap

        Repeater {
            id: rep
            // index-keyed so delegates survive niri state updates and can animate
            model: root.list.length

            delegate: Item {
                id: ws
                required property int index
                readonly property var info: root.list[index] ?? ({})
                readonly property bool active: info.is_active ?? false
                readonly property bool occupied: Niri.windowsOn(info.id).length > 0

                readonly property real main: active ? root.activeW : root.dot
                width: root.vertical ? root.capsuleH : main
                height: root.vertical ? main : root.capsuleH

                Behavior on width { enabled: !root.vertical; Anim { duration: Theme.durA("workspaces", 450); easing.bezierCurve: Theme.curves.spring } }
                Behavior on height { enabled: root.vertical; Anim { duration: Theme.durA("workspaces", 450); easing.bezierCurve: Theme.curves.spring } }

                Rectangle {
                    anchors.centerIn: parent
                    width: root.vertical ? root.dot : parent.width
                    height: root.vertical ? parent.height : root.dot
                    radius: root.numbers ? root.tileR : height / 2
                    // squares fill the capsule's height, so they light up instead of growing past its ends
                    scale: hover.hovered && !ws.active && !root.numbers && Theme.hoverZoom ? 1.25 : 1
                    color: ws.active ? "transparent" : root.numbers ? (hover.hovered ? Theme.alpha(Theme.text, 0.2) : ws.occupied ? Theme.alpha(Theme.text, 0.12) : "transparent") : ws.occupied ? Theme.alpha(Theme.text, 0.55) : Theme.alpha(Theme.text, 0.2)

                    Behavior on color { CAnim {} }
                    Behavior on scale { Anim { duration: Theme.durShort; easing.bezierCurve: Theme.curves.springFast } }
                }

                FText {
                    anchors.centerIn: parent
                    visible: root.numbers
                    text: ws.info.name || ws.info.idx || ""
                    font.pixelSize: Theme.fsXs
                    font.weight: Font.Bold
                    color: ws.active ? Theme.onAccent : ws.occupied ? Theme.text : Theme.textDim
                }

                HoverHandler {
                    id: hover
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: Niri.focusWorkspace(ws.info)
                }
            }
        }
    }

    // "apps": the workspace's apps in a pill; the active one filled, an empty one a dot
    Row {
        id: appsRow
        visible: root.apps
        x: 4
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5

        Repeater {
            // workspace ids, diffed: focus moving or a title changing doesn't rebuild the icons
            model: ScriptModel { values: root.apps ? root.list.map(w => w.id) : [] }

            delegate: Rectangle {
                id: aw
                required property var modelData        // the workspace id
                readonly property var ws: root.list.find(w => w.id === modelData) ?? ({})
                readonly property bool active: !!ws.is_active
                readonly property var ids: {
                    const out = [];
                    for (const w of Niri.windowsOn(aw.modelData))
                        if (w.app_id && !out.includes(w.app_id))
                            out.push(w.app_id);
                    return out;
                }
                readonly property bool empty: ids.length === 0
                readonly property int h: root.capsuleH - 2
                readonly property int iconSize: h - 10
                height: empty && !active ? 7 : h
                width: empty && !active ? 7 : content.implicitWidth + (h - iconSize)
                anchors.verticalCenter: parent.verticalCenter
                radius: height / 2
                color: active ? Theme.accent : empty ? Theme.alpha(Theme.text, hoverA.hovered ? 0.5 : 0.28) : Theme.alpha(Theme.accent2, hoverA.hovered ? 0.28 : 0.16)
                border.width: active || empty ? 0 : 1
                border.color: Theme.alpha(Theme.accent2, 0.5)
                scale: hoverA.hovered && Theme.hoverZoom && !active ? 1.06 : 1

                Behavior on width { Anim { duration: Theme.durA("workspaces", 450); easing.bezierCurve: Theme.curves.spring } }
                Behavior on color { CAnim {} }
                Behavior on scale { Anim { duration: Theme.durShort; easing.bezierCurve: Theme.curves.springFast } }

                Row {
                    id: content
                    anchors.centerIn: parent
                    visible: !aw.empty || aw.active
                    spacing: 3
                    FText {
                        visible: aw.active
                        anchors.verticalCenter: parent.verticalCenter
                        text: aw.ws.name || aw.ws.idx || ""
                        font.pixelSize: Theme.fsSm
                        font.weight: Font.Bold
                        color: Theme.onAccent
                        leftPadding: aw.empty ? 4 : 2
                        rightPadding: aw.empty ? 4 : 1
                    }
                    Repeater {
                        model: aw.ids.slice(0, 4)
                        AppIcon {
                            required property var modelData
                            anchors.verticalCenter: parent.verticalCenter
                            implicitSize: aw.iconSize
                            name: Apps.iconFor(modelData)
                        }
                    }
                    FText {
                        visible: aw.ids.length > 4
                        anchors.verticalCenter: parent.verticalCenter
                        text: "+" + (aw.ids.length - 4)
                        font.pixelSize: Theme.fsXs
                        font.weight: Font.Bold
                        color: aw.active ? Theme.onAccent : Theme.text
                    }
                }

                HoverHandler {
                    id: hoverA
                    cursorShape: Qt.PointingHandCursor
                }
                TapHandler {
                    onTapped: Niri.focusWorkspace(aw.ws)
                }
            }
        }
    }

    // windows on the current workspace
    FText {
        id: count
        visible: root.showCount && !root.apps
        x: root.vertical ? (parent.width - width) / 2 : row.x + row.width + root.gap + 2
        y: root.vertical ? row.y + row.height + root.gap + 2 : (parent.height - height) / 2
        text: root.windowCount
        font.pixelSize: Theme.fsXs
        font.weight: Font.Bold
        color: Theme.textDim
    }

    WheelHandler {
        enabled: root.wcfg.scrollSwitch
        onWheel: event => Niri.action((event.angleDelta.y > 0) !== root.wcfg.invertScroll ? "focus-workspace-up" : "focus-workspace-down")
    }
}
