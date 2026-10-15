// Vendored from https://github.com/AvengeMedia/DankMaterialShell (v1.6) and dank-qml-common (stable-1.6) (MIT) by tools/compat-vendor.py.
// Don't edit: change the vendoring tool or a Flamenco shim next to it.
import QtQuick
import qs.Compat.Dms.DankCommon.Widgets

DankActionButton {
    id: root

    property bool busy: false

    iconName: busy ? "" : "refresh"
    enabled: !busy

    DankSpinner {
        anchors.centerIn: parent
        size: root.iconSize
        strokeWidth: 2
        color: root.iconColor
        running: root.busy
        visible: root.busy
    }
}
