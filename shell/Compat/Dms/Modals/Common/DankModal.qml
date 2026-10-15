import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons as F
import qs.Services as FS
import qs.Compat.Dms.Common

// Flamenco's version of DMS's DankModal: a centered card over a dimmed screen,
// with the same properties, signals and functions.
Item {
    id: root

    property string layerNamespace: "dms:modal"
    property Component content: null
    property Item directContent: null
    property real modalWidth: 400
    property real modalHeight: 300
    property var targetScreen
    property bool showBackground: true
    property real backgroundOpacity: 0.5
    property string positioning: "center"
    property point customPosition: Qt.point(0, 0)
    property bool closeOnEscapeKey: true
    property bool closeOnBackgroundClick: true
    property string animationType: "scale"
    property int animationDuration: Theme.modalAnimationDuration
    property real animationScaleCollapsed: 0.96
    property real animationOffset: Theme.spacingL
    property list<real> animationEnterCurve: Theme.expressiveCurves.expressiveDefaultSpatial
    property list<real> animationExitCurve: Theme.expressiveCurves.emphasized
    property color backgroundColor: Theme.withAlpha(Theme.surfaceContainer, Theme.popupTransparency)
    property color borderColor: Theme.outlineMedium
    property real borderWidth: 0
    property real cornerRadius: Theme.cornerRadius
    property bool enableShadow: true
    property bool shouldBeVisible: false
    property bool shouldHaveFocus: shouldBeVisible
    property bool allowFocusOverride: false
    property bool allowStacking: false
    property bool keepContentLoaded: false
    property bool keepPopoutsOpen: false
    property var customKeyboardFocus: null
    property bool useOverlayLayer: false
    readonly property var transientSurfaceTracker: null

    signal opened
    signal dialogClosed
    signal backgroundClicked

    readonly property var contentLoader: win.item ? win.item.loader : null
    readonly property alias modalFocusScope: focusScope
    readonly property var contentWindow: win.item
    readonly property var effectiveScreen: targetScreen ?? Quickshell.screens.find(s => s.name === FS.Niri.focusedOutput) ?? Quickshell.screens[0]
    readonly property real screenWidth: effectiveScreen?.width ?? 1920
    readonly property real screenHeight: effectiveScreen?.height ?? 1080
    readonly property real dpr: effectiveScreen?.devicePixelRatio ?? 1
    property bool isClosing: false
    readonly property real alignedX: positioning === "custom" ? customPosition.x : (screenWidth - modalWidth) / 2
    readonly property real alignedY: positioning === "custom" ? customPosition.y : (screenHeight - modalHeight) / 2
    readonly property real alignedWidth: modalWidth
    readonly property real alignedHeight: modalHeight

    function open() {
        isClosing = false;
        shouldBeVisible = true;
        opened();
    }
    function close() {
        if (!shouldBeVisible)
            return;
        isClosing = true;
        shouldBeVisible = false;
        closeTimer.restart();
    }
    function instantClose() {
        shouldBeVisible = false;
        isClosing = false;
        dialogClosed();
    }
    function toggle() {
        shouldBeVisible ? close() : open();
    }

    Timer {
        id: closeTimer
        interval: Math.max(1, root.animationDuration)
        onTriggered: {
            root.isClosing = false;
            root.dialogClosed();
        }
    }

    FocusScope {
        id: focusScope
    }

    LazyLoader {
        id: win
        active: root.shouldBeVisible || root.isClosing || root.keepContentLoaded

        PanelWindow {
            id: w
            readonly property alias loader: loader
            screen: root.effectiveScreen
            visible: root.shouldBeVisible || root.isClosing
            color: "transparent"
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: root.useOverlayLayer ? WlrLayer.Overlay : WlrLayer.Top
            WlrLayershell.namespace: root.layerNamespace
            WlrLayershell.keyboardFocus: root.shouldHaveFocus ? (root.customKeyboardFocus ?? WlrKeyboardFocus.Exclusive) : WlrKeyboardFocus.None

            Rectangle {
                anchors.fill: parent
                color: root.showBackground ? Qt.rgba(0, 0, 0, root.backgroundOpacity) : "transparent"
                opacity: root.shouldBeVisible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: root.animationDuration } }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.backgroundClicked();
                        if (root.closeOnBackgroundClick)
                            root.close();
                    }
                }
            }

            Rectangle {
                id: card
                x: root.alignedX
                y: root.alignedY
                width: root.modalWidth
                height: root.modalHeight
                radius: root.cornerRadius
                color: root.backgroundColor
                border.color: root.borderColor
                border.width: root.borderWidth || 1
                opacity: root.shouldBeVisible ? 1 : 0
                scale: root.shouldBeVisible ? 1 : root.animationScaleCollapsed
                Behavior on opacity { NumberAnimation { duration: root.animationDuration } }
                Behavior on scale { NumberAnimation { duration: root.animationDuration; easing.type: Easing.OutCubic } }

                MouseArea {
                    anchors.fill: parent
                }

                FocusScope {
                    anchors.fill: parent
                    focus: true
                    Keys.onEscapePressed: event => {
                        if (root.closeOnEscapeKey) {
                            root.close();
                            event.accepted = true;
                        }
                    }

                    Loader {
                        id: loader
                        anchors.fill: parent
                        active: root.content !== null
                        sourceComponent: root.content
                        focus: true
                    }
                }

                Component.onCompleted: {
                    if (root.directContent) {
                        root.directContent.parent = card;
                        root.directContent.anchors.fill = card;
                    }
                }
            }
        }
    }
}
