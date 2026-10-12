import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Commons
import qs.Services
import qs.Widgets

// Fullscreen session menu with staggered button entrance + keyboard nav.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win

        required property ShellScreen modelData
        readonly property bool shouldShow: Panels.current === "power" && Panels.screen === modelData.name
        readonly property real p: pAnim.v
        property int sel: 0
        // destructive actions arm a 5 s countdown instead of running at once
        property string pending: ""
        property real charge: 0          // 0 → 1 over the countdown
        readonly property int remaining: Math.max(1, Math.ceil(5 * (1 - charge)))
        readonly property var pendingAction: actions.find(a => a.id === pending) ?? null

        readonly property var actions: [
            { id: "lock", icon: "lock", label: "Lock", run: () => Quickshell.execDetached([Paths.bin, "lock"]) },
            { id: "suspend", icon: "bedtime", label: "Suspend", run: () => { Quickshell.execDetached([Paths.bin, "lock"]); suspendDelay.start(); } },
            { id: "logout", icon: "logout", label: "Log out", verb: "Logging out", run: () => Power.logout() },
            { id: "reboot", icon: "restart_alt", label: "Restart", verb: "Restarting", run: () => Power.reboot() },
            { id: "shutdown", icon: "power_settings_new", label: "Shut down", verb: "Shutting down", run: () => Power.shutdown() }
        ]

        function cancel() {
            countdown.stop();
            pending = "";
            charge = 0;
        }

        function trigger(i) {
            const a = actions[i];
            if (a.verb) {
                // clicking the counting-down button again cancels it
                if (pending === a.id) {
                    cancel();
                    return;
                }
                pending = a.id;
                charge = 0;
                countdown.restart();
                return;
            }
            cancel();
            Panels.close();
            a.run();
        }

        // real 5 s regardless of the animation speed setting
        NumberAnimation {
            id: countdown
            target: win
            property: "charge"
            from: 0
            to: 1
            duration: 5000
            easing.type: Easing.Linear
            onFinished: {
                const a = win.pendingAction;
                win.pending = "";
                Panels.close();
                // the logout animation covers the screen first, then the action runs
                if (a)
                    SessionFx.playOutro(a.verb + "…", a.run, false);
            }
        }
        onShouldShowChanged: {
            cancel();
            if (shouldShow) {
                sel = 0;
                stagger.restart();
                focusItem.forceActiveFocus();
            }
        }

        Timer { id: suspendDelay; interval: 600; onTriggered: Power.suspend() }

        screen: modelData
        visible: shouldShow || p > 0.01
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "flamenco-power"

        // animated value lives on an Item: Behaviors on the window itself crash Qt 6.12
        Item {
            id: pAnim
            property real v: shouldShow ? 1 : 0
            Behavior on v { Anim { duration: Theme.durLong; easing.bezierCurve: Theme.curves.emphasizedDecel } }
        }
        WlrLayershell.keyboardFocus: shouldShow ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        Rectangle {
            anchors.fill: parent
            color: Theme.alpha(Theme.bg, 0.72)
            opacity: win.p
            MouseArea { anchors.fill: parent; onClicked: win.pending ? win.cancel() : Panels.close() }
        }

        Item {
            id: focusItem
            focus: true
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape)
                    win.pending ? win.cancel() : Panels.close();
                else if (event.key === Qt.Key_Left || event.key === Qt.Key_H)
                    win.sel = (win.sel + win.actions.length - 1) % win.actions.length;
                else if (event.key === Qt.Key_Right || event.key === Qt.Key_L || event.key === Qt.Key_Tab)
                    win.sel = (win.sel + 1) % win.actions.length;
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space)
                    win.trigger(win.sel);
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Theme.sp6
            opacity: win.p

            FText {
                Layout.alignment: Qt.AlignHCenter
                text: win.pendingAction ? win.pendingAction.verb + " in " + win.remaining + "…" : "Goodbye, " + Paths.user
                font.pixelSize: Theme.fsXxl
                font.weight: Font.Bold
            }

            FText {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: -Theme.sp5
                text: "Click it again or press Esc to cancel"
                dim: true
                opacity: win.pending ? 1 : 0
                Behavior on opacity { Anim {} }
            }

            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: Theme.sp4

                Repeater {
                    id: rep
                    model: win.actions

                    Rectangle {
                        id: btn
                        required property var modelData
                        required property int index
                        readonly property bool selected: win.sel === index
                        readonly property bool danger: win.pending === modelData.id
                        property real enter: 0

                        width: 128
                        height: 140
                        radius: selected ? Theme.rXl * 1.4 : Theme.rXl
                        color: danger ? Theme.alpha(Theme.error, 0.25) : selected ? Theme.accent : Theme.panelBg
                        border.width: 1
                        border.color: Theme.alpha(Theme.border, 0.6)
                        opacity: enter
                        scale: (0.6 + 0.4 * enter) * (selected ? 1.06 : 1)
                        transform: Translate { y: (1 - btn.enter) * 60 }

                        Behavior on color { CAnim {} }
                        Behavior on radius { Anim { easing.bezierCurve: Theme.curves.spring } }

                        // countdown: fills from the bottom, with a pulsing edge
                        ClippingRectangle {
                            anchors.fill: parent
                            radius: btn.radius
                            color: "transparent"
                            visible: btn.danger

                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width
                                height: parent.height * win.charge
                                color: Theme.error

                                Rectangle {
                                    anchors.top: parent.top
                                    width: parent.width
                                    height: 3
                                    color: Theme.onAccent
                                    SequentialAnimation on opacity {
                                        running: btn.danger
                                        loops: Animation.Infinite
                                        NumberAnimation { to: 0.2; duration: 400 }
                                        NumberAnimation { to: 0.8; duration: 400 }
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: Theme.sp3
                            FIcon {
                                Layout.alignment: Qt.AlignHCenter
                                icon: btn.modelData.icon
                                size: 44
                                fill: btn.selected ? 1 : 0
                                color: btn.selected || btn.danger ? Theme.onAccent : Theme.text
                            }
                            FText {
                                Layout.alignment: Qt.AlignHCenter
                                text: btn.danger ? "Cancel · " + win.remaining + "s" : btn.modelData.label
                                font.weight: Font.DemiBold
                                color: btn.selected || btn.danger ? Theme.onAccent : Theme.text
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: win.sel = btn.index
                            onClicked: win.trigger(btn.index)
                        }

                        SequentialAnimation {
                            id: entry
                            PropertyAction { target: btn; property: "enter"; value: 0 }
                            PauseAnimation { duration: Theme.dur(45) * btn.index }
                            NumberAnimation { target: btn; property: "enter"; to: 1; duration: Theme.durLong; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curves.spring }
                        }
                        Connections {
                            target: stagger
                            function onTriggered() { entry.restart(); }
                        }
                    }
                }
            }
        }

        Timer { id: stagger; interval: 1 }
    }
}
