import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets
import qs.Modules.Volume

Page {
    id: page
    title: "Sound"
    subtitle: "Sound theme for the shell and your apps, event sounds, audio devices and each app's volume."
    readonly property var sd: Settings.data.sound

    Component.onCompleted: Sounds.load()

    Group {
        title: "Sound theme"
        SettingRow {
            title: "Theme"
            subtitle: Sounds.themes.length ? "Installed themes from /usr/share/sounds and ~/.local/share/sounds. Apps get it through GTK, GNOME and KDE settings." : "Only the bundled Flamenco theme was found. More: sound-theme-freedesktop, ocean-sound-theme."
            icon: "library_music"
            FDropdown {
                implicitWidth: 280
                options: Sounds.themes
                current: page.sd.theme
                placeholder: "Choose a theme…"
                onSelected: v => {
                    page.sd.theme = v;
                    Sounds.play("message-new-instant");
                }
            }
        }

        SettingRow {
            title: "Preview"
            icon: "play_circle"
            Flow {
                width: 360
                spacing: 6
                Repeater {
                    model: [
                        { e: "message-new-instant", l: "Notification" },
                        { e: "audio-volume-change", l: "Volume" },
                        { e: "brightness-change", l: "Brightness" },
                        { e: "dialog-warning", l: "Warning" },
                        { e: "complete", l: "Complete" },
                        { e: "bell", l: "Bell" },
                        { e: "screen-capture", l: "Screenshot" }
                    ]
                    FButton {
                        required property var modelData
                        text: modelData.l
                        icon: "volume_up"
                        variant: "tonal"
                        implicitHeight: 30
                        onClicked: Sounds.play(modelData.e)
                    }
                }
            }
        }
    }

    Group {
        title: "Event sounds"
        SwitchRow { title: "Notification sound"; subtitle: "When a notification pops up (silent in Do Not Disturb)"; icon: "notifications_active"; target: page.sd; key: "notifications" }
        SwitchRow { title: "Volume feedback"; subtitle: "A click after you change the volume"; icon: "volume_up"; target: page.sd; key: "volumeFeedback" }
        SwitchRow { title: "Brightness feedback"; subtitle: "A tick after you change the screen brightness"; icon: "brightness_6"; target: page.sd; key: "brightnessFeedback" }
        SwitchRow { title: "App event sounds"; subtitle: "Let GTK, GNOME and KDE apps play their event sounds"; icon: "apps"; target: page.sd; key: "eventSounds" }
    }

    Group {
        title: "Devices"
        SettingRow {
            title: "Output"
            icon: "speaker"
            FDropdown {
                implicitWidth: 300
                options: Audio.sinks.map(n => ({ value: n.name, label: Audio.nodeName(n) }))
                current: Audio.sink?.name ?? ""
                onSelected: v => {
                    const n = Audio.sinks.find(x => x.name === v);
                    if (n)
                        Audio.setDefaultSink(n);
                }
            }
        }
        SettingRow {
            title: "Output volume"
            icon: Audio.icon
            FSlider {
                width: 300
                value: Audio.muted ? 0 : Audio.volume
                showValue: true
                onMoved: v => Audio.setVolume(v)
            }
        }
        SettingRow {
            title: "Input"
            icon: "mic"
            FDropdown {
                implicitWidth: 300
                options: Audio.sources.map(n => ({ value: n.name, label: Audio.nodeName(n) }))
                current: Audio.source?.name ?? ""
                onSelected: v => {
                    const n = Audio.sources.find(x => x.name === v);
                    if (n)
                        Audio.setDefaultSource(n);
                }
            }
        }
        SettingRow {
            title: "Input volume"
            icon: Audio.micMuted ? "mic_off" : "mic"
            FSlider {
                width: 300
                value: Audio.micMuted ? 0 : Audio.micVolume
                showValue: true
                accent: Theme.accent2
                onMoved: v => Audio.setMicVolume(v)
            }
        }
    }

    VisualizerSection {}

    Group {
        title: "App volumes"
        SwitchRow { title: "Allow up to 150%"; subtitle: "For quiet apps; above 100% can distort"; icon: "volume_up"; target: page.sd; key: "mixerBoost" }
        SwitchRow { title: "Set each stream"; subtitle: "An app playing several things (browser tabs) opens up to set each one"; icon: "format_list_bulleted"; target: page.sd; key: "mixerStreams" }
        AppMixer {
            Layout.fillWidth: true
            Layout.margins: Theme.sp3
            roomy: true
        }
    }
}
