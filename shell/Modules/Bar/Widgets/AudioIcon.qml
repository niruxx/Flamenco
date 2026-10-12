import QtQuick
import qs.Commons
import qs.Services
import qs.Widgets

StatusIcon {
    icon: Audio.icon
    iconColor: Audio.muted ? Theme.textDim : Theme.text
    onMiddleClicked: Audio.toggleMute()
    onWheel: event => Audio.step(event.angleDelta.y > 0 ? 0.05 : -0.05)
}
