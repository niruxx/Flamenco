import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

FCard {
    id: root
    signal openDetail(string name)

    implicitHeight: col.implicitHeight + Theme.sp4 * 2

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: Theme.sp4
        spacing: Theme.sp3

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.gap
            FSlider {
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

        RowLayout {
            Layout.fillWidth: true
            visible: Audio.source !== null
            spacing: Theme.gap
            FSlider {
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

        FSlider {
            Layout.fillWidth: true
            visible: Brightness.available
            showValue: true
            icon: "brightness_6"
            value: Brightness.value
            accent: Theme.accent3
            onMoved: v => Brightness.set(v)
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
