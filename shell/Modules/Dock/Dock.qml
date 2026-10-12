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
        // revealed while hovered, and for a moment after the pointer leaves
        readonly property bool revealed: !cfg.autoHide || hover.hovered || hideDelay.running
        property real mouseX: -1000

        // App ids only, so the list (and its delegates) stays stable while
        // windows change titles. Pinned apps that aren't installed and aren't
        // running are skipped.
        readonly property var ids: {
            const running = [];
            for (const w of Niri.windows) {
                const id = w.app_id || "";
                if (id && !running.some(r => r.toLowerCase() === id.toLowerCase()))
                    running.push(id);
            }
            const out = cfg.pinned.filter(p => Apps.lookup(p) !== null || running.some(r => r.toLowerCase() === p.toLowerCase()));
            if (cfg.showRunning)
                for (const id of running)
                    if (!out.some(p => p.toLowerCase() === id.toLowerCase()))
                        out.push(id);
            return out;
        }

        screen: modelData
        color: "transparent"
        anchors { bottom: true; left: true; right: true }
        implicitHeight: iconSize * 1.6 + 32
        // Normal (not Ignore) so the dock sits above a bottom bar instead of on it
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: cfg.autoHide ? 0 : iconSize + 20 + Theme.gap * 2
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "flamenco-dock"

        // Input region: the whole dock while revealed, otherwise a thin strip
        // along the entire bottom edge that brings it back.
        mask: Region { item: hitArea }

        Item {
            id: hitArea
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: win.revealed ? dock.width + 24 : parent.width
            height: win.revealed ? parent.height : Math.max(2, win.cfg.revealSize)
        }

        HoverHandler {
            id: hover
            onPointChanged: win.mouseX = point.position.x
            onHoveredChanged: {
                if (!hovered) {
                    win.mouseX = -1000;
                    hideDelay.restart();
                }
            }
        }

        Timer {
            id: hideDelay
            interval: 450
        }

        Rectangle {
            id: dock

            property real shift: win.revealed ? 0 : height + Theme.gap * 2
            Behavior on shift { Anim { duration: Theme.durLong; easing.bezierCurve: Theme.curves.emphasizedDecel } }

            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.gap
            anchors.horizontalCenter: parent.horizontalCenter
            transform: Translate { y: dock.shift }
            visible: win.ids.length > 0
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
                    // ScriptModel diffs by value, so unchanged ids keep their delegates
                    model: ScriptModel { values: win.ids }

                    Item {
                        id: app
                        required property string modelData
                        readonly property var entry: Apps.lookup(modelData)
                        readonly property bool pinned: win.cfg.pinned.includes(modelData)
                        readonly property var windows: Niri.windows.filter(w => (w.app_id || "").toLowerCase() === modelData.toLowerCase())
                        readonly property bool focused: windows.some(w => w.id === Niri.focusedWindowId)
                        readonly property real center: dock.x + row.x + x + width / 2
                        readonly property real mag: win.cfg.magnify ? Math.max(0, 1 - Math.abs(win.mouseX - center) / (win.iconSize * 2.2)) : 0
                        property int cycle: 0

                        width: win.iconSize * (1 + 0.5 * mag)
                        height: width
                        anchors.bottom: parent.bottom
                        Behavior on width { Anim { duration: Theme.durShort; easing.type: Easing.OutCubic } }

                        AppIcon {
                            anchors.fill: parent
                            anchors.margins: 2
                            implicitSize: win.iconSize * 1.5
                            name: app.entry?.icon ?? app.modelData
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
                            width: app.focused ? 16 : app.windows.length > 0 ? 6 : 0
                            color: app.focused ? Theme.accent : Theme.textDim
                            Behavior on width { Anim { easing.bezierCurve: Theme.curves.spring } }
                        }

                        MouseArea {
                            id: area
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => {
                                const wins = app.windows;
                                if (mouse.button === Qt.RightButton) {
                                    if (app.pinned)
                                        Settings.listRemove(win.cfg, "pinned", app.modelData);
                                    else
                                        Settings.listAdd(win.cfg, "pinned", app.modelData);
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
