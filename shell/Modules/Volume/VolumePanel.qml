import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

// Opened from the bar's volume icon: output volume + device switcher,
// per-app volumes, and the microphone.
Variants {
    model: Quickshell.screens

    OverlayPanel {
        id: panel
        name: "volume"
        hAlign: "right"
        cardWidth: 380

        ColumnLayout {
            width: parent.width
            spacing: Theme.sp3

            // ── output ──
            RowLayout {
                Layout.fillWidth: true
                FText {
                    Layout.fillWidth: true
                    text: "Volume"
                    font.pixelSize: Theme.fsXl
                    font.weight: Font.Bold
                }
                FText {
                    text: Audio.muted ? "Muted" : Math.round(Audio.volume * 100) + "%"
                    mono: true
                    dim: true
                }
            }

            FSlider {
                Layout.fillWidth: true
                implicitHeight: 40
                icon: Audio.icon
                value: Audio.muted ? 0 : Audio.volume
                onMoved: v => Audio.setVolume(v)
                onIconClicked: Audio.toggleMute()
            }

            FText {
                text: "Output"
                dim: true
                font.pixelSize: Theme.fsSm
                font.weight: Font.Bold
                Layout.topMargin: Theme.sp2
            }

            Repeater {
                model: Audio.sinks
                Rectangle {
                    id: dev
                    required property var modelData
                    readonly property bool current: modelData === Audio.sink
                    Layout.fillWidth: true
                    implicitHeight: 46
                    radius: Theme.rMd
                    color: current ? Theme.alpha(Theme.accent, 0.16) : Theme.surfaceHigh
                    Behavior on color { CAnim {} }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10
                        FIcon {
                            icon: dev.modelData.name.includes("bluez") ? "headphones" : dev.modelData.name.includes("hdmi") ? "tv" : dev.modelData.name.includes("usb") ? "usb" : "speaker"
                            fill: dev.current ? 1 : 0
                            color: dev.current ? Theme.accent : Theme.text
                        }
                        FText {
                            Layout.fillWidth: true
                            text: Audio.nodeName(dev.modelData)
                            font.weight: dev.current ? Font.DemiBold : Font.Normal
                            elide: Text.ElideRight
                        }
                        FIcon {
                            visible: dev.current
                            icon: "check"
                            size: 18
                            color: Theme.accent
                        }
                    }
                    StateLayer {
                        onClicked: Audio.setDefaultSink(dev.modelData)
                    }
                }
            }

            // ── apps ──
            FText {
                visible: Audio.streams.length > 0
                text: "Apps"
                dim: true
                font.pixelSize: Theme.fsSm
                font.weight: Font.Bold
                Layout.topMargin: Theme.sp2
            }

            Repeater {
                model: Audio.streams
                RowLayout {
                    id: app
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 10
                    AppIcon {
                        implicitSize: 24
                        name: Audio.streamIcon(app.modelData) || Audio.streamName(app.modelData).toLowerCase()
                        fallback: "audio-x-generic"
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        FText {
                            Layout.fillWidth: true
                            text: Audio.streamName(app.modelData)
                            font.pixelSize: Theme.fsSm
                            elide: Text.ElideRight
                        }
                        FSlider {
                            Layout.fillWidth: true
                            implicitHeight: 24
                            value: app.modelData.audio?.muted ? 0 : (app.modelData.audio?.volume ?? 0)
                            accent: Theme.accent2
                            onMoved: v => {
                                if (!app.modelData.audio)
                                    return;
                                app.modelData.audio.muted = false;
                                app.modelData.audio.volume = v;
                            }
                        }
                    }
                    FIconButton {
                        icon: app.modelData.audio?.muted ? "volume_off" : "volume_up"
                        size: 30
                        iconSize: 16
                        onClicked: if (app.modelData.audio) app.modelData.audio.muted = !app.modelData.audio.muted
                    }
                }
            }

            // ── microphone ──
            FText {
                visible: Audio.source !== null
                text: "Microphone"
                dim: true
                font.pixelSize: Theme.fsSm
                font.weight: Font.Bold
                Layout.topMargin: Theme.sp2
            }
            FSlider {
                visible: Audio.source !== null
                Layout.fillWidth: true
                icon: Audio.micMuted ? "mic_off" : "mic"
                value: Audio.micMuted ? 0 : Audio.micVolume
                accent: Theme.accent3
                showValue: true
                onMoved: v => Audio.setMicVolume(v)
                onIconClicked: Audio.toggleMicMute()
            }
            FDropdown {
                visible: Audio.sources.length > 1
                Layout.fillWidth: true
                options: Audio.sources.map(n => ({ value: n.name, label: Audio.nodeName(n) }))
                current: Audio.source?.name ?? ""
                onSelected: v => {
                    const n = Audio.sources.find(x => x.name === v);
                    if (n)
                        Audio.setDefaultSource(n);
                }
            }

            FButton {
                Layout.alignment: Qt.AlignRight
                Layout.topMargin: Theme.sp2
                text: "Sound settings"
                icon: "tune"
                variant: "tonal"
                implicitHeight: 32
                onClicked: Panels.openSettings("sound")
            }
        }
    }
}
