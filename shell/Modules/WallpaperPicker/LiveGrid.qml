import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.Commons
import qs.Services
import qs.Widgets

// Live (video) wallpapers from online: Wikimedia Commons (no key), Pexels and
// Pixabay (free API keys, kept by `flamenco live key`), or any link to a video
// or GIF. A click downloads it into <wallpaper folder>/live and puts it on.
ColumnLayout {
    id: root

    property string screenName: ""
    property string query: ""
    property var results: []
    property int page: 1
    property bool more: false
    property bool loading: false
    property string error: ""
    property bool needKey: false
    property string busy: ""                // the video being downloaded
    property string dlError: ""
    readonly property string source: Settings.data.wallpaper.liveSource || "wikimedia"
    readonly property var sources: [{ value: "wikimedia", label: "Wikimedia", icon: "public" }, { value: "pexels", label: "Pexels", icon: "movie" }, { value: "pixabay", label: "Pixabay", icon: "video_library" }]

    function search(next) {
        if (finder.running)
            return;
        page = next ? page + 1 : 1;
        if (!next)
            results = [];
        loading = true;
        error = "";
        needKey = false;
        finder.command = [Paths.bin, "live", "search", source, query.trim(), String(page)];
        finder.running = true;
    }
    function download(url) {
        if (!url || dl.running)
            return;
        busy = url;
        dlError = "";
        dl.command = [Paths.bin, "live", "get", url];
        dl.running = true;
    }
    function fmtTime(s) {
        return s >= 60 ? Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0") : "0:" + String(s).padStart(2, "0");
    }

    onSourceChanged: search(false)
    Component.onCompleted: search(false)
    spacing: Theme.sp3

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.sp2
        FSegmented {
            implicitWidth: 380
            implicitHeight: 38
            options: root.sources
            current: root.source
            onSelected: v => Settings.data.wallpaper.liveSource = v
        }
        FTextField {
            Layout.fillWidth: true
            implicitHeight: 38
            icon: "search"
            placeholder: "Search live wallpapers (ocean, rain, city at night…)"
            onAccepted: {
                root.query = text;
                root.search(false);
            }
        }
    }

    GridView {
        id: grid
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredHeight: 400
        readonly property int cols: Math.max(2, Math.floor(width / 220))
        cellWidth: width / cols
        cellHeight: cellWidth * 0.62
        clip: true
        model: root.results
        boundsBehavior: Flickable.OvershootBounds
        SmoothWheel { view: grid }
        // the next page when the end comes into view
        onAtYEndChanged: if (atYEnd && !root.loading && root.more && count > 0) root.search(true)

        ColumnLayout {
            anchors.centerIn: parent
            width: Math.min(parent.width - 40, 460)
            visible: grid.count === 0
            spacing: Theme.sp2
            FIcon {
                Layout.alignment: Qt.AlignHCenter
                icon: root.needKey ? "key" : root.loading ? "travel_explore" : "videocam_off"
                size: 40
                color: root.error && !root.needKey ? Theme.error : Theme.textDim
            }
            FText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: root.loading ? "Searching…" : root.error || "Nothing found"
                color: root.error && !root.needKey ? Theme.error : Theme.textDim
            }
            FButton {
                Layout.alignment: Qt.AlignHCenter
                visible: root.needKey
                text: "Add a key"
                icon: "key"
                onClicked: Panels.findSetting("wallpaper", "Live wallpapers")
            }
        }

        delegate: Item {
            id: cell
            required property var modelData
            width: grid.cellWidth
            height: grid.cellHeight
            ClippingRectangle {
                anchors.fill: parent
                anchors.margins: 6
                radius: Theme.rMd
                color: Theme.surfaceHigh
                scale: hov.hovered ? 1.03 : 1
                Behavior on scale { Anim { duration: Theme.durShort } }
                Image {
                    anchors.fill: parent
                    source: cell.modelData.thumb ?? ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize: Qt.size(420, 260)
                }
                // a play symbol over it, so it reads as a video
                Rectangle {
                    anchors.centerIn: parent
                    width: 38
                    height: 38
                    radius: 19
                    color: Theme.alpha(Theme.shadow, hov.hovered ? 0.65 : 0.4)
                    FIcon { anchors.centerIn: parent; icon: "play_arrow"; size: 24; fill: 1; color: "#ffffff" }
                }
                FText {
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    anchors.margins: 6
                    width: parent.width - 80
                    text: cell.modelData.title || cell.modelData.author || ""
                    elide: Text.ElideRight
                    color: "white"
                    font.pixelSize: Theme.fsXs
                    style: Text.Outline
                    styleColor: "#80000000"
                }
                FText {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 6
                    text: (cell.modelData.h ? cell.modelData.h + "p" : "") + (cell.modelData.duration ? " · " + root.fmtTime(cell.modelData.duration) : "")
                    color: "white"
                    font.pixelSize: Theme.fsXs
                    font.weight: Font.Bold
                    style: Text.Outline
                    styleColor: "#80000000"
                }
                Rectangle {
                    anchors.fill: parent
                    color: Theme.alpha(Theme.bg, 0.6)
                    visible: root.busy === cell.modelData.url
                    Column {
                        anchors.centerIn: parent
                        spacing: 4
                        FIcon { anchors.horizontalCenter: parent.horizontalCenter; icon: "downloading"; size: 26; color: Theme.accent }
                        FText { anchors.horizontalCenter: parent.horizontalCenter; text: "Downloading…"; color: Theme.text }
                    }
                }
                HoverHandler { id: hov }
                StateLayer {
                    disabled: root.busy !== ""
                    onClicked: root.download(cell.modelData.url)
                }
            }
        }
    }

    FText {
        Layout.fillWidth: true
        visible: root.dlError !== ""
        text: "Couldn't download it: " + root.dlError
        color: Theme.error
        wrapMode: Text.Wrap
        font.pixelSize: Theme.fsSm
    }

    // any link to a video or a GIF
    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.sp2
        FTextField {
            id: link
            Layout.fillWidth: true
            implicitHeight: 38
            icon: "link"
            placeholder: "Or paste a link to a video or GIF (https://…/clip.mp4)"
            onAccepted: root.download(text.trim())
        }
        FButton {
            text: root.busy !== "" && root.busy === link.text.trim() ? "Downloading…" : "Download"
            icon: "download"
            disabled: link.text.trim() === "" || root.busy !== ""
            onClicked: root.download(link.text.trim())
        }
    }

    FText {
        Layout.fillWidth: true
        text: (root.source === "wikimedia" ? "Free videos from Wikimedia Commons (check each one's license on its page)" : root.source === "pexels" ? "Videos from Pexels (free to use)" : "Videos from Pixabay (free to use)")
            + " · saved to " + Wallpapers.dir + "/live" + (Wallpapers.canPoster ? "" : " · install ffmpeg for thumbnails")
        dim: true
        wrapMode: Text.Wrap
        font.pixelSize: Theme.fsXs
    }

    Process {
        id: finder
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    root.results = root.results.concat(d.results ?? []);
                    root.more = !!d.more;
                    root.error = d.error ?? "";
                    root.needKey = !!d.needKey;
                } catch (e) {
                    root.error = "Couldn't search (is `flamenco` up to date?)";
                }
            }
        }
        onExited: root.loading = false
    }

    Process {
        id: dl
        stdout: StdioCollector {
            onStreamFinished: {
                const path = text.trim();
                if (path) {
                    Wallpapers.set(path, root.screenName);
                    Wallpapers.rescan();
                    link.text = "";
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) root.dlError = text.trim().split("\n").pop().replace(/^flamenco: /, "")
        }
        onExited: root.busy = ""
    }
}
