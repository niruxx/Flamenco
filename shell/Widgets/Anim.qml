import QtQuick
import qs.Commons

NumberAnimation {
    property string motionRole: "move"
    property string area: ""
    duration: Theme.motionDuration(motionRole, area)
    easing.type: Easing.BezierSpline
    easing.bezierCurve: motionRole === "enter" ? Theme.curves.emphasizedDecel
        : motionRole === "exit" ? Theme.curves.emphasizedAccel
        : motionRole === "shape" ? Theme.curves.spring : Theme.curves.standard
}
