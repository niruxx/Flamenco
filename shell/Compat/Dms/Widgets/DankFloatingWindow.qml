pragma ComponentBehavior: Bound
// Vendored from https://github.com/AvengeMedia/DankMaterialShell (v1.6) and dank-qml-common (stable-1.6) (MIT) by tools/compat-vendor.py.
// Don't edit: change the vendoring tool or a Flamenco shim next to it.

import QtQuick
import Quickshell
import qs.Compat.Dms.Common

FloatingWindow {
    id: root

    default property alias content: contentItem.data

    property color surfaceColor: Theme.floatingWindowSurface

    color: "transparent"

    Rectangle {
        anchors.fill: parent
        color: root.surfaceColor
    }

    WindowBlur {
        targetWindow: root
        blurX: 0
        blurY: 0
        blurWidth: root.visible ? root.width : 0
        blurHeight: root.visible ? root.height : 0
    }

    Item {
        id: contentItem

        property bool disablePopupTransparency: true

        anchors.fill: parent
    }
}
