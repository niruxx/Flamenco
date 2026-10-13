import QtQuick
import qs.Commons
import qs.Services
import qs.Widgets

// Focused window: icon + title (icon only on a vertical bar). Click or
// right-click for the window menu (move, float, fullscreen, pin, close,
// force quit…); middle-click closes the window.
BarChip {
    id: root
    required property var window             // the bar window, for the menu popup
    readonly property var win: Niri.focusedWindow
    property int barLevel: 0
    property bool barVisible: win !== null && barLevel < 2
    highlighted: menu.visible

    function openMenu() {
        if (!win)
            return;
        if (menu.visible) {
            menu.close();
            return;
        }
        const p = root.mapToItem(null, 0, 0);
        menu.open(win, Qt.rect(p.x, p.y, root.width, root.height));
    }

    onClicked: openMenu()
    onRightClicked: openMenu()
    onMiddleClicked: if (win) Niri.closeWindow(win.id)

    BarFlow {
        spacing: 8

        AppIcon {
            implicitSize: 18
            name: Apps.iconFor(root.win?.app_id ?? "")
        }

        FText {
            visible: !Theme.barVertical && root.barLevel < 1
            width: Math.min(implicitWidth, 280)
            text: root.win?.title ?? ""
            elide: Text.ElideRight
            font.pixelSize: Theme.fsSm
            font.weight: Font.Medium
        }
    }

    WindowMenu {
        id: menu
        window: root.window
    }
}
