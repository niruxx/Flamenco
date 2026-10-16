import QtQuick
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

// The overview's dash: the dock's pinned apps, then other running ones, and
// a button for every app. A dot marks running apps; clicking one goes to its
// window (the next one on each click), otherwise starts it.
Rectangle {
    id: dash

    property var overview
    readonly property var ids: {
        const running = [];
        for (const w of Niri.windows) {
            const id = w.app_id || "";
            if (id && !running.some(r => r.toLowerCase() === id.toLowerCase()))
                running.push(id);
        }
        const pinned = (Settings.data.dock.pinned || []).filter(p => Apps.lookup(p) !== null || running.some(r => r.toLowerCase() === p.toLowerCase()));
        return pinned.concat(running.filter(id => !pinned.some(p => p.toLowerCase() === id.toLowerCase())));
    }

    implicitWidth: row.width + Theme.sp3 * 2
    implicitHeight: 76
    radius: Math.min(Theme.rXl, height / 2)
    color: Theme.alpha(Theme.surface, 0.78)
    border.width: 1
    border.color: Theme.alpha(Theme.border, 0.6)

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.sp2

        Repeater {
            model: ScriptModel { values: dash.ids }

            Item {
                id: app
                required property var modelData
                readonly property var entry: Apps.lookup(modelData)
                readonly property bool running: Niri.windows.some(w => String(w.app_id).toLowerCase() === String(modelData).toLowerCase())
                width: 58
                height: 64

                AppIcon {
                    anchors.centerIn: parent
                    implicitSize: 46
                    name: app.entry?.icon ?? app.modelData
                    scale: appMouse.containsMouse && Theme.hoverZoom ? 1.12 : 1
                    Behavior on scale { Anim { easing.bezierCurve: Theme.curves.springFast } }
                }
                Rectangle {
                    visible: app.running
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    width: 6
                    height: 6
                    radius: 3
                    color: Theme.accent
                }
                // the name above, on hover
                Rectangle {
                    visible: appMouse.containsMouse
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.top
                    anchors.bottomMargin: Theme.sp3
                    width: tip.implicitWidth + 20
                    height: tip.implicitHeight + 10
                    radius: height / 2
                    color: Theme.surfaceHigh
                    FText {
                        id: tip
                        anchors.centerIn: parent
                        text: app.entry?.name ?? app.modelData
                        font.pixelSize: Theme.fsSm
                    }
                }
                MouseArea {
                    id: appMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: dash.overview.dashActivate(app.modelData)
                }
            }
        }

        Rectangle {
            visible: dash.ids.length > 0
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: 40
            color: Theme.alpha(Theme.border, 0.8)
        }

        FIconButton {
            anchors.verticalCenter: parent.verticalCenter
            size: 52
            icon: "apps"
            active: dash.overview.allApps
            onClicked: dash.overview.allApps = !dash.overview.allApps
        }
    }
}
