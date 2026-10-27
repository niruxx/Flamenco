import QtQuick
import qs.Commons
import qs.Services
import qs.Widgets

// The microphone. When it shows (Settings → Bar → Microphone): while an app is
// recording, also while it's muted, or always. How it looks: the mic icon, a dot
// (a privacy dot, like a phone's), a pill with the app's name, a ring around the
// icon, or a short text. Click mutes or unmutes it, right-click opens the
// microphone page in quick settings, scroll changes its volume.
Item {
    id: root

    property string screenName
    property int barLevel: 0
    readonly property string when: Settings.data.bar.micIndicator || "inuse"
    readonly property string look: Settings.data.bar.micStyle || "icon"
    readonly property bool live: Audio.micInUse && !Audio.micMuted
    property bool barVisible: Audio.source !== null && (when === "always" || Audio.micInUse || when === "inuse-muted" && Audio.micMuted)
    // what it's in: muted (error), recording (accent), idle (text)
    readonly property color tone: Audio.micMuted ? Theme.error : live ? Theme.accent : Theme.textDim

    implicitWidth: look === "icon" || look === "ring" ? btn.width : look === "dot" ? Math.round(Theme.barItem * 0.6) : chip.width
    implicitHeight: Theme.barItem

    function clicked(button) {
        if (button === Qt.RightButton)
            Panels.openControl("mic", root.screenName, root);
        else
            Audio.toggleMicMute();
    }
    WheelSteps { id: notches }
    function wheeled(event) {
        const n = notches.take(event);
        if (n !== 0)
            Audio.setMicVolume(Audio.micVolume + 0.05 * n);
    }

    // ── icon, ring ──
    FIconButton {
        id: btn
        visible: root.look === "icon" || root.look === "ring"
        anchors.centerIn: parent
        size: Theme.barItem
        iconSize: Theme.barIcon
        icon: Audio.micMuted ? "mic_off" : "mic"
        // icon: in use, highlighted; muted, in the error color so it stands out
        active: root.live && root.look === "icon"
        activeColor: Theme.accent
        iconColor: Audio.micMuted ? Theme.error : active ? Theme.onAccent : root.look === "ring" && root.live ? Theme.accent : Theme.text
        onClicked: Audio.toggleMicMute()
        onMiddleClicked: Audio.toggleMicMute()
        onRightClicked: root.clicked(Qt.RightButton)
        onWheel: event => root.wheeled(event)
    }
    // icon: a small pulsing dot in the corner while something is listening
    Rectangle {
        visible: root.look === "icon" && root.live
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
            running: root.look === "icon" && root.live
            loops: Animation.Infinite
            NumberAnimation { to: 0.35; duration: 700; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutSine }
        }
    }
    // ring: a circle around the icon, breathing outward while recording
    Rectangle {
        visible: root.look === "ring"
        anchors.centerIn: btn
        width: Math.round(Theme.barItem * 0.86)
        height: width
        radius: width / 2
        color: "transparent"
        border.width: 2
        border.color: root.tone
        Rectangle {
            visible: root.live
            anchors.centerIn: parent
            width: parent.width
            height: width
            radius: width / 2
            color: "transparent"
            border.width: 2
            border.color: Theme.accent
            SequentialAnimation on scale {
                running: root.look === "ring" && root.live
                loops: Animation.Infinite
                NumberAnimation { from: 1; to: 1.35; duration: 1100; easing.type: Easing.OutCubic }
            }
            SequentialAnimation on opacity {
                running: root.look === "ring" && root.live
                loops: Animation.Infinite
                NumberAnimation { from: 0.8; to: 0; duration: 1100; easing.type: Easing.OutCubic }
            }
        }
    }

    // ── dot: just a colored dot (hollow while muted) ──
    Rectangle {
        id: dot
        visible: root.look === "dot"
        anchors.centerIn: parent
        width: Math.max(8, Math.round(Theme.barItem * 0.32))
        height: width
        radius: width / 2
        color: Audio.micMuted ? "transparent" : root.live ? Theme.warning : Theme.textDim
        border.width: Audio.micMuted ? 2 : 0
        border.color: Theme.error
        SequentialAnimation on opacity {
            running: root.look === "dot" && root.live
            loops: Animation.Infinite
            onRunningChanged: if (!running) dot.opacity = 1
            NumberAnimation { to: 0.45; duration: 800; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1; duration: 800; easing.type: Easing.InOutSine }
        }
    }

    // ── pill (icon + who's listening) and text ──
    Rectangle {
        id: chip
        visible: root.look === "pill" || root.look === "text"
        anchors.centerIn: parent
        height: Math.round(Theme.barItem * 0.78)
        width: Math.min(180, row.implicitWidth + height * 0.7)
        radius: height / 2
        color: root.look === "pill" ? Theme.alpha(root.tone, root.live || Audio.micMuted ? 0.2 : 0.1) : "transparent"
        border.width: root.look === "text" ? 1 : 0
        border.color: root.tone
        Row {
            id: row
            anchors.centerIn: parent
            spacing: 4
            FIcon {
                visible: root.look === "pill"
                anchors.verticalCenter: parent.verticalCenter
                icon: Audio.micMuted ? "mic_off" : "mic"
                size: Theme.barIconSm
                fill: 1
                color: root.tone
            }
            FText {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, 130)
                text: root.look === "text" ? (Audio.micMuted ? I18n.tr("MUTED") : I18n.tr("MIC"))
                    : Audio.micMuted ? "Muted" : root.live ? (Audio.micUsers || "Recording") : "Mic"
                color: root.tone
                font.pixelSize: root.look === "text" ? Theme.fsXs : Theme.fsSm
                font.weight: Font.DemiBold
                font.letterSpacing: root.look === "text" ? 1 : 0
                elide: Text.ElideRight
            }
        }
    }

    // the dot, pill and text take clicks and the wheel here (the icon has its own)
    MouseArea {
        visible: root.look === "dot" || root.look === "pill" || root.look === "text"
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => root.clicked(mouse.button)
        onWheel: wheel => root.wheeled(wheel)
    }
}
