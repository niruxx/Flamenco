import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services

// Desktop widgets: one layer per screen above the wallpaper and below windows
// (niri's "bottom" layer). Only the widgets take clicks; the rest of the
// desktop is left alone. While they're being arranged on a screen, the editor
// draws them there instead.
Variants {
    model: Settings.data.desktop.enabled ? Quickshell.screens : []

    PanelWindow {
        id: win

        required property ShellScreen modelData
        readonly property var list: Desk.on(modelData.name)
        readonly property bool editingHere: Panels.widgetsEdit && Panels.screen === modelData.name

        screen: modelData
        visible: list.length > 0
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        // inside the space the bar and dock leave free, so it never covers them
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "flamenco-widgets"
        // notes take typing when clicked
        WlrLayershell.keyboardFocus: list.some(w => w.type === "note") ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        // input only where the widgets are
        readonly property var regions: {
            rep.count;
            win.editingHere;
            const out = [];
            for (let i = 0; i < rep.count; i++) {
                const it = rep.itemAt(i);
                if (it && !win.editingHere)
                    out.push(it.region);
            }
            return out;
        }
        mask: Region { regions: win.regions }

        Repeater {
            id: rep
            model: win.list

            WidgetBody {
                id: wb
                required property var modelData
                spec: modelData
                x: Desk.px(modelData.x, win.width, width)
                y: Desk.px(modelData.y, win.height, height)
                visible: !win.editingHere
                // after logging in they fade and rise into place (SessionFx.revealDesk)
                opacity: SessionFx.revealDesk
                transform: Translate { y: (1 - SessionFx.revealDesk) * 24 }
                property Region region: Region { item: wb }
            }
        }
    }
}
