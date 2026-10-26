import QtQuick
import qs.Commons
import qs.Services
import qs.Widgets

StatusIcon {
    barVisible: Brightness.available
    icon: "brightness_6"
    onWheel: event => {
        const n = notches.take(event);
        if (n !== 0)
            Brightness.step(0.05 * n);
    }
    WheelSteps { id: notches }
}
