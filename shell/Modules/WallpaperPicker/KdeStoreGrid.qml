import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.Commons
import qs.Services
import qs.Widgets

// The KDE Store's wallpapers (store.kde.org → Wallpapers KDE Plasma), through
// `flamenco get`. A click downloads the biggest picture (one without a logo when
// there's a choice) into <wallpaper folder>/kde-store and sets it; ones already
// there are just set. Settings → Get themes lists them too, with Remove.
ColumnLayout {
    id: root

    property string screenName: ""
    property string query: ""
    property string sorting: "rating"       // rating | downloads | new
    property var results: []
    property var got: ({})                  // id → its picture, downloaded since the search
    property int page: 1
    property bool more: false
    property bool loading: false
    property string error: ""
    property string busy: ""                // the id being downloaded
    property int seq: 0

    function search(again) {
        page = again ? page + 1 : 1;
        loading = true;
        error = "";
        seq++;
        searcher.createObject(root, { tag: seq, append: !!again, command: [Paths.bin, "get", "search", "wallpapers", query.trim(), String(page), sorting] }).running = true;
    }
    function pathOf(r) {
        return got[r.id] || (r.paths || [])[0] || "";
    }
    function pick(r) {
        const have = pathOf(r);
        if (have) {
            Wallpapers.set(have, screenName);
            return;
        }
        busy = r.id;
        dl.item = r;
        dl.command = [Paths.bin, "get", "install", "wallpapers", r.id];
        dl.running = true;
    }

    Component.onCompleted: search(false)
    spacing: Theme.sp3

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.sp2
        FTextField {
            Layout.fillWidth: true
            implicitHeight: 38
            icon: "search"
            placeholder: "Search the KDE Store (abstract, space, nature…)"
            onAccepted: {
                root.query = text;
                root.search(false);
            }
        }
        FSegmented {
            implicitWidth: 300
            implicitHeight: 38
            options: [{ value: "rating", label: "Top rated" }, { value: "downloads", label: "Popular" }, { value: "new", label: "Newest" }]
            current: root.sorting
            onSelected: v => {
                root.sorting = v;
                root.search(false);
            }
        }
    }

    GridView {
        id: grid
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredHeight: 420
        readonly property int cols: Math.max(2, Math.floor(width / 220))
        cellWidth: width / cols
        cellHeight: cellWidth * 0.62
        clip: true
        // diffed: the next page is added below instead of replacing the list
        model: ScriptModel { values: root.results }
        boundsBehavior: Flickable.OvershootBounds
        SmoothWheel { view: grid }
        onAtYEndChanged: if (atYEnd && !root.loading && root.more && count > 0) root.search(true)

        FText {
            anchors.centerIn: parent
            visible: grid.count === 0
            text: root.loading ? "Searching…" : root.error || "Nothing found"
            color: root.error ? Theme.error : Theme.textDim
        }

        delegate: Item {
            id: cell
            required property var modelData
            readonly property bool here: root.pathOf(modelData) !== ""
            readonly property bool current: here && Wallpapers.current === root.pathOf(modelData)
            width: grid.cellWidth
            height: grid.cellHeight
            ClippingRectangle {
                anchors.fill: parent
                anchors.margins: 6
                radius: Theme.rMd
                color: Theme.surfaceHigh
                border.width: cell.current ? 2 : 0
                border.color: Theme.accent
                Image {
                    anchors.fill: parent
                    source: cell.modelData.thumb || cell.modelData.preview || ""
                    sourceSize.width: 440
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
                Rectangle {
                    anchors.fill: parent
                    color: Theme.alpha(Theme.bg, 0.55)
                    visible: root.busy === cell.modelData.id
                    FText { anchors.centerIn: parent; text: "Downloading…"; color: "white" }
                }
                // its name, and whether it's here already
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 28
                    gradient: Gradient {
                        GradientStop { position: 0; color: "transparent" }
                        GradientStop { position: 1; color: "#a0000000" }
                    }
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 4
                        FText {
                            Layout.fillWidth: true
                            text: cell.modelData.name
                            color: "white"
                            font.pixelSize: Theme.fsXs
                            elide: Text.ElideRight
                        }
                        FIcon {
                            visible: cell.here
                            icon: cell.current ? "check_circle" : "download_done"
                            size: 14
                            color: "white"
                        }
                        FText {
                            text: "★ " + cell.modelData.score
                            color: "white"
                            font.pixelSize: Theme.fsXs
                        }
                    }
                }
                StateLayer {
                    disabled: root.busy !== ""
                    onClicked: root.pick(cell.modelData)
                }
            }
        }
    }

    FText {
        Layout.fillWidth: true
        text: "From store.kde.org · saved to " + Wallpapers.dir + "/kde-store · remove them in Settings → Get themes"
        dim: true
        font.pixelSize: Theme.fsXs
        elide: Text.ElideRight
    }

    Component {
        id: searcher
        Process {
            id: sp
            property int tag
            property bool append
            stdout: StdioCollector {
                onStreamFinished: {
                    if (sp.tag !== root.seq)
                        return;
                    try {
                        const d = JSON.parse(text);
                        if (!sp.append)
                            root.got = {};
                        root.results = (sp.append ? root.results : []).concat(d.results || []);
                        root.more = !!d.more;
                        root.error = d.error || "";
                    } catch (e) {
                        root.error = "Unexpected answer from the KDE Store";
                    }
                }
            }
            onExited: {
                if (sp.tag === root.seq)
                    root.loading = false;
                sp.destroy();
            }
        }
    }
    Process {
        id: dl
        property var item
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const path = (JSON.parse(text).paths || [])[0] || "";
                    if (path) {
                        const g = Object.assign({}, root.got);
                        g[dl.item.id] = path;
                        root.got = g;
                        Wallpapers.set(path, root.screenName);
                        Wallpapers.rescan();
                    }
                } catch (e) {}
            }
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) root.error = text.trim().split("\n").pop().replace(/^flamenco: /, "")
        }
        onExited: root.busy = ""
    }
}
