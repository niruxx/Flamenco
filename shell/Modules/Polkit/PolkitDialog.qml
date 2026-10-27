import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services
import qs.Widgets

// "Authentication is required…": the password dialog apps (and Flamenco's own
// admin actions) ask for through polkit, on the screen you're using, over a dimmed
// desktop. Enter authenticates, Esc cancels. A wrong password shakes it and says so;
// with a fingerprint reader set up for polkit, touching it works too.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win

        required property ShellScreen modelData
        readonly property var flow: PolkitAuth.flow
        readonly property bool here: modelData.name === Panels.targetScreen("")
        readonly property bool waiting: PolkitAuth.active && !(flow?.isResponseRequired ?? true)
        property bool busy: false

        screen: modelData
        visible: PolkitAuth.active && here
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "flamenco-polkit"
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        onVisibleChanged: {
            busy = false;
            field.text = "";
            if (visible)
                focusSoon.restart();
        }
        Timer {
            id: focusSoon
            interval: 50
            onTriggered: field.focusInput()
        }
        Connections {
            target: win.flow
            enabled: win.flow !== null
            function onAuthenticationFailed() {
                win.busy = false;
                field.text = "";
                shake.restart();
                field.focusInput();
            }
            function onIsResponseRequiredChanged() {
                if (win.flow.isResponseRequired) {
                    win.busy = false;
                    field.focusInput();
                }
            }
        }
        function submit() {
            if (busy || !flow)
                return;
            busy = true;
            PolkitAuth.submit(field.text);
            field.text = "";
        }

        // the desktop, dimmed; a click outside does nothing (cancel is a choice)
        Rectangle {
            anchors.fill: parent
            color: Theme.alpha(Theme.shadow, 0.45)
            MouseArea { anchors.fill: parent }
        }

        Rectangle {
            id: card
            anchors.centerIn: parent
            width: Math.min(440, parent.width - 48)
            height: col.implicitHeight + Theme.sp5 * 2
            radius: Theme.rXl
            color: Theme.popupBg
            border.width: 1
            border.color: Theme.alpha(Theme.border, 0.7)
            Finish {}

            transform: Translate { id: nudge }
            SequentialAnimation {
                id: shake
                NumberAnimation { target: nudge; property: "x"; to: -14; duration: 50 }
                NumberAnimation { target: nudge; property: "x"; to: 12; duration: 70 }
                NumberAnimation { target: nudge; property: "x"; to: -8; duration: 60 }
                NumberAnimation { target: nudge; property: "x"; to: 0; duration: 60 }
            }

            ColumnLayout {
                id: col
                x: Theme.sp5
                y: Theme.sp5
                width: parent.width - Theme.sp5 * 2
                spacing: Theme.sp3

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 56
                    implicitHeight: 56
                    radius: 18
                    color: Theme.alpha(Theme.accent, 0.16)
                    FIcon {
                        anchors.centerIn: parent
                        icon: win.waiting ? "fingerprint" : "admin_panel_settings"
                        size: 30
                        fill: 1
                        color: Theme.accent
                    }
                }
                FText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Authentication required"
                    font.pixelSize: Theme.fsLg
                    font.weight: Font.Bold
                }
                FText {
                    Layout.fillWidth: true
                    text: win.flow?.message ?? ""
                    horizontalAlignment: Text.AlignHCenter
                    dim: true
                    wrapMode: Text.Wrap
                }
                // who answers, when it isn't obvious
                FText {
                    Layout.fillWidth: true
                    visible: text !== ""
                    readonly property var who: win.flow?.selectedIdentity ?? null
                    text: who && who.string && who.string !== Quickshell.env("USER") ? "As " + who.string : ""
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Theme.fsSm
                }

                FTextField {
                    id: field
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.sp2
                    icon: "key"
                    password: !(win.flow?.responseVisible ?? false)
                    placeholder: (win.flow?.inputPrompt ?? "").replace(/[\s:]+$/, "") || "Password"
                    border.color: PolkitAuth.failed ? Theme.error : input.activeFocus ? Theme.accent : Theme.border
                    onAccepted: win.submit()
                    onKeyPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            PolkitAuth.cancel();
                            event.accepted = true;
                        }
                    }
                }
                FText {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: win.waiting ? "Touch the fingerprint reader, or type your password"
                        : (win.flow?.supplementaryMessage ?? "") !== "" ? win.flow.supplementaryMessage
                        : PolkitAuth.failed ? "That didn't work. Try again" : ""
                    color: PolkitAuth.failed || (win.flow?.supplementaryIsError ?? false) ? Theme.error : Theme.textDim
                    font.pixelSize: Theme.fsSm
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.sp2
                    spacing: Theme.sp2
                    Item { Layout.fillWidth: true }
                    FButton {
                        text: "Cancel"
                        variant: "tonal"
                        onClicked: PolkitAuth.cancel()
                    }
                    FButton {
                        text: win.busy ? "Checking…" : "Authenticate"
                        icon: "lock_open"
                        disabled: win.busy || field.text === ""
                        onClicked: win.submit()
                    }
                }
            }
        }
    }
}
