// Vendored from https://github.com/AvengeMedia/DankMaterialShell (v1.6) and dank-qml-common (stable-1.6) (MIT) by tools/compat-vendor.py.
// Don't edit: change the vendoring tool or a Flamenco shim next to it.
import QtQuick

SequentialAnimation {
    id: root

    property Item target
    property real minOpacity: 0.3
    property int pulseDuration: 600

    loops: Animation.Infinite

    NumberAnimation {
        target: root.target
        property: "opacity"
        to: root.minOpacity
        duration: root.pulseDuration
        easing.type: Easing.InOutQuad
    }
    NumberAnimation {
        target: root.target
        property: "opacity"
        to: 1.0
        duration: root.pulseDuration
        easing.type: Easing.InOutQuad
    }

    onStopped: if (root.target)
        root.target.opacity = 1.0
}
