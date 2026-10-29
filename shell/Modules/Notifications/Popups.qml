import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services
import qs.Widgets

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        readonly property string effect: Theme.spatialMotion("notifications") ? Settings.data.appearance.notifEffect || "slide" : "fade"

        required property ShellScreen modelData
        readonly property string pos: Settings.data.notifications.position
        readonly property bool atTop: pos.startsWith("top")
        readonly property bool here: modelData.name === Panels.targetScreen("")
        readonly property int count: Notifs.popups.count
        onCountChanged: if (count === 0) linger.restart()

        Timer {
            id: linger
            interval: Theme.motionDuration("exit", "notifications") + 50
        }

        screen: modelData
        visible: here && (count > 0 || linger.running)
        color: "transparent"
        anchors {
            top: win.atTop
            bottom: !win.atTop
            right: win.pos.endsWith("right")
            left: win.pos.endsWith("left")
        }
        // the cards sit Theme.edge from the screen's edge (and the bar), level with panels
        // and windows; the window itself goes to the edge so their shadows have room
        implicitWidth: 380 + Theme.edge * 2
        implicitHeight: Math.max(1, list.contentHeight + Theme.edge * 2)
        exclusionMode: ExclusionMode.Normal
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "flamenco-notifications"

        ListView {
            id: list
            anchors.fill: parent
            anchors.margins: Theme.edge
            interactive: false
            spacing: Theme.gap
            verticalLayoutDirection: win.atTop ? ListView.TopToBottom : ListView.BottomToTop
            model: Notifs.popups

            delegate: NotificationCard {
                width: list.width
                popup: true
            }

            add: Transition {
                ParallelAnimation {
                    // Settings → Appearance → Motion: slide in from the side, fade, or pop
                    Anim { property: "x"; from: win.effect === "slide" ? (win.pos.endsWith("left") ? -Theme.sp5 : Theme.sp5) : 0; to: 0; motionRole: "enter"; area: "notifications" }
                    Anim { property: "opacity"; from: 0; to: 1; motionRole: "fade"; area: "notifications" }
                    Anim { property: "scale"; from: win.effect === "pop" ? 0.94 : win.effect === "slide" ? 0.98 : 1; to: 1; motionRole: "enter"; area: "notifications" }
                }
            }
            remove: Transition {
                ParallelAnimation {
                    Anim { property: "opacity"; to: 0; motionRole: "exit"; area: "notifications" }
                    Anim { property: "scale"; to: win.effect === "fade" ? 1 : 0.98; motionRole: "exit"; area: "notifications" }
                }
            }
            displaced: Transition {
                Anim { properties: "x,y"; area: "notifications"; easing.bezierCurve: Theme.curves.emphasizedDecel }
            }
        }
    }
}
