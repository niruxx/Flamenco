import QtQuick
import qs.Commons
import qs.Services
import qs.Widgets

// Niri workspaces for this output, in a compact capsule.
// Empty = faint dot, occupied = bright dot, active = accent pill that glides.
Rectangle {
    id: root

    property string screenName
    readonly property var list: Niri.workspacesOn(screenName)
    readonly property int activeIndex: list.findIndex(w => w.is_active)
    property int barLevel: 0
    readonly property string style: barLevel >= 2 ? "dots" : Settings.data.bar.workspaceStyle
    readonly property bool numbers: style === "numbers"

    // geometry, all derived from the bar height
    readonly property int capsuleH: Theme.barHeight - 12
    readonly property int dot: numbers ? capsuleH - 8 : style === "dots" ? Math.round(capsuleH * 0.26) : Math.round(capsuleH * 0.34)
    readonly property int activeW: numbers ? dot : style === "dots" ? dot * 2.2 : dot * 2.8
    readonly property int gap: numbers ? 2 : 4
    readonly property int pad: numbers ? 4 : 8
    readonly property bool vertical: Theme.barVertical

    implicitWidth: vertical ? capsuleH : row.implicitWidth + pad * 2
    implicitHeight: vertical ? row.implicitHeight + pad * 2 : capsuleH
    radius: height / 2
    color: Theme.alpha(Theme.text, 0.06)
    property bool barVisible: list.length > 0

    Behavior on implicitWidth { enabled: !root.vertical; Anim { duration: Theme.durLong; easing.bezierCurve: Theme.curves.emphasizedDecel } }
    Behavior on implicitHeight { enabled: root.vertical; Anim { duration: Theme.durLong; easing.bezierCurve: Theme.curves.emphasizedDecel } }

    // the gliding highlight
    Rectangle {
        readonly property Item target: rep.count > 0 && root.activeIndex >= 0 ? rep.itemAt(root.activeIndex) : null
        visible: target !== null
        x: root.vertical ? (parent.width - width) / 2 : row.x + (target?.x ?? 0)
        y: root.vertical ? row.y + (target?.y ?? 0) : (parent.height - height) / 2
        width: root.vertical ? root.dot : target?.width ?? 0
        height: root.vertical ? target?.height ?? 0 : root.dot
        radius: root.numbers ? Theme.rXs : height / 2
        color: Theme.accent

        Behavior on x { Anim { duration: Theme.durLong; easing.bezierCurve: Theme.curves.spring } }
        Behavior on width { Anim { duration: Theme.durLong; easing.bezierCurve: Theme.curves.spring } }
        Behavior on y { Anim { duration: Theme.durLong; easing.bezierCurve: Theme.curves.spring } }
        Behavior on height { Anim { duration: Theme.durLong; easing.bezierCurve: Theme.curves.spring } }
    }

    Grid {
        id: row
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

                Behavior on width { enabled: !root.vertical; Anim { duration: Theme.durLong; easing.bezierCurve: Theme.curves.spring } }
                Behavior on height { enabled: root.vertical; Anim { duration: Theme.durLong; easing.bezierCurve: Theme.curves.spring } }

                Rectangle {
                    anchors.centerIn: parent
                    width: root.vertical ? root.dot : parent.width
                    height: root.vertical ? parent.height : root.dot
                    radius: root.numbers ? Theme.rXs : height / 2
                    scale: hover.hovered && !ws.active ? 1.25 : 1
                    color: ws.active ? "transparent" : root.numbers ? (ws.occupied ? Theme.alpha(Theme.text, 0.12) : "transparent") : ws.occupied ? Theme.alpha(Theme.text, 0.55) : Theme.alpha(Theme.text, 0.2)

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

    WheelHandler {
        onWheel: event => Niri.action(event.angleDelta.y > 0 ? "focus-workspace-up" : "focus-workspace-down")
    }
}
