import QtQuick
import qs.Commons

ColorAnimation {
    property string area: ""
    duration: Theme.motionDuration("color", area)
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Theme.curves.standard
}
