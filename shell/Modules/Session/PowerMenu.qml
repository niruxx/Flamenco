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
        // destructive actions run only after being held down for their hold time
        // (Settings → Power → Power menu); 0 runs them on a click
        readonly property var pcfg: Settings.data.power
        function holdFor(a) {
            if (!a || !a.verb)
                return 0;
            const s = a.id === "logout" ? pcfg.holdLogout : a.id === "reboot" || a.id === "firmware" ? pcfg.holdReboot : pcfg.holdShutdown;
            return Math.max(0, Math.round((Number(s) || 0) * 1000));
        }
        readonly property int holdMs: Math.max(1, holdFor(pendingAction) || (pcfg.countdown ?? 0) * 1000)
        property string pending: ""
        property real charge: 0          // 0 → 1 while held
        readonly property int remaining: Math.max(1, Math.ceil(holdMs / 1000 * (1 - charge)))
        // the hint under the title: which actions need holding, and for how long
        readonly property string hint: {
            const held = actions.filter(a => holdFor(a) > 0);
            if (held.length === 0)
                return "Click an action";
            const secs = s => (s % 1000 === 0 ? s / 1000 : (s / 1000).toFixed(1)) + (s === 1000 ? " second" : " seconds");
            const same = held.every(a => holdFor(a) === holdFor(held[0]));
            const names = held.map(a => a.label);
            const list = names.length > 1 ? names.slice(0, -1).join(", ") + " or " + names[names.length - 1] : names[0];
            return same ? "Hold " + list + " for " + secs(holdFor(held[0])) : "Hold " + held.map(a => a.label + " (" + secs(holdFor(a)) + ")").join(", ");
        }
        readonly property var pendingAction: actions.find(a => a.id === pending) ?? null

        // the buttons; hibernate, firmware setup and switching user are optional (Settings → Power)
        readonly property var actions: [
            { id: "lock", icon: "lock", label: I18n.tr("Lock"), run: () => Quickshell.execDetached([Paths.bin, "lock"]) },
            { id: "suspend", icon: "bedtime", label: I18n.tr("Suspend"), run: () => { Quickshell.execDetached([Paths.bin, "lock"]); suspendDelay.start(); } }
        ].concat(pcfg.menuHibernate ? [{ id: "hibernate", icon: "downloading", label: I18n.tr("Hibernate"), run: () => { Quickshell.execDetached([Paths.bin, "lock"]); hibernateDelay.start(); } }] : [],
            pcfg.menuSwitchUser && Power.canSwitchUser ? [{ id: "switch", icon: "switch_account", label: I18n.tr("Switch user"), run: () => Power.switchUser() }] : [], [
            { id: "logout", icon: "logout", label: I18n.tr("Log out"), verb: I18n.tr("Logging out"), run: () => Power.logout() },
            { id: "reboot", icon: "restart_alt", label: I18n.tr("Restart"), verb: I18n.tr("Restarting"), run: () => Power.reboot() }
        ], pcfg.menuFirmware ? [{ id: "firmware", icon: "developer_board", label: I18n.tr("Firmware setup"), verb: I18n.tr("Restarting into firmware setup"), run: () => Power.rebootFirmware() }] : [], [
            { id: "shutdown", icon: "power_settings_new", label: I18n.tr("Shut down"), verb: I18n.tr("Shutting down"), run: () => Power.shutdown() }
        ])

        // run an action, after the goodbye screen; niri's own logout shows its prompt
        // instead (Settings → Lock & Login → Session), so nothing covers the screen if
        // you cancel it
        function finish(a) {
            if (a.id === "logout" && Settings.data.session.logout === "niri" && !Niri.hyprland)
                a.run();
            else
                SessionFx.playOutro(a.verb + "…", a.run, false);
        }

        function cancel() {
            countdown.stop();
            release.stop();
            pending = "";
            charge = 0;
        }

        // click (or Enter) on a harmless action, or one set to run instantly, runs it at once
        function trigger(i) {
            const a = actions[i];
            if (a.verb && holdFor(a) > 0)
                return;
            // a countdown first (Settings → Power → Countdown), which Esc or a click cancels
            if (a.verb && (pcfg.countdown ?? 0) > 0) {
                cancel();
                pending = a.id;
                countdown.from = 0;
                countdown.duration = pcfg.countdown * 1000;
                countdown.restart();
                return;
            }
            cancel();
            Panels.close();
            if (a.verb)
                win.finish(a);
            else
                a.run();
        }

        // press on a destructive action starts filling it; letting go early drains it
        function holdStart(i) {
            const a = actions[i];
            if (!a.verb || holdFor(a) === 0)
                return;
            release.stop();
            pending = a.id;
            countdown.from = charge;
            countdown.duration = Math.max(1, holdFor(a) * (1 - charge));
            countdown.restart();
        }

        function holdEnd() {
            // a countdown (not a hold) keeps going when the button is let go
            if (!countdown.running || holdFor(pendingAction) === 0)
                return;
            countdown.stop();
            release.restart();
        }

        // the real hold time, regardless of the animation speed setting
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
                    win.finish(a);
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
        Timer { id: hibernateDelay; interval: 600; onTriggered: Power.hibernate() }

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
            Behavior on v { Anim { motionRole: win.shouldShow ? "enter" : "exit"; area: "panels" } }
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
                } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Down) {
                    win.holdEnd();
                    const step = event.key === Qt.Key_Up ? -actionGrid.columns : actionGrid.columns;
                    win.sel = (win.sel + step + win.actions.length) % win.actions.length;
                } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L || event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                    win.holdEnd();
                    const backward = event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier));
                    win.sel = (win.sel + (backward ? -1 : 1) + win.actions.length) % win.actions.length;
                } else if (confirmKeys.includes(event.key)) {
                    win.trigger(win.sel);
                    win.holdStart(win.sel);
                } else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9 && event.key - Qt.Key_1 < win.actions.length) {
                    // number keys: that button
                    win.sel = event.key - Qt.Key_1;
                    win.trigger(win.sel);
                    win.holdStart(win.sel);
                }
            }
            Keys.onReleased: event => {
                if (!event.isAutoRepeat && (confirmKeys.includes(event.key) || event.key >= Qt.Key_1 && event.key <= Qt.Key_9))
                    win.holdEnd();
            }
        }

        FScroll {
            id: powerScroll
            anchors.fill: parent
            anchors.margins: Theme.edge
            contentHeight: powerContent.implicitHeight + Theme.sp5 * 2
            opacity: win.p

            ColumnLayout {
                id: powerContent
                width: Math.max(0, powerScroll.width - powerScroll.gutter)
                y: Math.max(Theme.sp5, (powerScroll.height - implicitHeight) / 2)
                spacing: Theme.sp6

                FText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    text: win.pendingAction ? win.pendingAction.verb + " in " + win.remaining + "…" : I18n.tr("Goodbye, ") + Paths.user
                    font.pixelSize: Theme.fsXxl
                    font.weight: Font.Bold
                }

                FText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    Layout.topMargin: -Theme.sp5
                    text: win.pending ? I18n.tr("Let go to cancel") : win.hint
                    dim: true
                }

                GridLayout {
                    id: actionGrid
                    Layout.alignment: Qt.AlignHCenter
                    columns: Math.max(1, Math.min(win.actions.length, Math.floor((powerContent.width + Theme.sp4) / (128 * Theme.scale + Theme.sp4))))
                    columnSpacing: Theme.sp4
                    rowSpacing: Theme.sp4

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

                            Layout.preferredWidth: Math.min(128 * Theme.scale, powerContent.width)
                            Layout.preferredHeight: Math.round(140 * Theme.scale)
                            radius: selected ? Theme.rXl * 1.4 : Theme.rXl
                            color: danger ? Theme.alpha(Theme.error, 0.25) : selected ? Theme.accent : Theme.panelBg
                            border.width: 1
                            border.color: Theme.alpha(Theme.border, 0.6)
                            opacity: enter
                            scale: Theme.spatialMotion("panels") ? (0.96 + 0.04 * enter) * (selected ? 1.03 : 1) : 1
                            transform: Translate { y: Theme.spatialMotion("panels") ? (1 - btn.enter) * Theme.sp5 : 0 }

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

                            Rectangle {
                                visible: btn.danger
                                anchors.centerIn: parent
                                width: actionLabels.implicitWidth + Theme.sp4
                                height: actionLabels.implicitHeight + Theme.sp3
                                radius: Theme.rMd
                                color: Theme.surfaceHigh
                            }

                            ColumnLayout {
                                id: actionLabels
                                anchors.centerIn: parent
                                spacing: Theme.sp3
                                FIcon {
                                    Layout.alignment: Qt.AlignHCenter
                                    icon: btn.modelData.icon
                                    size: 44
                                    fill: btn.selected ? 1 : 0
                                    color: btn.danger ? Theme.text : btn.selected ? Theme.onAccent : Theme.text
                                }
                                FText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: btn.danger ? win.remaining + "s" : btn.modelData.label
                                    font.weight: Font.DemiBold
                                    color: btn.danger ? Theme.text : btn.selected ? Theme.onAccent : Theme.text
                                }
                                // its number key
                                FText {
                                    Layout.alignment: Qt.AlignHCenter
                                    visible: btn.index < 9
                                    text: String(btn.index + 1)
                                    mono: true
                                    font.pixelSize: Theme.fsXs
                                    opacity: 0.55
                                    color: btn.danger ? Theme.textDim : btn.selected ? Theme.onAccent : Theme.textDim
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
                                PauseAnimation { duration: Theme.spatialMotion("panels") ? Theme.durA("panels", 25) * btn.index : 0 }
                                NumberAnimation { target: btn; property: "enter"; to: 1; duration: Theme.motionDuration("enter", "panels"); easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curves.emphasizedDecel }
                            }
                            Connections {
                                target: stagger
                                function onTriggered() { entry.restart(); }
                            }
                        }
                    }
                }
            }

        }

        onSelChanged: {
            if (!rep || !powerScroll)
                return;
            const button = rep.itemAt(sel);
            if (!button)
                return;
            const top = button.mapToItem(powerScroll.contentItem, 0, 0).y;
            const bottom = top + button.height;
            const desired = top < powerScroll.contentY ? top - Theme.sp3
                : bottom > powerScroll.contentY + powerScroll.height ? bottom - powerScroll.height + Theme.sp3
                : powerScroll.contentY;
            powerScroll.contentY = Math.max(0, Math.min(powerScroll.maxY, desired));
        }

        Timer { id: stagger; interval: 1 }
    }
}
