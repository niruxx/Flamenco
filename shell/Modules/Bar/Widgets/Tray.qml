import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.Commons
import qs.Widgets

// System tray. Right-click menus are native Qt menus (QApplication).
Row {
    id: root
    required property var window
    property bool barVisible: SystemTray.items.values.length > 0
    spacing: 2

    Repeater {
        model: SystemTray.items

        delegate: Item {
            id: it
            required property SystemTrayItem modelData
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
            }

            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor
                onClicked: mouse => {
                    const item = it.modelData;
                    if (mouse.button === Qt.MiddleButton) {
                        item.secondaryActivate();
                    } else if (mouse.button === Qt.RightButton || item.onlyMenu) {
                        if (item.hasMenu) {
                            const p = it.mapToItem(null, 0, Theme.barTop ? it.height + 6 : -6);
                            item.display(root.window, p.x, p.y);
                        }
                    } else {
                        item.activate();
                    }
                }
                onWheel: wheel => it.modelData.scroll(wheel.angleDelta.y, false)
            }
        }
    }
}
