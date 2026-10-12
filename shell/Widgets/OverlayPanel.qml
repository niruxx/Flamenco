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
            Behavior on v { Anim { duration: Theme.durLong; easing.bezierCurve: Theme.curves.emphasizedDecel } }
        }
    WlrLayershell.keyboardFocus: shouldShow ? (exclusiveKeyboard ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand) : WlrKeyboardFocus.None

    onShouldShowChanged: if (shouldShow) {
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
        readonly property real travel: edge === "top" || edge === "left" ? -18 : 18
        readonly property string hPos: root.place === "bar" ? (edge === "left" || edge === "right" ? edge : root.hAlign) : root.place.endsWith("left") ? "left" : root.place.endsWith("right") ? "right" : "center"

        width: Math.min(root.cardWidth, parent.width - Theme.gap * 2)
        // never taller than the screen (minus a gap); the content scrolls instead
        height: Math.min(inner.implicitHeight + root.cardPadding * 2, parent.height - Theme.gap * 2)
        x: hPos === "left" ? Theme.gap : hPos === "right" ? parent.width - width - Theme.gap : (parent.width - width) / 2
        y: root.place === "center" ? (parent.height - height) / 2.6 : edge === "bottom" ? parent.height - height - Theme.gap : Theme.gap

        radius: Theme.rXl
        color: Theme.panelBg
        border.width: 1
        border.color: Theme.alpha(Theme.border, 0.7)

        opacity: root.progress
        scale: 0.94 + 0.06 * root.progress
        transformOrigin: card.edge === "top" ? Item.Top : card.edge === "bottom" ? Item.Bottom : card.edge === "left" ? Item.TopLeft : card.edge === "right" ? Item.TopRight : Item.Center
        transform: Translate {
            readonly property bool sideways: card.edge === "left" || card.edge === "right"
            x: sideways ? (1 - root.progress) * card.travel : 0
            y: sideways || card.edge === "" ? 0 : (1 - root.progress) * card.travel
        }

        layer.enabled: Settings.data.appearance.shadows
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
}
