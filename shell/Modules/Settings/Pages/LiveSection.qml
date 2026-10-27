import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services
import qs.Widgets

// Settings → Wallpaper → Live wallpapers: videos and GIFs that play on the
// desktop, when they pause, and the keys for finding more online (Pexels,
// Pixabay; Wikimedia Commons needs none). Keys go to `flamenco live key`, which
// keeps them in the keyring (or a file only you can read); the shell never holds them.
Group {
    id: root
    title: I18n.tr("Live wallpapers")
    readonly property var w: Settings.data.wallpaper
    property var keys: ({})                  // source → has a key

    function refreshKeys() {
        keysProc.running = true;
    }
    Component.onCompleted: refreshKeys()

    SwitchRow {
        title: I18n.tr("Play live wallpapers")
        subtitle: !Wallpapers.canPlay ? I18n.tr("Qt Multimedia isn't installed, so they show a still (Settings → System check)")
            : Wallpapers.liveCount > 0 ? Wallpapers.liveCount + " in your folder (videos: mp4, webm, mkv, mov; and GIFs). Off: they show a still"
            : "Put videos (mp4, webm, mkv, mov) or GIFs in your folder, or find some online below"
        icon: "animated_images"
        target: root.w
        key: "live"
    }
    SettingRow {
        visible: !Wallpapers.canPoster
        title: "ffmpeg isn't installed"
        subtitle: I18n.tr("It makes the stills of videos: their thumbnails, the transitions, colors from wallpaper and the lock screen")
        icon: "warning"
        FButton {
            text: I18n.tr("System check")
            variant: "text"
            onClicked: Panels.openSettings("system")
        }
    }
    SwitchRow { visible: root.w.live; title: I18n.tr("Pause in power saver"); subtitle: Power.profileId === "power-saver" ? I18n.tr("Paused now: the power profile is Power saver. They play on battery otherwise") : I18n.tr("While the power profile is Power saver; they play on battery otherwise. The picture stays, it just stops moving"); icon: "battery_saver"; target: root.w; key: "livePauseSaver" }
    SwitchRow { visible: root.w.live; title: I18n.tr("Pause behind windows"); subtitle: I18n.tr("While a tiled window is on the screen's workspace"); icon: "select_window"; target: root.w; key: "livePauseWindows" }
    SliderRow { visible: root.w.live; title: I18n.tr("Speed"); icon: "speed"; target: root.w; key: "liveSpeed"; from: 0.25; to: 2; stepSize: 0.05; decimals: 2; suffix: "×" }
    SwitchRow { visible: root.w.live; title: I18n.tr("Sound"); subtitle: I18n.tr("Videos are silent unless this is on"); icon: "volume_up"; target: root.w; key: "liveSound" }

    SettingRow {
        title: I18n.tr("Find live wallpapers online")
        subtitle: I18n.tr("In the wallpaper switcher's Live tab: Wikimedia Commons (no key), Pexels or Pixabay, or paste a link. Saved to ") + Wallpapers.dir + "/live"
        icon: "travel_explore"
        FButton {
            text: I18n.tr("Open the switcher")
            icon: "view_carousel"
            onClicked: Panels.open("wallpaper", "")
        }
    }

    Repeater {
        model: [
            { id: "pexels", name: "Pexels", url: "https://www.pexels.com/api/new/" },
            { id: "pixabay", name: "Pixabay", url: "https://pixabay.com/api/docs/#api_search_videos" }
        ]
        SettingRow {
            id: krow
            required property var modelData
            readonly property bool has: !!root.keys[modelData.id]
            title: modelData.name + " API key"
            subtitle: has ? I18n.tr("Saved (in your keyring, or a file only you can read)") : I18n.tr("Free: sign up, then paste your key here")
            icon: "key"
            Row {
                spacing: 8
                FTextField {
                    id: field
                    implicitWidth: 200
                    password: true
                    placeholder: krow.has ? I18n.tr("Replace the key") : I18n.tr("Paste the key")
                }
                FButton {
                    text: I18n.tr("Save")
                    disabled: field.text.trim() === ""
                    onClicked: {
                        saver.createObject(root, { src: krow.modelData.id, key: field.text.trim(), remove: false }).running = true;
                        field.text = "";
                    }
                }
                FButton {
                    visible: krow.has
                    text: I18n.tr("Remove")
                    variant: "text"
                    onClicked: saver.createObject(root, { src: krow.modelData.id, key: "", remove: true }).running = true
                }
                FButton {
                    visible: !krow.has
                    text: I18n.tr("Get a key")
                    variant: "text"
                    onClicked: Qt.openUrlExternally(krow.modelData.url)
                }
            }
        }
    }

    Process {
        id: keysProc
        command: [Paths.bin, "live", "keys"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.keys = JSON.parse(text);
                } catch (e) {
                    root.keys = {};
                }
            }
        }
    }
    Component {
        id: saver
        Process {
            id: sp
            property string src
            property string key
            property bool remove
            command: remove ? [Paths.bin, "live", "key", src, "--clear"] : [Paths.bin, "live", "key", src]
            stdinEnabled: !remove
            onStarted: if (!remove) write(key + "\n")
            onExited: {
                root.refreshKeys();
                sp.destroy();
            }
        }
    }
}
