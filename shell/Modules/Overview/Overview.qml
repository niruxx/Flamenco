import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services
import qs.Widgets
import qs.Modules.Background

// Flamenco's overview, like GNOME's Activities (Settings → Overview): a search
// field, this screen's workspaces along the top, the windows of the one showing,
// and a dash of favourite apps. Typing searches apps. Opened by the start
// button, by tapping Super (SuperKey), or with `flamenco overview`.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win

        required property ShellScreen modelData
        readonly property string screenName: modelData.name
        readonly property var cfg: Settings.data.overview
        readonly property bool shown: Panels.current === "overview" && Panels.screen === screenName
        readonly property real p: pAnim.v

        property string query: ""
        property bool allApps: false               // the dash's apps button, with nothing typed
        readonly property bool searching: query.trim() !== "" || allApps
        property int sel: 0                        // keyboard selection: a window, or an app while searching

        readonly property var spaces: Niri.workspacesOn(screenName)
        readonly property var current: spaces.find(w => w.is_active) ?? spaces[0] ?? null
        // the workspace's windows in their layout order (columns left to right), floating ones last
        readonly property var wins: {
            if (!current)
                return [];
            const pos = w => w.layout?.pos_in_scrolling_layout ?? null;
            return Niri.windowsOn(current.id).slice().sort((a, b) => {
                const pa = pos(a), pb = pos(b);
                if (!pa || !pb)
                    return (pa ? 0 : 1) - (pb ? 0 : 1) || String(a.id).localeCompare(String(b.id));
                return pa[0] - pb[0] || pa[1] - pb[1];
            });
        }
        readonly property var apps: searching ? Apps.search(query).slice(0, 48) : []
        readonly property bool showDash: cfg.dash === "always" || (cfg.dash !== "never" && !Settings.data.dock.enabled)
        readonly property real aspect: modelData.width > 0 ? modelData.width / modelData.height : 16 / 9

        function close() {
            Panels.close();
        }
        function openWindow(w) {
            Niri.focusWindow(w.id);
            close();
        }
        function launch(e) {
            Apps.launch(e);
            close();
        }
        // a dash app: its window if it's running (the next one on each click), else start it
        function dashActivate(id) {
            const mine = Niri.windows.filter(w => String(w.app_id).toLowerCase() === String(id).toLowerCase());
            if (mine.length) {
                const i = mine.findIndex(w => w.id === Niri.activeWindowId);
                openWindow(mine[(i + 1) % mine.length]);
                return;
            }
            launch(Apps.lookup(id));
        }
        function moveSel(dx, dy) {
            const n = searching ? apps.length : wins.length;
            if (n === 0)
                return;
            const cols = Math.max(1, searching ? appGrid.cols : windowArea.cols);
            let i = sel + dx + dy * cols;
            sel = Math.max(0, Math.min(n - 1, i));
        }
        function activateSel() {
            if (searching) {
                if (apps[sel])
                    launch(apps[sel]);
            } else if (wins[sel]) {
                openWindow(wins[sel]);
            }
        }

        onShownChanged: {
            if (!shown)
                return;
            query = "";
            field.text = "";
            allApps = false;
            sel = Math.max(0, wins.findIndex(w => w.id === Niri.activeWindowId));
            field.focusInput();
        }
        onSearchingChanged: sel = searching ? 0 : Math.max(0, wins.findIndex(w => w.id === Niri.activeWindowId))

        screen: modelData
        visible: shown || p > 0.01
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        // inside the space the bar (and a dock that stays up) leave free, so they stay in view
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "flamenco-overview"
        WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        // animated value lives on an Item: Behaviors on the window itself crash Qt 6.12
        Item {
            id: pAnim
            property real v: win.shown ? 1 : 0
            Behavior on v { Anim { duration: Theme.durA("panels", 420); easing.bezierCurve: Theme.curves.emphasizedDecel } }
        }

        // ── backdrop: the wallpaper, blurred and dimmed; a click on it closes ──
        Item {
            anchors.fill: parent
            opacity: win.p

            BackdropLayer {
                source: Paths.toUrl(Wallpapers.forScreen(win.screenName))
                shown: win.cfg.blur
            }
            Rectangle {
                anchors.fill: parent
                color: win.cfg.blur ? Theme.alpha(Theme.shadow, 0.25) : Theme.alpha(Theme.bg, 0.82)
            }
            TapHandler { onTapped: win.close() }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.sp5
            spacing: Theme.sp5
            opacity: win.p
            scale: 0.97 + 0.03 * win.p

            // ── search ──
            FTextField {
                id: field
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Math.min(560, win.width * 0.6)
                implicitHeight: 48
                radius: height / 2
                icon: "search"
                placeholder: "Type to search apps"
                fontSize: Theme.fsLg
                onEdited: t => {
                    win.query = t;
                    win.sel = 0;
                }
                onAccepted: win.activateSel()
                onKeyPressed: event => {
                    const k = event.key;
                    if (k === Qt.Key_Escape) {
                        if (win.query !== "" || win.allApps) {
                            field.text = "";
                            win.query = "";
                            win.allApps = false;
                        } else {
                            win.close();
                        }
                    } else if (k === Qt.Key_Down) {
                        win.moveSel(0, 1);
                    } else if (k === Qt.Key_Up) {
                        win.moveSel(0, -1);
                    } else if (k === Qt.Key_Right && (field.text === "" || event.modifiers & Qt.ControlModifier)) {
                        win.moveSel(1, 0);
                    } else if (k === Qt.Key_Left && (field.text === "" || event.modifiers & Qt.ControlModifier)) {
                        win.moveSel(-1, 0);
                    } else if (k === Qt.Key_Tab) {
                        win.moveSel(1, 0);
                    } else if (k === Qt.Key_Backtab) {
                        win.moveSel(-1, 0);
                    } else {
                        return;
                    }
                    event.accepted = true;
                }
            }

            // ── workspaces ──
            Row {
                id: strip
                Layout.alignment: Qt.AlignHCenter
                visible: win.cfg.workspaces && !win.searching && win.spaces.length > 0
                spacing: Theme.sp3
                readonly property real thumbH: Math.max(56, Math.min(120, win.height * 0.1))

                Repeater {
                    model: win.spaces

                    WorkspaceThumb {
                        required property var modelData
                        ws: modelData
                        height: strip.thumbH
                        width: Math.round(strip.thumbH * win.aspect)
                        wallpaper: Paths.toUrl(Wallpapers.forScreen(win.screenName))
                    }
                }
            }

            // ── windows of the workspace showing ──
            Item {
                id: windowArea
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: !win.searching

                // the grid that fits the windows biggest: cells share one size, each
                // window keeps its own shape inside its cell
                readonly property int n: win.wins.length
                readonly property int gap: Theme.sp5
                readonly property int labelH: 30
                readonly property var fit: {
                    let best = { cols: 1, w: 0, h: 0 };
                    for (let c = 1; c <= Math.max(1, n); c++) {
                        const r = Math.ceil(n / c);
                        const cw = (width - (c - 1) * gap) / c;
                        const ch = (height - (r - 1) * gap) / r - labelH;
                        const w = Math.min(cw, ch * win.aspect, width * 0.62);
                        if (w > best.w)
                            best = { cols: c, w, h: w / win.aspect };
                    }
                    return best;
                }
                readonly property int cols: fit.cols
                readonly property int rows: Math.ceil(n / Math.max(1, cols))

                FText {
                    anchors.centerIn: parent
                    visible: windowArea.n === 0
                    text: win.current ? "No windows on this workspace" : ""
                    color: "white"
                    opacity: 0.8
                    font.pixelSize: Theme.fsXl
                }

                Repeater {
                    model: win.wins

                    WindowCard {
                        required property var modelData
                        required property int index
                        winData: modelData
                        overview: win
                        selected: win.sel === index
                        previews: win.cfg.previews
                        shown: win.shown
                        readonly property int col: index % windowArea.cols
                        readonly property int row: Math.floor(index / windowArea.cols)
                        // the last row is centered when it isn't full
                        readonly property int inRow: row === windowArea.rows - 1 ? windowArea.n - row * windowArea.cols : windowArea.cols
                        readonly property real rowW: inRow * windowArea.fit.w + (inRow - 1) * windowArea.gap
                        readonly property real gridH: windowArea.rows * (windowArea.fit.h + windowArea.labelH) + (windowArea.rows - 1) * windowArea.gap
                        x: (windowArea.width - rowW) / 2 + col * (windowArea.fit.w + windowArea.gap)
                        y: (windowArea.height - gridH) / 2 + row * (windowArea.fit.h + windowArea.labelH + windowArea.gap)
                        width: windowArea.fit.w
                        height: windowArea.fit.h + windowArea.labelH
                        Behavior on x { Anim { easing.bezierCurve: Theme.curves.emphasizedDecel } }
                        Behavior on y { Anim { easing.bezierCurve: Theme.curves.emphasizedDecel } }
                        Behavior on width { Anim { easing.bezierCurve: Theme.curves.emphasizedDecel } }
                        Behavior on height { Anim { easing.bezierCurve: Theme.curves.emphasizedDecel } }
                        onHoveredChanged: if (hovered) win.sel = index
                    }
                }
            }

            // ── app search (and every app, from the dash's apps button) ──
            GridView {
                id: appGrid
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: cols * cellWidth
                visible: win.searching
                readonly property int cols: Math.max(1, Math.min(8, Math.floor((win.width - Theme.sp5 * 2) / cellWidth)))
                cellWidth: 136
                cellHeight: 128
                clip: true
                model: win.apps
                currentIndex: win.sel
                boundsBehavior: Flickable.StopAtBounds

                SmoothWheel {
                    view: appGrid
                }

                delegate: Item {
                    id: cell
                    required property var modelData
                    required property int index
                    readonly property bool current: win.sel === index
                    width: appGrid.cellWidth
                    height: appGrid.cellHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: Theme.rLg
                        color: cell.current ? Theme.alpha(Theme.accent, 0.22) : cellMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                        border.width: cell.current ? 1 : 0
                        border.color: Theme.alpha(Theme.accent, 0.5)
                        Behavior on color { CAnim {} }
                    }
                    Column {
                        anchors.centerIn: parent
                        spacing: Theme.sp2
                        AppIcon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            implicitSize: 60
                            name: cell.modelData.icon
                            scale: cell.current && Theme.hoverZoom ? 1.08 : 1
                            Behavior on scale { Anim { easing.bezierCurve: Theme.curves.springFast } }
                        }
                        FText {
                            width: appGrid.cellWidth - 16
                            horizontalAlignment: Text.AlignHCenter
                            text: cell.modelData.name
                            color: "white"
                            elide: Text.ElideRight
                            maximumLineCount: 2
                            wrapMode: Text.Wrap
                            font.pixelSize: Theme.fsSm
                        }
                    }
                    MouseArea {
                        id: cellMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: win.sel = cell.index
                        onClicked: win.launch(cell.modelData)
                    }
                }

                FText {
                    anchors.centerIn: parent
                    visible: appGrid.count === 0
                    text: "No apps match “" + win.query.trim() + "”"
                    color: "white"
                    opacity: 0.8
                    font.pixelSize: Theme.fsLg
                }
            }

            // ── dash: favourite (the dock's pinned) and running apps ──
            Dash {
                Layout.alignment: Qt.AlignHCenter
                visible: win.showDash
                overview: win
            }
        }
    }
}
