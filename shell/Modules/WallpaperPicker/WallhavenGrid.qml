import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.Commons
import qs.Services
import qs.Widgets

// Wallhaven (wallhaven.cc), safe-for-work images at least the screen's size.
// A click downloads it into <wallpaper folder>/wallhaven and sets it.
ColumnLayout {
    id: root

    property string screenName: ""
    property size minSize: Qt.size(1920, 1080)
    property string query: ""
    property string sorting: "toplist"
    property var results: []
    property int page: 1
    property int lastPage: 1
    property bool loading: false
    property string error: ""
    property string busy: ""                // the image being downloaded

    function search(more) {
        page = more ? page + 1 : 1;
        loading = true;
        error = "";
        const q = encodeURIComponent(query.trim());
        const url = "https://wallhaven.cc/api/v1/search?q=" + q + "&categories=110&purity=100&sorting=" + sorting
            + (sorting === "toplist" ? "&topRange=1M" : "") + "&atleast=" + Math.round(minSize.width) + "x" + Math.round(minSize.height) + "&page=" + page;
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            loading = false;
            if (xhr.status !== 200) {
                error = xhr.status === 429 ? "Wallhaven is busy; try again in a minute" : "Couldn't reach Wallhaven" + (xhr.status ? " (" + xhr.status + ")" : "");
                return;
            }
            try {
                const d = JSON.parse(xhr.responseText);
                results = (more ? results : []).concat(d.data ?? []);
                lastPage = d.meta?.last_page ?? 1;
            } catch (e) {
                error = "Unexpected answer from Wallhaven";
            }
        };
        xhr.open("GET", url);
        xhr.send();
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
            placeholder: "Search Wallhaven (nature, city, minimal…)"
            onAccepted: {
                root.query = text;
                root.search(false);
            }
        }
        FSegmented {
            implicitWidth: 320
            implicitHeight: 38
            options: [{ value: "toplist", label: "Top" }, { value: "date_added", label: "Latest" }, { value: "random", label: "Random" }, { value: "relevance", label: "Relevant" }]
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
        Layout.preferredHeight: 420
        readonly property int cols: Math.max(2, Math.floor(width / 220))
        cellWidth: width / cols
        cellHeight: cellWidth * 0.62
        clip: true
        // diffed: the next page is added below instead of replacing the list (which scrolled to the top)
        model: ScriptModel { values: root.results }
        boundsBehavior: Flickable.OvershootBounds
        SmoothWheel { view: grid }
        // the next page when the end comes into view
        onAtYEndChanged: if (atYEnd && !root.loading && root.page < root.lastPage && count > 0) root.search(true)

        FText {
            anchors.centerIn: parent
            visible: grid.count === 0
            text: root.loading ? "Searching…" : root.error || "Nothing found"
            color: root.error ? Theme.error : Theme.textDim
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
                Image {
                    anchors.fill: parent
                    source: cell.modelData.thumbs?.small ?? ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
                Rectangle {
                    anchors.fill: parent
                    color: Theme.alpha(Theme.bg, 0.55)
                    visible: root.busy === cell.modelData.path
                    FText { anchors.centerIn: parent; text: "Downloading…"; color: "white" }
                }
                FText {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 6
                    text: cell.modelData.resolution ?? ""
                    color: "white"
                    font.pixelSize: Theme.fsXs
                    style: Text.Outline
                    styleColor: "#80000000"
                }
                StateLayer {
                    disabled: root.busy !== ""
                    onClicked: {
                        root.busy = cell.modelData.path;
                        dl.command = [Paths.bin, "wallhaven", "get", cell.modelData.path];
                        dl.running = true;
                    }
                }
            }
        }
    }

    FText {
        Layout.fillWidth: true
        text: "From wallhaven.cc · saved to " + Wallpapers.dir + "/wallhaven"
        dim: true
        font.pixelSize: Theme.fsXs
    }

    Process {
        id: dl
        stdout: StdioCollector {
            onStreamFinished: {
                const path = text.trim();
                if (path) {
                    Wallpapers.set(path, root.screenName);
                    Wallpapers.rescan();
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) root.error = text.trim().replace(/^flamenco: /, "")
        }
        onExited: root.busy = ""
    }
}
