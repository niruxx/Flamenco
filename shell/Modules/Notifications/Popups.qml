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

        required property ShellScreen modelData
        readonly property string pos: Settings.data.notifications.position
        readonly property bool atTop: pos.startsWith("top")
        readonly property bool here: modelData.name === Panels.targetScreen("")
        readonly property int count: Notifs.popups.count
        onCountChanged: if (count === 0) linger.restart()

        Timer {
            id: linger
            interval: Theme.durLong + 100
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
        margins {
            top: Theme.gap
            bottom: Theme.gap
            left: Theme.gap
            right: Theme.gap
        }
        implicitWidth: 400
        implicitHeight: Math.max(1, list.contentHeight + 20)
        exclusionMode: ExclusionMode.Normal
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "flamenco-notifications"

        ListView {
            id: list
            anchors.fill: parent
            anchors.margins: 10
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
                    NumberAnimation { property: "x"; from: win.pos.endsWith("left") ? -420 : 420; to: 0; duration: Theme.durXl; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curves.spring }
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.durMed }
                    NumberAnimation { property: "scale"; from: 0.85; to: 1; duration: Theme.durLong; easing.type: Easing.OutBack }
                }
            }
            remove: Transition {
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; to: 0; duration: Theme.durMed }
                    NumberAnimation { property: "scale"; to: 0.8; duration: Theme.durMed; easing.type: Easing.InCubic }
                }
            }
            displaced: Transition {
                NumberAnimation { properties: "x,y"; duration: Theme.durLong; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curves.emphasizedDecel }
            }
        }
    }
}
