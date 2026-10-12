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
        anchors {
            top: Theme.barTop
            bottom: !Theme.barTop
            left: true
            right: true
        }
        implicitHeight: Theme.barHeight + Theme.barMargin
        exclusiveZone: implicitHeight
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
        Component { id: networkC; StatusIcon { screenName: win.modelData.name; icon: Network.icon; tip: Network.label } }
        Component { id: bluetoothC; StatusIcon { screenName: win.modelData.name; icon: BluetoothState.icon; barVisible: BluetoothState.available } }
        Component { id: audioC; AudioIcon { screenName: win.modelData.name } }
        Component { id: brightnessC; BrightnessIcon { screenName: win.modelData.name } }
        Component { id: batteryC; Battery { screenName: win.modelData.name } }
        Component { id: notifC; NotifBell { screenName: win.modelData.name } }
        Component { id: weatherC; WeatherChip { screenName: win.modelData.name } }
        Component { id: powerC; FIconButton { icon: "power_settings_new"; size: Theme.barHeight - 10; iconColor: Theme.error; onClicked: Panels.toggle("power", win.modelData.name) } }

        Item {
            id: content
            anchors.fill: parent
            anchors.topMargin: Theme.barTop ? Theme.barMargin : 0
            anchors.bottomMargin: Theme.barTop ? 0 : Theme.barMargin
            anchors.leftMargin: Theme.barMargin
            anchors.rightMargin: Theme.barMargin
            opacity: win.enter
            transform: Translate { y: (1 - win.enter) * (Theme.barTop ? -Theme.barHeight : Theme.barHeight) }

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

            BarSection {
                registry: win.registry
                islands: win.islands
                ids: win.cfg.left
                anchors.left: parent.left
                anchors.leftMargin: win.islands ? 0 : 6
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height
            }

            BarSection {
                registry: win.registry
                islands: win.islands
                ids: win.cfg.center
                anchors.centerIn: parent
                height: parent.height
            }

            BarSection {
                registry: win.registry
                islands: win.islands
                ids: win.cfg.right
                anchors.right: parent.right
                anchors.rightMargin: win.islands ? 0 : 6
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height
            }
        }
    }
}
