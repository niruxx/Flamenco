import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

FCard {
    id: root
    signal openDetail(string name)
    readonly property bool cards: (Settings.data.control.style || "cards") === "cards"

    implicitHeight: col.implicitHeight + Theme.sp4 * 2

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: Theme.sp4
        spacing: Theme.sp3

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.gap
            FPillSlider {
                visible: root.cards
                Layout.fillWidth: true
                icon: Audio.icon
                value: Audio.volume
                muted: Audio.muted
                from: Theme.accent3
                to: Theme.accent2
                onMoved: v => Audio.setVolume(v)
                onIconClicked: Audio.toggleMute()
            }
            FSlider {
                visible: !root.cards
                Layout.fillWidth: true
                showValue: true
                icon: Audio.icon
                value: Audio.muted ? 0 : Audio.volume
                onMoved: v => Audio.setVolume(v)
                onIconClicked: Audio.toggleMute()
            }
            FIconButton {
                icon: "chevron_right"
                size: 30
                onClicked: root.openDetail("audio")
            }
        }

        // the app mixer: who's playing, a tap away
        Rectangle {
            Layout.fillWidth: true
            visible: Audio.streamGroups.length > 0
            implicitHeight: 40
            radius: root.cards ? 20 : Theme.rMd
            color: Theme.alpha(Theme.text, 0.05)
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 8
                spacing: 8
                // the first few apps' icons, overlapping
                Row {
                    spacing: -6
                    Repeater {
                        model: Audio.streamGroups.slice(0, 4)
                        Rectangle {
                            required property var modelData
                            width: 24
                            height: 24
                            radius: 12
                            color: Theme.surfaceHigh
                            border.width: 2
                            border.color: Theme.surface
                            AppIcon {
                                anchors.centerIn: parent
                                implicitSize: 16
                                name: modelData.icon
                                fallback: "audio-x-generic"
                            }
                        }
                    }
                }
                FText {
                    Layout.fillWidth: true
                    text: Audio.streamGroups.length === 1 ? Audio.streamGroups[0].name + " is playing" : Audio.streamGroups.length + " apps playing"
                    font.pixelSize: Theme.fsSm
                    elide: Text.ElideRight
                }
                FText { text: "Mixer"; color: Theme.accent; font.pixelSize: Theme.fsSm; font.weight: Font.DemiBold }
                FIcon { icon: "chevron_right"; size: 18; color: Theme.accent }
            }
            StateLayer { onClicked: root.openDetail("mixer") }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: Audio.source !== null
            spacing: Theme.gap
            FPillSlider {
                visible: root.cards
                Layout.fillWidth: true
                icon: Audio.micMuted ? "mic_off" : "mic"
                value: Audio.micVolume
                muted: Audio.micMuted
                from: Theme.warning
                to: Theme.accent
                onMoved: v => Audio.setMicVolume(v)
                onIconClicked: Audio.toggleMicMute()
            }
            FSlider {
                visible: !root.cards
                Layout.fillWidth: true
                showValue: true
                icon: Audio.micMuted ? "mic_off" : "mic"
                value: Audio.micMuted ? 0 : Audio.micVolume
                accent: Theme.accent2
                onMoved: v => Audio.setMicVolume(v)
                onIconClicked: Audio.toggleMicMute()
            }
            FIconButton {
                icon: "chevron_right"
                size: 30
                onClicked: root.openDetail("mic")
            }
        }

        FPillSlider {
            Layout.fillWidth: true
            visible: Brightness.available && root.cards
            icon: "brightness_6"
            value: Brightness.value
            from: Theme.accent
            to: Theme.warning
            onMoved: v => Brightness.set(v)
        }
        FSlider {
            Layout.fillWidth: true
            visible: Brightness.available && !root.cards
            showValue: true
            icon: "brightness_6"
            value: Brightness.value
            accent: Theme.accent3
            onMoved: v => Brightness.set(v)
        }

        // external monitors (DDC/CI)
        Repeater {
            model: Brightness.ddc
            FSlider {
                required property var modelData
                Layout.fillWidth: true
                showValue: true
                icon: "desktop_windows"
                value: modelData.value / modelData.max
                accent: Theme.accent3
                onMoved: v => Brightness.setDdc(modelData.bus, v)
            }
        }

        FSlider {
            Layout.fillWidth: true
            visible: Brightness.kbdAvailable
            showValue: true
            icon: Brightness.kbdLevel > 0 ? "backlight_high" : "backlight_high_off"
            value: Brightness.kbdValue
            stepSize: Brightness.kbdMax > 0 && Brightness.kbdMax <= 10 ? 1 / Brightness.kbdMax : 0
            accent: Theme.accent3
            onMoved: v => Brightness.setKbd(v)
            onIconClicked: Brightness.toggleKbd()
        }
    }
}
