import QtQuick
import qs.Commons
import qs.Services
import qs.Widgets

// The microphone: appears while an app is recording (and while it's muted, so
// a muted mic doesn't go unnoticed). Click mutes or unmutes it, right-click
// opens the microphone page in quick settings, scroll changes its volume.
Item {
    id: root

    property string screenName
    property int barLevel: 0
    readonly property bool always: Settings.data.bar.micIndicator === "always"
    readonly property bool live: Audio.micInUse && !Audio.micMuted
    property bool barVisible: Audio.source !== null && (always || Audio.micInUse || Audio.micMuted)

    implicitWidth: btn.width
    implicitHeight: btn.height

    FIconButton {
        id: btn
        size: Theme.barItem
        iconSize: 18
        icon: Audio.micMuted ? "mic_off" : "mic"
        // in use: highlighted; muted: the error color, so it stands out
        active: root.live
        activeColor: Theme.accent
        iconColor: Audio.micMuted ? Theme.error : active ? Theme.onAccent : Theme.text
        onClicked: Audio.toggleMicMute()
        onMiddleClicked: Audio.toggleMicMute()
        onRightClicked: Panels.openControl("mic", root.screenName, root)
        onWheel: event => {
            const n = notches.take(event);
            if (n !== 0)
                Audio.setMicVolume(Audio.micVolume + 0.05 * n);
        }
        WheelSteps { id: notches }
    }

    // a small pulsing dot while something is listening
    Rectangle {
        visible: root.live
        width: 7
        height: 7
        radius: 3.5
        color: Theme.error
        border.width: 1
        border.color: Theme.barBg
        anchors.top: btn.top
        anchors.right: btn.right
        anchors.margins: 3
        SequentialAnimation on opacity {
            running: root.live
            loops: Animation.Infinite
            NumberAnimation { to: 0.35; duration: 700; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutSine }
        }
    }
}
