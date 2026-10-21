import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services

// Base for every popout (control center, launcher, calendar, …).
// One instance per screen; it shows when Panels.current === name on its screen.
// Handles: click-outside-to-close, Esc, keyboard focus, dimming, and the
// open/close motion (rise + scale + fade on an emphasized curve).
PanelWindow {
    id: root

    required property ShellScreen modelData
    property string name
    property string hAlign: "center"     // left | center | right
    property bool centered: false        // vertically centered instead of hugging the bar
    // Explicit screen placement, overriding centered/hAlign:
    // center | top | bottom | top-left | top-right | bottom-left | bottom-right | bar
    property string placement: ""
    readonly property string place: placement !== "" ? placement : centered ? "center" : "bar"
    property bool exclusiveKeyboard: false
    // how it opens (Settings → Appearance → Motion): rise | fade | slide | zoom | none
    readonly property string effect: Settings.data.appearance.panelEffect || "rise"
    // open on the side of the bar widget that opened it (false: always at hAlign)
    property bool followOrigin: true
    property int cardWidth: 420
    property int cardPadding: Theme.sp4
    property alias card: card
    default property alias content: inner.data

    readonly property bool shouldShow: Panels.current === name && Panels.screen === modelData.name
    readonly property real progress: progressAnim.v

    signal opened

    screen: modelData
    visible: shouldShow || progress > 0.001
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "flamenco-" + name

        // animated value lives on an Item: Behaviors on the window itself crash Qt 6.12
        Item {
            id: progressAnim
            property real v: shouldShow ? 1 : 0
            Behavior on v { Anim { duration: root.effect === "none" ? 0 : Theme.durA("panels", 450); easing.bezierCurve: Theme.curves.emphasizedDecel } }
        }
    WlrLayershell.keyboardFocus: shouldShow ? (exclusiveKeyboard ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand) : WlrKeyboardFocus.None

    // where it was opened from (see Panels.noteOrigin), kept while it closes
    property string openedFrom: ""
    property real openedAt: -1

    onShouldShowChanged: if (shouldShow) {
        openedFrom = Panels.side;
        openedAt = Panels.anchor;
        keys.forceActiveFocus();
        opened();
    }

    // Dim + click-outside catcher
    Rectangle {
        anchors.fill: parent
        color: Theme.shadow
        opacity: Settings.data.appearance.dimBehindPanels ? 0.18 * root.progress : 0

        MouseArea {
            anchors.fill: parent
            onClicked: Panels.close()
        }
    }

    Item {
        id: keys
        focus: true
        Keys.onEscapePressed: Panels.close()
    }

    Rectangle {
        id: card

        // which edge the card grows from: the bar's edge, or none when centered
        readonly property string edge: root.place === "bar" ? Theme.barPos : root.place === "center" ? "" : root.place.startsWith("bottom") ? "bottom" : "top"
        readonly property real travel: (edge === "top" || edge === "left" ? -1 : 1) * (root.effect === "slide" ? 70 : root.effect === "rise" ? 18 : 0)
        // opened from a bar widget: on that widget's side of the bar (Panels.side)
        readonly property string from: root.place === "bar" && root.followOrigin ? root.openedFrom : ""
        readonly property string fromAlign: from === "start" ? "left" : from === "end" ? "right" : from === "center" ? "anchor" : ""
        readonly property string hPos: root.place === "bar" ? (edge === "left" || edge === "right" ? edge : fromAlign || root.hAlign) : root.place.endsWith("left") ? "left" : root.place.endsWith("right") ? "right" : "center"
        // distance kept from the screen's sides
        readonly property real side: blend ? inset : Theme.edge
        function clampTo(v, size, room) {
            return Math.max(side, Math.min(room - size - side, v));
        }

        // Blend (Settings → Appearance): the card grows out of the bar as one
        // surface, flush against it in the bar's color, joined by concave corners
        readonly property bool blend: Theme.blendPanels && root.place === "bar"
        readonly property int fillet: Math.min(Theme.rXl, 24)
        // keep clear of the bar's ends (margin + rounded corner) so the joins sit on its straight part
        readonly property int inset: blend ? Theme.barMargin + (Theme.barFlush ? 0 : Theme.barRadius) + fillet : Theme.edge
        readonly property bool alongTop: edge === "top" || edge === "bottom"

        width: Math.min(root.cardWidth, parent.width - Theme.edge * 2)
        // never taller than the screen (minus a gap); the content scrolls instead
        height: Math.min(inner.implicitHeight + root.cardPadding * 2, parent.height - Theme.edge * 2)
        x: blend && edge === "left" ? 0 : blend && edge === "right" ? parent.width - width
            : edge === "left" ? Theme.edge : edge === "right" ? parent.width - width - Theme.edge
            : hPos === "left" ? side : hPos === "right" ? parent.width - width - side
            : hPos === "anchor" && root.openedAt >= 0 ? clampTo(root.openedAt - width / 2, width, parent.width)
            : (parent.width - width) / 2
        // on a side bar, along its length: top, bottom, or level with the widget
        readonly property real alongY: from === "end" ? parent.height - height - side
            : from === "center" && root.openedAt >= 0 ? clampTo(root.openedAt - height / 2, height, parent.height)
            : side
        y: root.place === "center" ? (parent.height - height) / 2.6
            : blend && edge === "top" ? 0 : blend && edge === "bottom" ? parent.height - height
            : edge === "left" || edge === "right" ? alongY
            : edge === "bottom" ? parent.height - height - Theme.edge : Theme.edge

        radius: Theme.rXl
        // square where it meets the bar
        topLeftRadius: blend && (edge === "top" || edge === "left") ? 0 : Theme.rXl
        topRightRadius: blend && (edge === "top" || edge === "right") ? 0 : Theme.rXl
        bottomLeftRadius: blend && (edge === "bottom" || edge === "left") ? 0 : Theme.rXl
        bottomRightRadius: blend && (edge === "bottom" || edge === "right") ? 0 : Theme.rXl
        color: blend ? Theme.barBg : Theme.panelBg
        border.width: blend ? 0 : 1
        border.color: Theme.alpha(Theme.border, 0.7)

        // the surface finish (gloss / chrome), under the content (not on a card joined to the bar,
        // whose square corners it wouldn't follow)
        Finish { visible: !card.blend && (Settings.data.appearance.finish || "flat") !== "flat" }

        opacity: card.blend || root.effect === "slide" ? Math.min(1, root.progress * 1.6) : root.progress
        // blended cards slide out from under the bar instead of zooming
        scale: card.blend ? 1 : root.effect === "zoom" ? 0.8 + 0.2 * root.progress : root.effect === "rise" ? 0.94 + 0.06 * root.progress : 1
        transformOrigin: card.edge === "top" ? Item.Top : card.edge === "bottom" ? Item.Bottom : card.edge === "left" ? Item.TopLeft : card.edge === "right" ? Item.TopRight : Item.Center
        transform: Translate {
            readonly property bool sideways: card.edge === "left" || card.edge === "right"
            readonly property real dist: card.blend ? (sideways ? card.width : card.height) * 0.35 : Math.abs(card.travel)
            readonly property real sign: card.edge === "top" || card.edge === "left" ? -1 : 1
            x: sideways ? (1 - root.progress) * dist * sign : 0
            y: sideways || card.edge === "" ? 0 : (1 - root.progress) * dist * sign
        }

        // the concave joins on either side of a blended card
        Fillet { host: card; visible: card.blend; first: true }
        Fillet { host: card; visible: card.blend; first: false }

        layer.enabled: Settings.data.appearance.shadows && !card.blend
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Theme.alpha(Theme.shadow, 0.45)
            shadowBlur: 1.0
            shadowVerticalOffset: 6
            blurMax: 32
        }

        Behavior on height { Anim { easing.bezierCurve: Theme.curves.emphasizedDecel } }

        // swallow clicks so they don't reach the close catcher
        MouseArea { anchors.fill: parent }

        FScroll {
            id: scroller
            anchors.fill: parent
            anchors.margins: root.cardPadding
            contentHeight: inner.implicitHeight
            // only grab drags when there's something to scroll, so sliders and swipes inside work normally
            interactive: contentHeight > height + 1

            Item {
                id: inner
                width: scroller.width
                height: implicitHeight
                implicitHeight: children.length > 0 ? children[0].implicitHeight : 0
            }
        }
    }

    // A square of the bar's color with a quarter circle cut out, filling the
    // corner between the bar and one side of a blended card.
    component Fillet: Canvas {
        id: f
        required property var host     // the card (inline components can't see this file's ids)
        property bool first: true      // left (or top, on a side bar) of the card
        readonly property int r: f.host.fillet
        readonly property string edge: f.host.edge
        readonly property color fill: Theme.barBg
        width: r
        height: r
        x: f.host.alongTop ? (first ? -r : f.host.width) : (edge === "left" ? 0 : f.host.width - r)
        y: f.host.alongTop ? (edge === "top" ? 0 : f.host.height - r) : (first ? -r : f.host.height)
        // the cut-out circle's center: the corner of this square away from the bar and the card
        readonly property point hole: f.host.alongTop
            ? Qt.point(first ? 0 : r, edge === "top" ? r : 0)
            : Qt.point(edge === "left" ? r : 0, first ? 0 : r)
        onFillChanged: requestPaint()
        onHoleChanged: requestPaint()
        onVisibleChanged: if (visible) requestPaint()
        onRChanged: requestPaint()
        // draw the curved shape itself (no erasing): from the square's corner next
        // to the hole, across its far corner, to the other side, and back along
        // the quarter circle around the hole
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const r = f.r, h = f.hole;
            const a = Qt.point(r - h.x, h.y);          // beside the hole, along x
            const o = Qt.point(r - h.x, r - h.y);      // the far corner
            const b = Qt.point(h.x, r - h.y);          // beside the hole, along y
            const angA = Math.atan2(a.y - h.y, a.x - h.x);
            const angB = Math.atan2(b.y - h.y, b.x - h.x);
            let sweep = angA - angB;
            while (sweep > Math.PI)
                sweep -= 2 * Math.PI;
            while (sweep <= -Math.PI)
                sweep += 2 * Math.PI;
            ctx.fillStyle = f.fill;
            ctx.beginPath();
            ctx.moveTo(a.x, a.y);
            ctx.lineTo(o.x, o.y);
            ctx.lineTo(b.x, b.y);
            ctx.arc(h.x, h.y, r, angB, angA, sweep < 0);
            ctx.closePath();
            ctx.fill();
        }
    }
}
