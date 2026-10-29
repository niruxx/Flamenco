import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services
import qs.Widgets
import qs.Modules.Calendar

// The notification center as a shade (Settings → Notifications → Style → Shade):
// a full-height sheet sliding in from the left or right edge, under the bar,
// with the date and time, the month, and the notifications grouped by app.
// Opened like the drop-down (the bell, Mod+N, `flamenco notifications`).
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win

        required property ShellScreen modelData
        readonly property var cfg: Settings.data.notifications
        readonly property bool shown: Panels.current === "notifications" && Panels.screen === modelData.name && cfg.style === "shade"
        readonly property real p: pAnim.v
        // which edge: as set, or (auto) the side of the bar the bell is on
        readonly property string side: cfg.shadeSide === "left" ? "left" : cfg.shadeSide === "right" ? "right" : Panels.side === "start" ? "left" : "right"
        readonly property int sheetW: Math.min(440, width - 40)

        // the notifications, newest first, grouped by app (the groups in order of their newest)
        readonly property var groups: {
            Notifs.history.count;                  // re-run when notifications come and go
            const out = [];
            const by = {};
            for (let i = 0; i < Notifs.history.count; i++) {
                const e = Notifs.history.get(i);
                const app = e.appName || "Notification";
                if (!by[app]) {
                    by[app] = { app, items: [] };
                    out.push(by[app]);
                }
                by[app].items.push({ nid: e.nid, appName: e.appName, appIcon: e.appIcon, image: e.image, summary: e.summary, body: e.body, urgency: e.urgency, time: e.time, timeout: e.timeout, actionsJson: e.actionsJson });
            }
            return out;
        }

        onShownChanged: if (shown) Notifs.markRead()

        screen: modelData
        visible: shown || p > 0.01
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        // under the bar (it stays in view), over everything else
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "flamenco-notification-shade"
        WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        // animated value lives on an Item: Behaviors on the window itself crash Qt 6.12
        Item {
            id: pAnim
            property real v: win.shown ? 1 : 0
            Behavior on v { Anim { motionRole: win.shown ? "enter" : "exit"; area: "notifications" } }
        }

        // the rest of the screen, a little dimmed; a click there closes it
        Rectangle {
            anchors.fill: parent
            color: Theme.alpha(Theme.shadow, 0.18)
            opacity: win.p
            MouseArea {
                anchors.fill: parent
                onClicked: Panels.close()
            }
        }
        Item {
            focus: win.shown
            Keys.onEscapePressed: Panels.close()
        }

        // ── the sheet ──
        Rectangle {
            id: sheet
            width: win.sheetW
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.margins: Theme.edge
            x: win.side === "left" ? Theme.edge - (1 - win.p) * (width + Theme.edge * 2) : parent.width - width - Theme.edge + (1 - win.p) * (width + Theme.edge * 2)
            radius: Theme.rXl
            color: Theme.panelBg
            border.width: 1
            border.color: Theme.alpha(Theme.border, 0.7)
            MouseArea { anchors.fill: parent }   // clicks on it stay on it

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 14

                // the day, and the time with the weather
                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: -2
                        FText { text: Time.format("dddd"); color: Theme.accent3; font.weight: Font.Bold; font.pixelSize: Theme.fsSm }
                        FText { text: Time.format("d MMMM"); font.pixelSize: 30; font.weight: Font.Bold }
                    }
                    ColumnLayout {
                        spacing: -2
                        FText { Layout.alignment: Qt.AlignRight; text: Time.time; font.pixelSize: 34; font.weight: Font.Light }
                        FText {
                            Layout.alignment: Qt.AlignRight
                            visible: Weather.ready
                            text: Math.round(Weather.temp) + "° · " + Weather.description
                            dim: true
                            font.pixelSize: Theme.fsXs
                        }
                    }
                }

                // the month
                Rectangle {
                    Layout.fillWidth: true
                    visible: win.cfg.shadeCalendar ?? true
                    implicitHeight: month.implicitHeight + 24
                    radius: Theme.rLg
                    color: Theme.alpha(Theme.text, 0.04)
                    border.width: 1
                    border.color: Theme.alpha(Theme.text, 0.07)
                    MonthGrid {
                        id: month
                        anchors.fill: parent
                        anchors.margins: 12
                        cellHeight: 30
                    }
                }

                // notifications: the count, Do not disturb, Clear
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Rectangle {
                        Layout.preferredWidth: 30
                        Layout.preferredHeight: 30
                        radius: 9
                        color: Theme.alpha(Theme.accent, 0.18)
                        FIcon { anchors.centerIn: parent; icon: Notifs.dnd ? "notifications_off" : "notifications"; size: 17; fill: 1; color: Theme.accent }
                    }
                    FText { text: I18n.tr("Notifications"); font.weight: Font.Bold; font.pixelSize: Theme.fsLg }
                    FText { visible: Notifs.history.count > 0; text: Notifs.history.count; color: Theme.accent; font.weight: Font.Bold; font.pixelSize: Theme.fsLg }
                    Item { Layout.fillWidth: true }
                    FButton {
                        implicitHeight: 32
                        text: I18n.tr("DND")
                        icon: Notifs.dnd ? "notifications_off" : "do_not_disturb_on"
                        variant: Notifs.dnd ? "filled" : "tonal"
                        onClicked: Notifs.setDnd(!Notifs.dnd)
                    }
                    FButton {
                        implicitHeight: 32
                        text: I18n.tr("Clear")
                        icon: "clear_all"
                        variant: "tonal"
                        disabled: Notifs.history.count === 0
                        onClicked: Notifs.clearAll()
                    }
                }

                // grouped by app
                ListView {
                    id: list
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 10
                    model: ScriptModel { values: win.groups.map(g => g.app) }
                    boundsBehavior: Flickable.StopAtBounds

                    SmoothWheel {
                        view: list
                    }

                    delegate: Column {
                        id: group
                        required property var modelData             // the app's name
                        readonly property var info: win.groups.find(g => g.app === modelData) ?? { app: modelData, items: [] }
                        width: list.width
                        spacing: 8

                        // "App · N", and clear just these
                        Item {
                            width: parent.width
                            height: 22
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 7; height: 7; radius: 4; color: Theme.accent3 }
                            FText {
                                x: 14
                                anchors.verticalCenter: parent.verticalCenter
                                text: group.info.app + " · " + group.info.items.length
                                color: Theme.accent3
                                font.weight: Font.Bold
                                font.pixelSize: Theme.fsSm
                            }
                            FIconButton {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                icon: "close"
                                size: 24
                                iconSize: 15
                                onClicked: group.info.items.forEach(n => Notifs.dismiss(n.nid))
                            }
                        }
                        Repeater {
                            model: group.info.items
                            NotificationCard {
                                required property var modelData
                                width: group.width
                                stripe: true
                                nid: modelData.nid
                                appName: modelData.appName
                                appIcon: modelData.appIcon
                                image: modelData.image
                                summary: modelData.summary
                                body: modelData.body
                                urgency: modelData.urgency
                                time: modelData.time
                                timeout: modelData.timeout
                                actionsJson: modelData.actionsJson
                            }
                        }
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        visible: Notifs.history.count === 0
                        spacing: 6
                        FIcon { Layout.alignment: Qt.AlignHCenter; icon: Notifs.dnd ? "notifications_paused" : "done_all"; size: 40; color: Theme.accent }
                        FText { Layout.alignment: Qt.AlignHCenter; text: I18n.tr("You're all caught up"); font.weight: Font.DemiBold }
                        FText { Layout.alignment: Qt.AlignHCenter; text: Notifs.dnd ? I18n.tr("Do not disturb is on") : I18n.tr("New notifications show up here"); dim: true; font.pixelSize: Theme.fsSm }
                    }
                }
            }
        }
    }
}
