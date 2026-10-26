import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

// Menu for a window, opened from the bar's window title or by right-clicking an
// app in the dock: move it to another workspace or monitor, float / fullscreen
// it, open a new window of the app, pin it to the dock, switch to another
// window, close or force quit it. For a pinned app with no window, just Open
// and Unpin.
PopupWindow {
    id: root

    required property var window
    property var win: null                     // snapshot of the window it was opened for
    property string appId: ""                  // the app, when opened for one without a window (dock)
    // the edge it opens away from: the bar's, or the dock's
    property string side: Theme.barPos
    readonly property bool sideVertical: side === "left" || side === "right"
    property string page: "main"               // main | workspaces | monitors | windows
    property bool armed: false                 // force quit asks for a second click
    property real closedAt: 0
    property rect at: Qt.rect(0, 0, 1, 1)

    // the live copy, so floating / workspace changes show while the menu is open
    readonly property var live: win ? (Niri.windows.find(w => w.id === win.id) ?? null) : null
    readonly property string app: live?.app_id ?? appId
    readonly property var entry: app ? Apps.lookup(app) : null
    readonly property int appWindows: app ? Niri.windows.filter(w => String(w.app_id).toLowerCase() === app.toLowerCase()).length : 0
    readonly property var outputs: {
        const out = [];
        for (const w of Niri.workspaces)
            if (w.output && !out.includes(w.output))
                out.push(w.output);
        return out;
    }
    readonly property string winOutput: Niri.workspaces.find(w => w.id === live?.workspace_id)?.output ?? ""
    readonly property bool pinned: !!app && Settings.data.dock.pinned.some(p => p.toLowerCase() === app.toLowerCase())

    // w: a window, or null with appId for an app that isn't running
    function open(w, rect, appId) {
        // the click that closed the menu (focus grab) shouldn't reopen it
        if (Date.now() - closedAt < 250)
            return;
        win = w;
        root.appId = appId ?? "";
        page = "main";
        armed = false;
        at = rect;
        visible = true;
        openAnim.restart();
    }

    function close() {
        visible = false;
    }

    function run(f) {
        if (live)
            f(live);
        close();
    }

    // app actions that don't need a window
    function runApp(f) {
        f();
        close();
    }

    function wsLabel(ws) {
        const name = ws.name ? ws.name : "Workspace " + ws.idx;
        return outputs.length > 1 ? name + "  ·  " + ws.output : name;
    }

    // closes itself if its window goes away
    onLiveChanged: if (visible && win && !live) close()
    onVisibleChanged: if (!visible) {
        closedAt = Date.now();
        armed = false;
    }

    readonly property int gap: 8
    // only a real window (a QML window object), never a plain value
    anchor.window: window && window.contentItem !== undefined ? window : null
    anchor.rect.x: side === "right" ? at.x - gap : side === "left" ? at.x + at.width + gap : at.x + at.width / 2
    anchor.rect.y: side === "bottom" ? at.y - gap : sideVertical ? at.y : at.y + at.height + gap
    anchor.rect.width: 1
    anchor.rect.height: 1
    anchor.edges: side === "bottom" ? Edges.Top : side === "left" ? Edges.Right : side === "right" ? Edges.Left : Edges.Bottom
    anchor.gravity: side === "bottom" ? Edges.Top : side === "left" ? Edges.Right : side === "right" ? Edges.Left : Edges.Bottom
    grabFocus: true
    color: "transparent"
    visible: false

    implicitWidth: 300
    implicitHeight: Math.min(list.implicitHeight + 12, (window?.screen?.height ?? 900) * 0.7)

    Rectangle {
        id: body
        anchors.fill: parent
        radius: Theme.rLg
        color: Theme.popupBg
        border.width: 1
        border.color: Theme.alpha(Theme.border, 0.7)

        property real p: 1
        Anim {
            id: openAnim
            target: body
            property: "p"
            from: 0
            to: 1
            duration: Theme.durMed
            easing.bezierCurve: Theme.curves.emphasizedDecel
        }
        opacity: p
        scale: 0.94 + 0.06 * p

        FScroll {
            id: scroller
            anchors.fill: parent
            anchors.margins: 6
            contentHeight: list.implicitHeight

            ColumnLayout {
                id: list
                width: scroller.width - scroller.gutter
                spacing: 0

                // ── header: the app and its title ──
                RowLayout {
                    visible: root.page === "main"
                    Layout.fillWidth: true
                    Layout.margins: 8
                    spacing: 12

                    AppIcon {
                        implicitSize: 32
                        name: root.entry?.icon ?? Apps.iconFor(root.app)
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        FText {
                            Layout.fillWidth: true
                            text: root.entry?.name ?? root.app
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }
                        FText {
                            Layout.fillWidth: true
                            text: root.live?.title ?? (root.appWindows > 0 ? "" : "Not running")
                            color: Theme.textDim
                            font.pixelSize: Theme.fsSm
                            elide: Text.ElideRight
                        }
                    }
                }

                // back row on the sub-pages
                MenuRow {
                    visible: root.page !== "main"
                    label: root.page === "workspaces" ? "Move to workspace" : root.page === "monitors" ? "Move to monitor" : "Open windows"
                    leadIcon: "arrow_back"
                    bold: true
                    onActivated: root.page = "main"
                }

                Sep { visible: true }

                // ── main page ──
                MenuRow {
                    visible: root.page === "main" && !!root.live
                    label: "Move to workspace"
                    leadIcon: "move_group"
                    submenu: true
                    onActivated: root.page = "workspaces"
                }
                MenuRow {
                    visible: root.page === "main" && !!root.live && root.outputs.length > 1
                    label: "Move to monitor"
                    leadIcon: "monitor"
                    submenu: true
                    onActivated: root.page = "monitors"
                }
                MenuRow {
                    visible: root.page === "main" && !!root.live
                    label: root.live?.is_floating ? "Tile window" : "Float window"
                    leadIcon: root.live?.is_floating ? "view_column" : "picture_in_picture"
                    onActivated: root.run(w => Niri.toggleFloating(w))
                }
                MenuRow {
                    visible: root.page === "main" && !!root.live
                    label: "Resize…"
                    leadIcon: "open_in_full"
                    onActivated: root.run(w => Resize.open(w.id, ""))
                }
                MenuRow {
                    visible: root.page === "main" && !!root.live
                    label: "Fullscreen"
                    leadIcon: "fullscreen"
                    onActivated: root.run(w => Niri.toggleFullscreen(w))
                }
                MenuRow {
                    visible: root.page === "main" && !!root.live && !Niri.hyprland && !root.live?.is_floating
                    label: "Maximize column"
                    leadIcon: "width_full"
                    onActivated: root.run(w => Niri.action("maximize-column"))
                }
                MenuRow {
                    visible: root.page === "main" && !!root.live && !Niri.hyprland && !root.live?.is_floating
                    label: "Center column"
                    leadIcon: "align_horizontal_center"
                    onActivated: root.run(w => Niri.action("center-column"))
                }

                Sep { visible: root.page === "main" && !!root.live }

                MenuRow {
                    visible: root.page === "main" && root.entry !== null
                    label: root.appWindows > 0 ? "New window" : "Open"
                    leadIcon: root.appWindows > 0 ? "add" : "open_in_new"
                    onActivated: root.runApp(() => Apps.launch(root.entry))
                }
                MenuRow {
                    visible: root.page === "main" && root.app !== ""
                    label: root.pinned ? "Unpin from dock" : "Pin to dock"
                    leadIcon: root.pinned ? "keep_off" : "keep"
                    onActivated: root.runApp(() => {
                        const id = root.app;
                        const cfg = Settings.data.dock;
                        const have = cfg.pinned.find(p => p.toLowerCase() === id.toLowerCase());
                        if (have !== undefined)
                            Settings.listRemove(cfg, "pinned", have);
                        else
                            Settings.listAdd(cfg, "pinned", id);
                    })
                }
                MenuRow {
                    visible: root.page === "main" && Niri.windows.length > 1
                    label: "Open windows"
                    leadIcon: "select_window"
                    submenu: true
                    onActivated: root.page = "windows"
                }

                Sep { visible: root.page === "main" && !!root.live }

                MenuRow {
                    visible: root.page === "main" && !!root.live
                    label: "Close window"
                    leadIcon: "close"
                    onActivated: root.run(w => Niri.closeWindow(w.id))
                }
                MenuRow {
                    visible: root.page === "main" && root.appWindows > 1
                    label: "Close all " + root.appWindows + " windows"
                    leadIcon: "close_fullscreen"
                    onActivated: root.runApp(() => {
                        for (const w of Niri.windows.filter(x => String(x.app_id).toLowerCase() === root.app.toLowerCase()))
                            Niri.closeWindow(w.id);
                    })
                }
                MenuRow {
                    visible: root.page === "main" && !!root.live && (root.live?.pid ?? 0) > 0
                    label: root.armed ? "Click again to force quit" : "Force quit"
                    leadIcon: "dangerous"
                    danger: true
                    bold: root.armed
                    onActivated: {
                        if (!root.armed) {
                            root.armed = true;
                            disarm.restart();
                        } else {
                            root.run(w => Niri.forceQuit(w));
                        }
                    }
                }

                // ── workspaces page ──
                Repeater {
                    model: root.page === "workspaces" ? Niri.workspaces : []
                    delegate: MenuRow {
                        required property var modelData
                        readonly property bool here: modelData.id === root.live?.workspace_id
                        label: root.wsLabel(modelData)
                        leadIcon: here ? "radio_button_checked" : "radio_button_unchecked"
                        accent: here
                        enabled: !here
                        onActivated: root.run(w => Niri.moveWindowToWorkspace(w, modelData))
                    }
                }

                // ── monitors page ──
                Repeater {
                    model: root.page === "monitors" ? root.outputs : []
                    delegate: MenuRow {
                        required property string modelData
                        readonly property bool here: modelData === root.winOutput
                        label: modelData
                        leadIcon: here ? "radio_button_checked" : "radio_button_unchecked"
                        accent: here
                        enabled: !here
                        onActivated: root.run(w => Niri.moveWindowToMonitor(w, modelData))
                    }
                }

                // ── open windows page: switch to any of them ──
                Repeater {
                    model: root.page === "windows" ? Niri.windows : []
                    delegate: MenuRow {
                        required property var modelData
                        label: modelData.title || modelData.app_id
                        appIcon: Apps.iconFor(modelData.app_id)
                        accent: modelData.id === root.live?.id
                        onActivated: {
                            Niri.focusWindow(modelData.id);
                            root.close();
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: disarm
        interval: 3000
        onTriggered: root.armed = false
    }

    component Sep: Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        implicitHeight: 1
        color: Theme.border
        opacity: 0.6
    }

    component MenuRow: Rectangle {
        id: mr
        property string label
        property string leadIcon: ""
        property string appIcon: ""
        property bool submenu: false
        property bool bold: false
        property bool danger: false
        property bool accent: false
        signal activated

        Layout.fillWidth: true
        implicitHeight: 34
        radius: Theme.rSm
        color: "transparent"
        opacity: enabled || accent ? 1 : 0.45

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 12

            FIcon {
                visible: mr.leadIcon !== "" && mr.appIcon === ""
                icon: mr.leadIcon
                size: 18
                fill: mr.accent ? 1 : 0
                color: mr.danger ? Theme.error : mr.accent ? Theme.accent : Theme.text
            }
            AppIcon {
                visible: mr.appIcon !== ""
                implicitSize: 18
                name: mr.appIcon
            }
            FText {
                Layout.fillWidth: true
                text: mr.label
                color: mr.danger ? Theme.error : mr.accent ? Theme.accent : Theme.text
                font.weight: mr.bold || mr.accent ? Font.DemiBold : Font.Normal
                elide: Text.ElideRight
            }
            FIcon {
                visible: mr.submenu
                icon: "chevron_right"
                size: 18
                color: Theme.textDim
            }
        }

        StateLayer {
            disabled: !mr.enabled
            onClicked: mr.activated()
        }
    }
}
