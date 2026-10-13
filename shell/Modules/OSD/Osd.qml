import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services
import qs.Widgets

// Volume / brightness / keyboard backlight / mic popup.
Scope {
    id: root

    property string kind: ""
    property bool shown: false
    property bool armed: false

    readonly property real value: kind === "brightness" ? Brightness.value : kind === "kbd" ? Brightness.kbdValue : kind === "mic" ? Audio.micVolume : Audio.volume
    readonly property string icon: kind === "brightness" ? "brightness_6" : kind === "kbd" ? (Brightness.kbdLevel > 0 ? "backlight_high" : "backlight_high_off") : kind === "mic" ? (Audio.micMuted ? "mic_off" : "mic") : Audio.icon
    readonly property bool muted: kind === "volume" ? Audio.muted : kind === "mic" ? Audio.micMuted : false

    function show(k) {
        if (!armed || !Settings.data.osd.enabled)
            return;
        kind = k;
        shown = true;
        hideTimer.restart();
    }

    // Don't flash the OSD for the initial values on startup.
    Timer { running: true; interval: 1500; onTriggered: root.armed = true }
    Timer { id: hideTimer; interval: 1600; onTriggered: root.shown = false }

    Connections {
        target: Audio.sink?.audio ?? null
        function onVolumeChanged() { root.show("volume"); }
        function onMutedChanged() { root.show("volume"); }
    }
    Connections {
        target: Audio.source?.audio ?? null
        function onMutedChanged() { root.show("mic"); }
    }
    Connections {
        target: Brightness
        function onChangedByUser() { root.show("brightness"); }
        function onKbdChangedByUser() { root.show("kbd"); }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property ShellScreen modelData
            readonly property bool here: modelData.name === Panels.targetScreen("")
            readonly property real p: pAnim.v

            screen: modelData
            visible: p > 0.01
            color: "transparent"
            anchors.bottom: Settings.data.osd.position !== "top"
            anchors.top: Settings.data.osd.position === "top"
            implicitWidth: 340
            implicitHeight: 90
            exclusionMode: ExclusionMode.Normal
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "flamenco-osd"

        // animated value lives on an Item: Behaviors on the window itself crash Qt 6.12
        Item {
            id: pAnim
            property real v: root.shown && here ? 1 : 0
            Behavior on v { Anim { duration: Theme.durLong; easing.bezierCurve: Theme.curves.spring } }
        }
            mask: Region {}

            Rectangle {
                id: pill
                anchors.horizontalCenter: parent.horizontalCenter
                y: Settings.data.osd.position === "top" ? 12 : parent.height - height - 12
                width: 300
                height: 58
                radius: height / 2
                color: Theme.panelBg
                border.width: 1
                border.color: Theme.alpha(Theme.border, 0.6)
                opacity: win.p
                scale: 0.7 + 0.3 * win.p
                transform: Translate { y: (1 - win.p) * (Settings.data.osd.position === "top" ? -30 : 30) }

                layer.enabled: Settings.data.appearance.shadows
                layer.effect: MultiEffect { shadowEnabled: true; shadowColor: Theme.alpha(Theme.shadow, 0.4); shadowBlur: 0.8 }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    Rectangle {
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 34
                        radius: 17
                        color: root.muted ? Theme.surfaceHighest : Theme.accent
                        FIcon {
                            anchors.centerIn: parent
                            icon: root.icon
                            fill: 1
                            size: 20
                            color: root.muted ? Theme.textDim : Theme.onAccent
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 8
                        radius: 4
                        color: Theme.surfaceHighest
                        Rectangle {
                            height: parent.height
                            radius: 4
                            width: parent.width * Math.min(1, root.value)
                            color: root.muted ? Theme.textDim : Theme.accent
                            Behavior on width { Anim { easing.bezierCurve: Theme.curves.emphasizedDecel } }
                        }
                    }

                    FText {
                        Layout.preferredWidth: 38
                        horizontalAlignment: Text.AlignRight
                        text: Math.round(root.value * 100)
                        mono: true
                        font.weight: Font.Bold
                    }
                }
            }
        }
    }
}
