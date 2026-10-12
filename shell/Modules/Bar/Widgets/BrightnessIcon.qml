import QtQuick
import qs.Commons
import qs.Services
import qs.Widgets

StatusIcon {
    barVisible: Brightness.available
    icon: "brightness_6"
    onWheel: event => Brightness.step(event.angleDelta.y > 0 ? 0.05 : -0.05)
}
