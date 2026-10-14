import QtQuick
import qs.Commons
import qs.Services
import qs.Widgets

// While the screen is being recorded: a pulsing red dot and the time. Click stops it.
BarChip {
    id: root
    property string screenName
    property int barLevel: 0
    property bool barVisible: Recorder.recording
    color: Theme.alpha(Theme.error, 0.18)
    onClicked: Recorder.stop()

    BarFlow {
        spacing: 6
        Rectangle {
            width: 9
            height: 9
            radius: 4.5
            color: Theme.error
            SequentialAnimation on opacity {
                running: Recorder.recording
                loops: Animation.Infinite
                NumberAnimation { to: 0.3; duration: 600; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1; duration: 600; easing.type: Easing.InOutSine }
            }
        }
        FText {
            visible: !Theme.barVertical && root.barLevel < 2
            text: Recorder.clock
            mono: true
            font.pixelSize: Theme.fsSm
            color: Theme.error
        }
        FIcon { icon: "stop"; size: 16; fill: 1; color: Theme.error }
    }
}
