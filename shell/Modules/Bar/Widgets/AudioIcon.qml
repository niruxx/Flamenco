import QtQuick
import qs.Commons
import qs.Services
import qs.Widgets

StatusIcon {
    icon: Audio.icon
    // its own popout (volume + outputs + apps), not the control center
    panel: "volume"
    iconColor: Audio.muted ? Theme.textDim : Theme.text
    onMiddleClicked: Audio.toggleMute()
    onWheel: event => Audio.step(event.angleDelta.y > 0 ? 0.05 : -0.05)
}
