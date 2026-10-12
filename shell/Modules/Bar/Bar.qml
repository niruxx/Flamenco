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
        Component { id: windowC; WindowTitle {} }
        Component { id: clockC; Clock { screenName: win.modelData.name } }
        Component { id: mediaC; MediaMini { screenName: win.modelData.name } }
        Component { id: trayC; Tray { window: win } }
        Component { id: statsC; SysStats {} }
        Component { id: keyboardC; KeyboardLayout {} }
        Component { id: networkC; StatusIcon { screenName: win.modelData.name; icon: Network.icon; tip: Network.label; detail: "wifi" } }
        Component { id: bluetoothC; StatusIcon { screenName: win.modelData.name; icon: BluetoothState.icon; barVisible: BluetoothState.available; detail: "bluetooth" } }
        Component { id: audioC; AudioIcon { screenName: win.modelData.name } }
        Component { id: brightnessC; BrightnessIcon { screenName: win.modelData.name } }
        Component { id: batteryC; Battery { screenName: win.modelData.name } }
        Component { id: notifC; NotifBell { screenName: win.modelData.name } }
        Component { id: weatherC; WeatherChip { screenName: win.modelData.name } }
        Component { id: quickC; FIconButton { icon: "menu"; size: Theme.barHeight - 10; iconSize: 18; active: Panels.current === "control" && Panels.controlDetail === ""; onClicked: Panels.toggle("control", win.modelData.name) } }
        Component { id: powerC; FIconButton { icon: "power_settings_new"; size: Theme.barHeight - 10; iconColor: Theme.error; onClicked: Panels.toggle("power", win.modelData.name) } }

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
                border.width: win.attached ? 0 : 1
                border.color: Theme.alpha(Theme.border, 0.5)

                layer.enabled: Settings.data.appearance.shadows && !win.attached
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Theme.alpha(Theme.shadow, 0.35)
                    shadowBlur: 0.6
                    shadowVerticalOffset: 2
                }
            }

            // start (left / top)
            BarSection {
                registry: win.registry
                islands: win.islands
                vertical: win.vertical
                ids: win.cfg.left
                x: win.vertical ? (parent.width - width) / 2 : (win.islands ? 0 : 6)
                y: win.vertical ? (win.islands ? 0 : 6) : (parent.height - height) / 2
            }

            // center
            BarSection {
                registry: win.registry
                islands: win.islands
                vertical: win.vertical
                ids: win.cfg.center
                anchors.centerIn: parent
            }

            // end (right / bottom)
            BarSection {
                registry: win.registry
                islands: win.islands
                vertical: win.vertical
                ids: win.cfg.right
                x: win.vertical ? (parent.width - width) / 2 : parent.width - width - (win.islands ? 0 : 6)
                y: win.vertical ? parent.height - height - (win.islands ? 0 : 6) : (parent.height - height) / 2
            }
        }
    }
}
