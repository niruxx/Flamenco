import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services
import qs.Widgets
import "Widgets"

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win

        required property ShellScreen modelData
        readonly property var cfg: Settings.data.bar
        readonly property bool islands: cfg.style === "islands"
        readonly property bool attached: cfg.style === "attached"

        screen: modelData
        color: "transparent"
        readonly property bool vertical: Theme.barVertical
        readonly property int sectionGap: 12

        // compaction level for this screen; recomputed from 0 whenever the space or layout changes
        property int level: 0
        function refit() {
            level = 0;
            refitTimer.restart();
        }
        Timer {
            id: refitTimer
            interval: 80
            onTriggered: fitTimer.restart()
        }
        Connections {
            target: Settings.data.bar
            function onLeftChanged() { win.refit(); }
            function onCenterChanged() { win.refit(); }
            function onRightChanged() { win.refit(); }
            function onHeightChanged() { win.refit(); }
            function onPositionChanged() { win.refit(); }
        }
        Connections {
            target: Settings.data.appearance
            function onUiScaleChanged() { win.refit(); }
        }
        readonly property string pos: Theme.barPos
        readonly property int thickness: Theme.barHeight + Theme.barMargin

        anchors {
            top: win.pos !== "bottom"
            bottom: win.pos !== "top"
            left: win.pos !== "right"
            right: win.pos !== "left"
        }
        implicitHeight: vertical ? 0 : thickness
        implicitWidth: vertical ? thickness : 0
        exclusiveZone: thickness
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "flamenco-bar"

        // Entrance: slide in from the edge on startup.
        readonly property real enter: enterAnim.v

        // animated value lives on an Item: Behaviors on the window itself crash Qt 6.12
        Item {
            id: enterAnim
            property real v: 0
            Component.onCompleted: v = 1
            Behavior on v { Anim { duration: Theme.durXl; easing.bezierCurve: Theme.curves.emphasizedDecel } }
        }

        readonly property var registry: ({
                launcher: launcherC,
                workspaces: workspacesC,
                window: windowC,
                taskbar: taskbarC,
                clock: clockC,
                media: mediaC,
                tray: trayC,
                sysstats: statsC,
                keyboard: keyboardC,
                network: networkC,
                bluetooth: bluetoothC,
                audio: audioC,
                brightness: brightnessC,
                battery: batteryC,
                notifications: notifC,
                weather: weatherC,
                quicksettings: quickC,
                power: powerC
            })

        Component { id: launcherC; LauncherButton { screenName: win.modelData.name } }
        Component { id: workspacesC; Workspaces { screenName: win.modelData.name } }
        Component { id: windowC; WindowTitle { window: win } }
        Component { id: taskbarC; Taskbar { window: win; screenName: win.modelData.name } }
        Component { id: clockC; Clock { screenName: win.modelData.name } }
        Component { id: mediaC; MediaMini { screenName: win.modelData.name } }
        Component { id: trayC; Tray { window: win } }
        Component { id: statsC; SysStats { screenName: win.modelData.name } }
        Component { id: keyboardC; KeyboardLayout {} }
        Component { id: networkC; StatusIcon { screenName: win.modelData.name; icon: Network.icon; tip: Network.label; detail: "wifi" } }
        Component { id: bluetoothC; StatusIcon { screenName: win.modelData.name; icon: BluetoothState.icon; barVisible: BluetoothState.available && barLevel < 3; detail: "bluetooth" } }
        Component { id: audioC; AudioIcon { screenName: win.modelData.name } }
        Component { id: brightnessC; BrightnessIcon { screenName: win.modelData.name } }
        Component { id: batteryC; Battery { screenName: win.modelData.name } }
        Component { id: notifC; NotifBell { screenName: win.modelData.name } }
        Component { id: weatherC; WeatherChip { screenName: win.modelData.name } }
        Component { id: quickC; FIconButton { id: qsBtn; icon: "menu"; size: Theme.barHeight - 10; iconSize: 18; active: Panels.current === "control" && Panels.controlDetail === ""; onClicked: Panels.toggle("control", win.modelData.name, qsBtn) } }
        Component { id: powerC; FIconButton { id: powerBtn; icon: "power_settings_new"; size: Theme.barHeight - 10; iconColor: Theme.error; onClicked: Panels.toggle("power", win.modelData.name, powerBtn) } }

        Item {
            id: content
            anchors.fill: parent
            // margin on the screen-edge side and both ends; none on the inner side
            anchors.topMargin: win.pos === "bottom" ? 0 : Theme.barMargin
            anchors.bottomMargin: win.pos === "top" ? 0 : Theme.barMargin
            anchors.leftMargin: win.pos === "right" ? 0 : Theme.barMargin
            anchors.rightMargin: win.pos === "left" ? 0 : Theme.barMargin
            opacity: win.enter
            transform: Translate {
                readonly property real d: (1 - win.enter) * Theme.barHeight
                x: win.pos === "left" ? -d : win.pos === "right" ? d : 0
                y: win.pos === "top" ? -d : win.pos === "bottom" ? d : 0
            }

            Rectangle {
                id: bg
                anchors.fill: parent
                visible: !win.islands
                color: Theme.barBg
                radius: win.attached ? 0 : Theme.rLg
                // no outline when panels blend into the bar: it would show as a seam
                border.width: win.attached || Theme.blendPanels ? 0 : 1
                border.color: Theme.alpha(Theme.border, 0.5)

                layer.enabled: Settings.data.appearance.shadows && !win.attached
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Theme.alpha(Theme.shadow, 0.35)
                    shadowBlur: 0.6
                    shadowVerticalOffset: 2
                }
            }

            // ── fit to the space available ──
            // Sections that don't fit step the bar through compaction levels
            // (0 full · 1 no text labels · 2 low-priority widgets hidden · 3 minimal).
            readonly property real avail: win.vertical ? height : width
            readonly property real used: (startSec.visible ? startSec.size : 0) + (centerSec.visible ? centerSec.size : 0) + (endSec.visible ? endSec.size : 0) + 2 * win.sectionGap + 12
            onUsedChanged: fitTimer.restart()
            onAvailChanged: win.refit()

            Timer {
                id: fitTimer
                interval: 80
                onTriggered: {
                    if (content.used > content.avail && win.level < 3) {
                        win.level++;
                        restart();
                    }
                }
            }

            // start (left / top)
            BarSection {
                id: startSec
                barSide: "start"
                registry: win.registry
                islands: win.islands
                vertical: win.vertical
                level: win.level
                ids: win.cfg.left
                x: win.vertical ? (parent.width - width) / 2 : (win.islands ? 0 : 6)
                y: win.vertical ? (win.islands ? 0 : 6) : (parent.height - height) / 2
            }

            // center: centered when there's room, otherwise kept between its neighbours
            BarSection {
                id: centerSec
                barSide: "center"
                registry: win.registry
                islands: win.islands
                vertical: win.vertical
                level: win.level
                ids: win.cfg.center

                readonly property real lo: startSec.visible ? (win.vertical ? startSec.y + startSec.height : startSec.x + startSec.width) + win.sectionGap : 0
                readonly property real hi: (endSec.visible ? (win.vertical ? endSec.y : endSec.x) - win.sectionGap : (win.vertical ? parent.height : parent.width)) - size
                readonly property real ideal: ((win.vertical ? parent.height : parent.width) - size) / 2
                readonly property real pos: Math.max(lo, Math.min(hi, ideal))

                x: win.vertical ? (parent.width - width) / 2 : pos
                y: win.vertical ? pos : (parent.height - height) / 2
            }

            // end (right / bottom)
            BarSection {
                id: endSec
                barSide: "end"
                registry: win.registry
                islands: win.islands
                vertical: win.vertical
                level: win.level
                ids: win.cfg.right
                x: win.vertical ? (parent.width - width) / 2 : parent.width - width - (win.islands ? 0 : 6)
                y: win.vertical ? parent.height - height - (win.islands ? 0 : 6) : (parent.height - height) / 2
            }
        }
    }
}
