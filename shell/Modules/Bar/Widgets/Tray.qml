import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.Commons
import qs.Widgets

// System tray (StatusNotifierItem / AppIndicator).
// Left click activates, right click opens the app's menu (themed, or native Qt
// via Settings), middle click is the secondary action, scroll is forwarded.
BarFlow {
    id: root

    required property var window
    readonly property var cfg: Settings.data.bar
    readonly property var items: SystemTray.items.values.filter(i => !(cfg.trayHidePassive && i.status === Status.Passive))
    property int barLevel: 0
    // tight bars show fewer icons before the overflow arrow
    readonly property int maxVisible: barLevel >= 3 ? 0 : barLevel === 2 ? 1 : barLevel === 1 ? Math.min(3, Math.max(1, cfg.trayMaxVisible)) : Math.max(1, cfg.trayMaxVisible)
    readonly property bool overflowing: items.length > maxVisible
    property bool expanded: false
    readonly property var shown: overflowing && !expanded ? items.slice(0, maxVisible) : items
    property bool barVisible: items.length > 0

    spacing: 2

    function anchorFor(item) {
        // rect of `item` in bar-window coordinates, for popup anchoring
        const p = item.mapToItem(null, 0, 0);
        return Qt.rect(p.x, p.y, item.width, item.height);
    }

    function openMenu(trayItem, visual) {
        if (cfg.trayNativeMenus) {
            const r = anchorFor(visual);
            const x = Theme.barPos === "right" ? r.x - 6 : Theme.barPos === "left" ? r.x + r.width + 6 : r.x;
            const y = Theme.barPos === "bottom" ? r.y - 6 : Theme.barVertical ? r.y : r.y + r.height + 6;
            trayItem.display(root.window, x, y);
            return;
        }
        menu.open(trayItem, anchorFor(visual));
    }

    Repeater {
        model: root.shown

        delegate: Item {
            id: it
            required property SystemTrayItem modelData
            readonly property bool attention: modelData.status === Status.NeedsAttention
            width: Theme.barHeight - 12
            height: width

            IconImage {
                id: img
                anchors.centerIn: parent
                implicitSize: 18
                source: {
                    const icon = it.modelData.icon;
                    if (icon.includes("?path=")) {
                        const [name, path] = icon.split("?path=");
                        return "file://" + path + "/" + name.slice(name.lastIndexOf("/") + 1);
                    }
                    return icon;
                }
                scale: area.containsMouse ? 1.15 : 1
                Behavior on scale { Anim { easing.bezierCurve: Theme.curves.springFast } }

                // gentle pulse while the app wants attention
                SequentialAnimation on opacity {
                    running: it.attention && Theme.speed > 0
                    loops: Animation.Infinite
                    onRunningChanged: if (!running) img.opacity = 1
                    NumberAnimation { to: 0.35; duration: 600; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1; duration: 600; easing.type: Easing.InOutSine }
                }
            }

            Rectangle {
                visible: it.attention
                width: 6; height: 6; radius: 3
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 2
                color: Theme.accent
            }

            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor
                onClicked: mouse => {
                    const item = it.modelData;
                    tip.hide();
                    if (mouse.button === Qt.MiddleButton)
                        item.secondaryActivate();
                    else if (mouse.button === Qt.RightButton || item.onlyMenu)
                        item.hasMenu ? root.openMenu(item, it) : item.activate();
                    else
                        item.activate();
                }
                onWheel: wheel => it.modelData.scroll(wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x, wheel.angleDelta.y === 0)
                onContainsMouseChanged: {
                    const text = it.modelData.tooltipTitle || it.modelData.title || it.modelData.id;
                    if (containsMouse && !menu.visible)
                        tip.showFor(text, it.modelData.tooltipDescription, root.anchorFor(it));
                    else
                        tip.hide();
                }
            }
        }
    }

    // overflow toggle
    FIconButton {
        visible: root.overflowing
        size: Theme.barHeight - 14
        iconSize: 16
        icon: Theme.barVertical ? (root.expanded ? "keyboard_arrow_up" : "keyboard_arrow_down") : (root.expanded ? "chevron_left" : "chevron_right")
        onClicked: root.expanded = !root.expanded
    }

    TrayMenu {
        id: menu
        window: root.window
    }

    TrayTooltip {
        id: tip
        window: root.window
    }
}
