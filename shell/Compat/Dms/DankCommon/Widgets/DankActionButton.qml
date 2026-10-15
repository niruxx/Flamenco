// Vendored from https://github.com/AvengeMedia/DankMaterialShell (v1.6) and dank-qml-common (stable-1.6) (MIT) by tools/compat-vendor.py.
// Don't edit: change the vendoring tool or a Flamenco shim next to it.
import QtQuick
import qs.Compat.Dms.DankCommon.Common
import qs.Compat.Dms.DankCommon.Widgets

StyledRect {
    id: root

    property string iconName: ""
    property int iconSize: Style.iconSize - 4
    property color iconColor: Style.surfaceText
    property color backgroundColor: "transparent"
    property bool circular: true
    property int buttonSize: 32
    property var tooltipText: null
    property string tooltipSide: "bottom"
    readonly property alias pressed: stateLayer.pressed

    signal clicked
    signal entered
    signal exited

    width: buttonSize
    height: buttonSize
    radius: Style.cornerRadius
    color: backgroundColor
    activeFocusOnTab: enabled

    Keys.onPressed: event => {
        if (!root.enabled)
            return;
        switch (event.key) {
        case Qt.Key_Space:
        case Qt.Key_Return:
        case Qt.Key_Enter:
            root.clicked();
            event.accepted = true;
            break;
        }
    }

    FocusRing {}

    DankIcon {
        anchors.centerIn: parent
        name: root.iconName
        size: root.iconSize
        color: root.iconColor
    }

    StateLayer {
        id: stateLayer
        disabled: !root.enabled
        stateColor: Style.primary
        cornerRadius: root.radius
        onClicked: root.clicked()
        onEntered: root.entered()
        onExited: root.exited()
        tooltipText: root.tooltipText
        tooltipSide: root.tooltipSide
    }
}
