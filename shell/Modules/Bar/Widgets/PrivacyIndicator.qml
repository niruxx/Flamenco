import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

// Privacy: a pill that appears while the camera, screen sharing or the
// microphone is in use (the mic only when its own bar widget isn't there).
// Click for who's using what, and to mute the mic.
BarChip {
    id: root

    required property var window             // the bar window, for the popup
    property string screenName
    property int barLevel: 0
    readonly property bool micHere: {
        const b = Settings.data.bar;
        return !(b.left || []).concat(b.center || [], b.right || []).includes("mic");
    }
    readonly property bool showMic: micHere && Privacy.mic
    property bool barVisible: Privacy.camera || Privacy.screen || showMic
    highlighted: pop.visible
    color: Theme.alpha(Privacy.screen ? Theme.error : Privacy.camera ? Theme.success : Theme.warning, pop.visible ? 0.3 : 0.18)

    onClicked: {
        if (pop.visible) {
            pop.visible = false;
            return;
        }
        const p = root.mapToItem(null, 0, 0);
        pop.at = Qt.rect(p.x, p.y, root.width, root.height);
        pop.visible = true;
    }

    BarFlow {
        spacing: 4
        FIcon { visible: root.showMic; icon: Audio.micMuted ? "mic_off" : "mic"; size: Theme.barIconSm; fill: 1; color: Theme.warning }
        FIcon { visible: Privacy.camera; icon: "videocam"; size: Theme.barIconSm; fill: 1; color: Theme.success }
        FIcon { visible: Privacy.screen; icon: "screen_share"; size: Theme.barIconSm; fill: 1; color: Theme.error }
    }

    PopupWindow {
        id: pop
        property rect at: Qt.rect(0, 0, 1, 1)
        readonly property int gap: 8
        anchor.window: root.window
        anchor.rect.x: Theme.barPos === "right" ? at.x - gap : Theme.barPos === "left" ? at.x + at.width + gap : at.x + at.width / 2
        anchor.rect.y: Theme.barPos === "bottom" ? at.y - gap : Theme.barVertical ? at.y : at.y + at.height + gap
        anchor.rect.width: 1
        anchor.rect.height: 1
        anchor.edges: Theme.barPos === "bottom" ? Edges.Top : Theme.barPos === "left" ? Edges.Right : Theme.barPos === "right" ? Edges.Left : Edges.Bottom
        anchor.gravity: anchor.edges
        grabFocus: true
        color: "transparent"
        visible: false
        implicitWidth: 320
        implicitHeight: list.implicitHeight + 24

        Rectangle {
            anchors.fill: parent
            radius: Theme.rLg
            color: Theme.popupBg
            border.width: 1
            border.color: Theme.alpha(Theme.border, 0.7)

            ColumnLayout {
                id: list
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                FText { text: I18n.tr("In use"); font.weight: Font.Bold }
                Use {
                    visible: Privacy.mic || Audio.micMuted
                    icon: Audio.micMuted ? "mic_off" : "mic"
                    tint: Theme.warning
                    what: Audio.micMuted ? "Microphone (muted)" : "Microphone"
                    who: Privacy.mic ? Privacy.micUsers : "Nothing is recording"
                    action: Audio.micMuted ? "Unmute" : "Mute"
                    onAct: Audio.toggleMicMute()
                }
                Use {
                    visible: Privacy.camera
                    icon: "videocam"
                    tint: Theme.success
                    what: "Camera"
                    who: Privacy.cameraUsers || "an app"
                }
                Use {
                    visible: Privacy.screen
                    icon: "screen_share"
                    tint: Theme.error
                    what: "Screen sharing"
                    who: (Privacy.screenUsers || "an app") + ". Stop it in that app."
                }
            }
        }
    }

    component Use: RowLayout {
        id: u
        property string icon
        property color tint
        property string what
        property string who
        property string action: ""
        signal act
        Layout.fillWidth: true
        spacing: 10
        Rectangle {
            implicitWidth: 32
            implicitHeight: 32
            radius: 16
            color: Theme.alpha(u.tint, 0.2)
            FIcon { anchors.centerIn: parent; icon: u.icon; size: 18; fill: 1; color: u.tint }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            FText { Layout.fillWidth: true; text: u.what; font.weight: Font.Medium }
            FText { Layout.fillWidth: true; text: u.who; dim: true; font.pixelSize: Theme.fsSm; wrapMode: Text.Wrap }
        }
        FButton {
            visible: u.action !== ""
            text: u.action
            variant: "tonal"
            onClicked: u.act()
        }
    }
}
