import QtQuick
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

// Running apps, one button per app (its windows grouped), like a taskbar.
// Click focuses the app (again to cycle its windows), middle-click opens a
// new window, right-click opens the window menu (move to a workspace or
// monitor, float, fullscreen, pin, close, force quit…).
BarFlow {
    id: root

    required property var window             // the bar window, for the menu popup
    property string screenName
    property int barLevel: 0
    readonly property var cfg: Settings.data.bar
    readonly property bool titles: cfg.taskbarTitles && !Theme.barVertical && barLevel < 1

    // which windows: every screen, this screen, or this screen's current workspace
    readonly property var shown: {
        const scope = cfg.taskbarScope;
        if (scope === "all")
            return Niri.windows;
        const ws = Niri.workspacesOn(screenName);
        const ids = (scope === "workspace" ? ws.filter(w => w.is_active) : ws).map(w => w.id);
        return Niri.windows.filter(w => ids.includes(w.workspace_id));
    }
    // app ids, in the order they first appear
    readonly property var apps: {
        const out = [];
        for (const w of shown) {
            const id = String(w.app_id || "");
            if (id && !out.some(a => a.toLowerCase() === id.toLowerCase()))
                out.push(id);
        }
        return out;
    }
    property bool barVisible: apps.length > 0

    Repeater {
        // ScriptModel diffs by value: a window's title changing doesn't rebuild every icon
        model: ScriptModel { values: root.apps }

        BarChip {
            id: chip
            required property string modelData
            readonly property var wins: root.shown.filter(w => String(w.app_id).toLowerCase() === modelData.toLowerCase())
            readonly property var focusedWin: wins.find(w => w.id === Niri.activeWindowId) ?? null
            readonly property var entry: Apps.lookup(modelData)
            property int cycle: 0
            highlighted: focusedWin !== null || menu.visible
            padding: root.titles ? 10 : 7

            onClicked: {
                if (wins.length === 0)
                    return;
                cycle = (cycle + (focusedWin ? 1 : 0)) % wins.length;
                Niri.focusWindow(wins[cycle].id);
            }
            onMiddleClicked: Apps.launch(entry)
            onRightClicked: {
                if (menu.visible) {
                    menu.close();
                    return;
                }
                const p = chip.mapToItem(null, 0, 0);
                menu.open(focusedWin ?? wins[0] ?? null, Qt.rect(p.x, p.y, chip.width, chip.height), modelData);
            }

            BarFlow {
                spacing: 8
                AppIcon {
                    implicitSize: 18
                    name: chip.entry?.icon ?? Apps.iconFor(chip.modelData)
                }
                FText {
                    visible: root.titles
                    width: Math.min(implicitWidth, 160)
                    text: (chip.focusedWin ?? chip.wins[0])?.title ?? chip.entry?.name ?? chip.modelData
                    elide: Text.ElideRight
                    font.pixelSize: Theme.fsSm
                }
            }

            // running indicator: under the button (beside it on a vertical bar); a count for several windows
            Rectangle {
                parent: chip                // on the chip's edge, not inside its centered content
                anchors.bottom: Theme.barVertical ? undefined : parent.bottom
                anchors.horizontalCenter: Theme.barVertical ? undefined : parent.horizontalCenter
                anchors.left: Theme.barVertical ? parent.left : undefined
                anchors.verticalCenter: Theme.barVertical ? parent.verticalCenter : undefined
                width: Theme.barVertical ? 3 : (chip.focusedWin ? 14 : 5)
                height: Theme.barVertical ? (chip.focusedWin ? 14 : 5) : 3
                radius: 1.5
                color: chip.focusedWin ? Theme.accent : Theme.textDim
                Behavior on width { Anim { easing.bezierCurve: Theme.curves.spring } }
                Behavior on height { Anim { easing.bezierCurve: Theme.curves.spring } }
            }

            WindowMenu {
                id: menu
                window: root.window
            }
        }
    }
}
