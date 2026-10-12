import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services
import qs.Widgets

// Pinned + running apps, macOS-style magnification, auto-hide.
Variants {
    model: Settings.data.dock.enabled ? Quickshell.screens : []

    PanelWindow {
        id: win

        required property ShellScreen modelData
        readonly property var cfg: Settings.data.dock
        readonly property int iconSize: cfg.iconSize
        readonly property bool revealed: !cfg.autoHide || hover.hovered
        property real mouseX: -1000

        readonly property var apps: {
            const running = {};
            for (const w of Niri.windows) {
                const id = w.app_id || "unknown";
                (running[id] = running[id] || []).push(w);
            }
            const ids = cfg.pinned.slice();
            for (const id in running)
                if (!ids.some(p => p.toLowerCase() === id.toLowerCase()))
                    ids.push(id);
            return ids.map(id => ({
                        id,
                        pinned: cfg.pinned.includes(id),
                        windows: Object.keys(running).filter(k => k.toLowerCase() === id.toLowerCase()).flatMap(k => running[k])
                    }));
        }

        screen: modelData
        color: "transparent"
        anchors { bottom: true; left: true; right: true }
        implicitHeight: iconSize * 1.9 + 24
        exclusiveZone: cfg.autoHide ? 0 : iconSize + 28
        exclusionMode: cfg.autoHide ? ExclusionMode.Ignore : ExclusionMode.Normal
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "flamenco-dock"
        mask: Region { item: win.revealed ? hit : edge }

        Item {
            id: edge
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: dock.width
            height: 4
        }

        Item {
            id: hit
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: dock.width + 20
            height: parent.height
        }

        HoverHandler {
            id: hover
            onPointChanged: win.mouseX = point.position.x
            onHoveredChanged: if (!hovered) win.mouseX = -1000
        }

        Rectangle {
            id: dock

            property real shift: win.revealed ? 0 : height + 20
            Behavior on shift { Anim { duration: Theme.durLong; easing.bezierCurve: Theme.curves.emphasizedDecel } }

            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.gap
            anchors.horizontalCenter: parent.horizontalCenter
            transform: Translate { y: dock.shift }
            width: row.width + 20
            height: win.iconSize + 20
            radius: Theme.rXl
            color: Theme.panelBg
            border.width: 1
            border.color: Theme.alpha(Theme.border, 0.6)

            Behavior on width { Anim { easing.bezierCurve: Theme.curves.emphasizedDecel } }

            Row {
                id: row
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 10
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6

                Repeater {
                    model: win.apps

                    Item {
                        id: app
                        required property var modelData
                        readonly property var entry: Apps.lookup(modelData.id)
                        readonly property real center: dock.x + row.x + x + width / 2
                        readonly property real mag: win.cfg.magnify ? Math.max(0, 1 - Math.abs(win.mouseX - center) / (win.iconSize * 2.2)) : 0
                        readonly property bool focused: modelData.windows.some(w => w.id === Niri.focusedWindowId)
                        property int cycle: 0

                        width: win.iconSize * (1 + 0.5 * mag)
                        height: width
                        anchors.bottom: parent.bottom
                        Behavior on width { Anim { duration: Theme.durShort; easing.type: Easing.OutCubic } }

                        AppIcon {
                            anchors.fill: parent
                            anchors.margins: 2
                            implicitSize: win.iconSize * 1.5
                            name: app.entry?.icon ?? app.modelData.id
                            scale: area.pressed ? 0.85 : 1
                            Behavior on scale { Anim { easing.bezierCurve: Theme.curves.springFast } }
                        }

                        // running indicator
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.bottom
                            anchors.topMargin: 2
                            height: 4
                            radius: 2
                            width: app.focused ? 16 : app.modelData.windows.length > 0 ? 6 : 0
                            color: app.focused ? Theme.accent : Theme.textDim
                            Behavior on width { Anim { easing.bezierCurve: Theme.curves.spring } }
                        }

                        MouseArea {
                            id: area
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => {
                                const wins = app.modelData.windows;
                                if (mouse.button === Qt.RightButton) {
                                    if (app.modelData.pinned)
                                        Settings.listRemove(win.cfg, "pinned", app.modelData.id);
                                    else
                                        Settings.listAdd(win.cfg, "pinned", app.modelData.id);
                                } else if (mouse.button === Qt.MiddleButton || wins.length === 0) {
                                    Apps.launch(app.entry);
                                } else {
                                    app.cycle = (app.cycle + (app.focused ? 1 : 0)) % wins.length;
                                    Niri.focusWindow(wins[app.cycle].id);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
