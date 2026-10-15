// Vendored from https://github.com/AvengeMedia/DankMaterialShell (v1.6) and dank-qml-common (stable-1.6) (MIT) by tools/compat-vendor.py.
// Don't edit: change the vendoring tool or a Flamenco shim next to it.
import QtQuick

// Reusable ColorAnimation wrapper
ColorAnimation {
    duration: Style.expressiveDurations.normal
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Style.expressiveCurves.standard
}
