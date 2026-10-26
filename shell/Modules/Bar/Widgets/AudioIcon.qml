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
    onWheel: event => {
        const n = notches.take(event);
        if (n !== 0)
            Audio.step(0.05 * n);
    }
    WheelSteps { id: notches }
}
