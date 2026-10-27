import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets
import qs.Modules.Volume

Page {
    id: page
    title: I18n.tr("Sound")
    subtitle: I18n.tr("Sound theme for the shell and your apps, event sounds, audio devices and each app's volume.")
    readonly property var sd: Settings.data.sound

    Component.onCompleted: Sounds.load()

    Group {
        title: I18n.tr("Sound theme")
        SettingRow {
            title: I18n.tr("Theme")
            subtitle: Sounds.themes.length ? I18n.tr("Installed themes from /usr/share/sounds and ~/.local/share/sounds. Apps get it through GTK, GNOME and KDE settings.") : I18n.tr("Only the bundled Flamenco theme was found. More: sound-theme-freedesktop, ocean-sound-theme.")
            icon: "library_music"
            FDropdown {
                implicitWidth: 280
                options: Sounds.themes
                current: page.sd.theme
                placeholder: I18n.tr("Choose a theme…")
                onSelected: v => {
                    page.sd.theme = v;
                    Sounds.play("message-new-instant");
                }
            }
        }

        SettingRow {
            title: I18n.tr("Preview")
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
        title: I18n.tr("Event sounds")
        SwitchRow { title: I18n.tr("Notification sound"); subtitle: I18n.tr("When a notification pops up (silent in Do Not Disturb)"); icon: "notifications_active"; target: page.sd; key: "notifications" }
        SwitchRow { title: I18n.tr("Volume feedback"); subtitle: I18n.tr("A click after you change the volume"); icon: "volume_up"; target: page.sd; key: "volumeFeedback" }
        SwitchRow { title: I18n.tr("Brightness feedback"); subtitle: I18n.tr("A tick after you change the screen brightness"); icon: "brightness_6"; target: page.sd; key: "brightnessFeedback" }
        SwitchRow { title: I18n.tr("App event sounds"); subtitle: I18n.tr("Let GTK, GNOME and KDE apps play their event sounds"); icon: "apps"; target: page.sd; key: "eventSounds" }
    }

    Group {
        title: I18n.tr("Devices")
        SettingRow {
            title: I18n.tr("Output")
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
            title: I18n.tr("Output volume")
            icon: Audio.icon
            FSlider {
                width: 300
                value: Audio.muted ? 0 : Audio.volume
                showValue: true
                onMoved: v => Audio.setVolume(v)
            }
        }
        SettingRow {
            title: I18n.tr("Input")
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
            title: I18n.tr("Input volume")
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
        title: I18n.tr("App volumes")
        SwitchRow { title: I18n.tr("Allow up to 150%"); subtitle: I18n.tr("For quiet apps; above 100% can distort"); icon: "volume_up"; target: page.sd; key: "mixerBoost" }
        SwitchRow { title: I18n.tr("Set each stream"); subtitle: I18n.tr("An app playing several things (browser tabs) opens up to set each one"); icon: "format_list_bulleted"; target: page.sd; key: "mixerStreams" }
        AppMixer {
            Layout.fillWidth: true
            Layout.margins: Theme.sp3
            roomy: true
        }
    }

    Group {
        title: I18n.tr("Media players")
        DropdownRow {
            title: I18n.tr("Preferred player")
            subtitle: Settings.data.media.preferred ? I18n.tr("The media controls follow it whenever it has something, unless another player is playing") : I18n.tr("None: the one playing, else the last with a track")
            icon: "star"
            target: Settings.data.media
            key: "preferred"
            options: [{ value: "", label: I18n.tr("None") }].concat((Settings.data.media.seen || []).map(n => ({ value: n, label: n + (Media.names.includes(n) ? "" : " (closed)") })))
        }
        SettingRow {
            visible: (Settings.data.media.seen || []).length === 0
            title: I18n.tr("No players yet")
            subtitle: I18n.tr("Players show up here once they've been open (Spotify, mpv, a browser playing a video…)")
            icon: "info"
        }
        Repeater {
            model: Settings.data.media.seen || []
            SettingRow {
                id: prow
                required property string modelData
                readonly property bool ignored: (Settings.data.media.ignored || []).some(n => n.toLowerCase() === modelData.toLowerCase())
                title: modelData
                subtitle: ignored ? I18n.tr("Ignored: never shown in the bar, panels or lock screen") : Media.names.includes(modelData) ? I18n.tr("Open now") : I18n.tr("Closed")
                icon: "music_note"
                Row {
                    spacing: 6
                    FButton {
                        text: prow.ignored ? I18n.tr("Show it") : I18n.tr("Ignore")
                        variant: prow.ignored ? "filled" : "tonal"
                        onClicked: {
                            const all = Settings.data.media.ignored || [];
                            Settings.data.media.ignored = prow.ignored ? all.filter(n => n.toLowerCase() !== prow.modelData.toLowerCase()) : all.concat([prow.modelData]);
                        }
                    }
                    FIconButton {
                        icon: "close"
                        size: 30
                        onClicked: Settings.data.media.seen = (Settings.data.media.seen || []).filter(n => n !== prow.modelData)
                    }
                }
            }
        }
    }
}
