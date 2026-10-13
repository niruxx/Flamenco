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
        // destructive actions run only after being held down for holdMs
        readonly property int holdMs: 3000
        property string pending: ""
        property real charge: 0          // 0 → 1 while held
        readonly property int remaining: Math.max(1, Math.ceil(holdMs / 1000 * (1 - charge)))
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
            release.stop();
            pending = "";
            charge = 0;
        }

        // click (or Enter) on a harmless action runs it at once
        function trigger(i) {
            const a = actions[i];
            if (a.verb)
                return;
            cancel();
            Panels.close();
            a.run();
        }

        // press on a destructive action starts filling it; letting go early drains it
        function holdStart(i) {
            const a = actions[i];
            if (!a.verb)
                return;
            release.stop();
            pending = a.id;
            countdown.from = charge;
            countdown.duration = Math.max(1, holdMs * (1 - charge));
            countdown.restart();
        }

        function holdEnd() {
            if (!countdown.running)
                return;
            countdown.stop();
            release.restart();
        }

        // real 3 s regardless of the animation speed setting
        NumberAnimation {
            id: countdown
            target: win
            property: "charge"
            to: 1
            easing.type: Easing.Linear
            onFinished: {
                if (win.charge < 1)
                    return;     // stopped early by holdEnd()
                const a = win.pendingAction;
                win.pending = "";
                win.charge = 0;
                Panels.close();
                // the logout animation covers the screen first, then the action runs
                if (a)
                    SessionFx.playOutro(a.verb + "…", a.run, false);
            }
        }
        SequentialAnimation {
            id: release
            NumberAnimation { target: win; property: "charge"; to: 0; duration: 250; easing.type: Easing.OutCubic }
            PropertyAction { target: win; property: "pending"; value: "" }
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
            MouseArea { anchors.fill: parent; onClicked: Panels.close() }
        }

        Item {
            id: focusItem
            focus: true
            readonly property var confirmKeys: [Qt.Key_Return, Qt.Key_Enter, Qt.Key_Space]
            Keys.onPressed: event => {
                if (event.isAutoRepeat)
                    return;
                if (event.key === Qt.Key_Escape) {
                    win.pending ? win.cancel() : Panels.close();
                } else if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
                    win.holdEnd();
                    win.sel = (win.sel + win.actions.length - 1) % win.actions.length;
                } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L || event.key === Qt.Key_Tab) {
                    win.holdEnd();
                    win.sel = (win.sel + 1) % win.actions.length;
                } else if (confirmKeys.includes(event.key)) {
                    win.trigger(win.sel);
                    win.holdStart(win.sel);
                }
            }
            Keys.onReleased: event => {
                if (!event.isAutoRepeat && confirmKeys.includes(event.key))
                    win.holdEnd();
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
                text: win.pending ? "Let go to cancel" : "Hold Log out, Restart or Shut down for 3 seconds"
                dim: true
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
                                text: btn.danger ? win.remaining + "s" : btn.modelData.label
                                font.weight: Font.DemiBold
                                color: btn.selected || btn.danger ? Theme.onAccent : Theme.text
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: win.sel = btn.index
                            onPressed: {
                                win.sel = btn.index;
                                win.holdStart(btn.index);
                            }
                            onReleased: win.holdEnd()
                            onCanceled: win.holdEnd()
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
