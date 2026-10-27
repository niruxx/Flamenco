import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

// The desktop's right-click menu: wallpaper, widgets, a terminal, the display and
// appearance settings.
PopupWindow {
    id: root

    required property var window
    property string screenName: ""
    property point at: Qt.point(0, 0)

    function open(x, y) {
        at = Qt.point(x, y);
        visible = true;
    }
    function run(f) {
        visible = false;
        f();
    }

    anchor.window: window
    anchor.rect.x: at.x
    anchor.rect.y: at.y
    anchor.rect.width: 1
    anchor.rect.height: 1
    anchor.edges: Edges.Top | Edges.Left
    anchor.gravity: Edges.Bottom | Edges.Right
    grabFocus: true
    color: "transparent"
    visible: false
    implicitWidth: 250
    implicitHeight: col.implicitHeight + 12

    Rectangle {
        anchors.fill: parent
        radius: Theme.rLg
        color: Theme.popupBg
        border.width: 1
        border.color: Theme.alpha(Theme.border, 0.7)

        ColumnLayout {
            id: col
            anchors.fill: parent
            anchors.margins: 6
            spacing: 0
            MenuItemRow { label: "Change wallpaper…"; leadIcon: "wallpaper"; onActivated: root.run(() => Panels.open("wallpaper", root.screenName)) }
            MenuItemRow { label: "Next wallpaper"; leadIcon: "shuffle"; onActivated: root.run(() => Wallpapers.random(root.screenName)) }
            Rectangle { Layout.fillWidth: true; Layout.margins: 4; implicitHeight: 1; color: Theme.alpha(Theme.text, 0.08) }
            MenuItemRow { label: "Add or arrange widgets"; leadIcon: "widgets"; onActivated: root.run(() => Panels.editWidgets(root.screenName)) }
            MenuItemRow {
                label: Settings.data.desktop.enabled ? "Hide desktop widgets" : "Show desktop widgets"
                leadIcon: Settings.data.desktop.enabled ? "visibility_off" : "visibility"
                onActivated: root.run(() => Settings.data.desktop.enabled = !Settings.data.desktop.enabled)
            }
            Rectangle { Layout.fillWidth: true; Layout.margins: 4; implicitHeight: 1; color: Theme.alpha(Theme.text, 0.08) }
            MenuItemRow { label: "Open a terminal"; leadIcon: "terminal"; onActivated: root.run(() => Quickshell.execDetached(Paths.term([]))) }
            MenuItemRow { label: "Files"; leadIcon: "folder_open"; onActivated: root.run(() => Quickshell.execDetached(["xdg-open", Paths.home])) }
            Rectangle { Layout.fillWidth: true; Layout.margins: 4; implicitHeight: 1; color: Theme.alpha(Theme.text, 0.08) }
            MenuItemRow { label: "Display settings"; leadIcon: "monitor"; onActivated: root.run(() => Panels.openSettings("displays")) }
            MenuItemRow { label: "Appearance"; leadIcon: "palette"; onActivated: root.run(() => Panels.openSettings("appearance")) }
            MenuItemRow { label: "Settings"; leadIcon: "settings"; onActivated: root.run(() => Panels.openSettings("")) }
        }
    }
}
