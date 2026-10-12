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

        readonly property real travel: Theme.barTop ? -18 : 18

        width: root.cardWidth
        height: inner.implicitHeight + root.cardPadding * 2
        x: root.hAlign === "left" ? Theme.gap : root.hAlign === "right" ? parent.width - width - Theme.gap : (parent.width - width) / 2
        y: root.centered ? (parent.height - height) / 2.6 : Theme.barTop ? Theme.gap : parent.height - height - Theme.gap

        radius: Theme.rXl
        color: Theme.panelBg
        border.width: 1
        border.color: Theme.alpha(Theme.border, 0.7)

        opacity: root.progress
        scale: 0.94 + 0.06 * root.progress
        transformOrigin: root.centered ? Item.Center : Theme.barTop ? Item.Top : Item.Bottom
        transform: Translate { y: (1 - root.progress) * card.travel }

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

        Item {
            id: inner
            anchors.fill: parent
            anchors.margins: root.cardPadding
            implicitHeight: children.length > 0 ? children[0].implicitHeight : 0
        }
    }
}
