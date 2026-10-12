import QtQuick
import QtQuick.Layouts
import qs.Commons

// Click, then press a key combination. Produces niri key names ("Mod+Shift+S").
// Combinations niri already binds never reach the window, so they can also be typed.
Rectangle {
    id: root

    property string value: ""
    property bool recording: false
    signal recorded(string combo)

    implicitWidth: 300
    implicitHeight: 42
    radius: Theme.rMd
    color: recording ? Theme.alpha(Theme.accent, 0.12) : Theme.surfaceHighest
    border.width: recording ? 2 : 1
    border.color: recording ? Theme.accent : Theme.border

    Behavior on color { CAnim {} }

    // unshifted names, because niri matches keysyms with modifiers separately
    readonly property var names: ({
            [Qt.Key_Return]: "Return", [Qt.Key_Enter]: "Return", [Qt.Key_Space]: "Space", [Qt.Key_Escape]: "Escape",
            [Qt.Key_Tab]: "Tab", [Qt.Key_Backtab]: "Tab", [Qt.Key_Backspace]: "BackSpace", [Qt.Key_Delete]: "Delete",
            [Qt.Key_Insert]: "Insert", [Qt.Key_Home]: "Home", [Qt.Key_End]: "End", [Qt.Key_PageUp]: "Page_Up",
            [Qt.Key_PageDown]: "Page_Down", [Qt.Key_Left]: "Left", [Qt.Key_Right]: "Right", [Qt.Key_Up]: "Up",
            [Qt.Key_Down]: "Down", [Qt.Key_Comma]: "Comma", [Qt.Key_Less]: "Comma", [Qt.Key_Period]: "Period",
            [Qt.Key_Greater]: "Period", [Qt.Key_Slash]: "Slash", [Qt.Key_Question]: "Slash", [Qt.Key_Backslash]: "BackSlash",
            [Qt.Key_Bar]: "BackSlash", [Qt.Key_Minus]: "Minus", [Qt.Key_Underscore]: "Minus", [Qt.Key_Equal]: "Equal",
            [Qt.Key_Plus]: "Equal", [Qt.Key_BracketLeft]: "BracketLeft", [Qt.Key_BraceLeft]: "BracketLeft",
            [Qt.Key_BracketRight]: "BracketRight", [Qt.Key_BraceRight]: "BracketRight", [Qt.Key_Semicolon]: "Semicolon",
            [Qt.Key_Colon]: "Semicolon", [Qt.Key_Apostrophe]: "Apostrophe", [Qt.Key_QuoteDbl]: "Apostrophe",
            [Qt.Key_QuoteLeft]: "Grave", [Qt.Key_AsciiTilde]: "Grave", [Qt.Key_Exclam]: "1", [Qt.Key_At]: "2",
            [Qt.Key_NumberSign]: "3", [Qt.Key_Dollar]: "4", [Qt.Key_Percent]: "5", [Qt.Key_AsciiCircum]: "6",
            [Qt.Key_Ampersand]: "7", [Qt.Key_Asterisk]: "8", [Qt.Key_ParenLeft]: "9", [Qt.Key_ParenRight]: "0",
            [Qt.Key_Print]: "Print", [Qt.Key_Pause]: "Pause", [Qt.Key_ScrollLock]: "Scroll_Lock", [Qt.Key_Menu]: "Menu",
            [Qt.Key_VolumeUp]: "XF86AudioRaiseVolume", [Qt.Key_VolumeDown]: "XF86AudioLowerVolume",
            [Qt.Key_VolumeMute]: "XF86AudioMute", [Qt.Key_MicMute]: "XF86AudioMicMute",
            [Qt.Key_MediaPlay]: "XF86AudioPlay", [Qt.Key_MediaTogglePlayPause]: "XF86AudioPlay",
            [Qt.Key_MediaNext]: "XF86AudioNext", [Qt.Key_MediaPrevious]: "XF86AudioPrev",
            [Qt.Key_MonBrightnessUp]: "XF86MonBrightnessUp", [Qt.Key_MonBrightnessDown]: "XF86MonBrightnessDown",
            [Qt.Key_Calculator]: "XF86Calculator"
        })
    readonly property var modifierKeys: [Qt.Key_Shift, Qt.Key_Control, Qt.Key_Alt, Qt.Key_Meta, Qt.Key_Super_L, Qt.Key_Super_R, Qt.Key_AltGr, Qt.Key_CapsLock, Qt.Key_NumLock]

    function keyName(key) {
        if (key >= Qt.Key_A && key <= Qt.Key_Z)
            return String.fromCharCode(key);
        if (key >= Qt.Key_0 && key <= Qt.Key_9)
            return String.fromCharCode(key);
        if (key >= Qt.Key_F1 && key <= Qt.Key_F35)
            return "F" + (key - Qt.Key_F1 + 1);
        return names[key] ?? "";
    }

    function start() {
        recording = true;
        catcher.forceActiveFocus();
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 6
        spacing: 8

        FIcon {
            icon: root.recording ? "radio_button_checked" : "keyboard"
            color: root.recording ? Theme.accent : Theme.textDim
            SequentialAnimation on opacity {
                running: root.recording
                loops: Animation.Infinite
                NumberAnimation { to: 0.3; duration: 500 }
                NumberAnimation { to: 1; duration: 500 }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            FText {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.recording || root.value === ""
                text: root.recording ? "Press a key combination… (Esc to cancel)" : "Click to record"
                dim: true
            }
            FKeycaps {
                anchors.verticalCenter: parent.verticalCenter
                visible: !root.recording && root.value !== ""
                combo: root.value
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.recording ? (root.recording = false) : root.start()
    }

    Item {
        id: catcher
        focus: root.recording
        Keys.onPressed: event => {
            if (!root.recording)
                return;
            event.accepted = true;
            if (root.modifierKeys.includes(event.key))
                return;
            const mods = [];
            if (event.modifiers & Qt.MetaModifier)
                mods.push("Mod");
            if (event.modifiers & Qt.ControlModifier)
                mods.push("Ctrl");
            if (event.modifiers & Qt.AltModifier)
                mods.push("Alt");
            if (event.modifiers & Qt.ShiftModifier)
                mods.push("Shift");
            if (event.key === Qt.Key_Escape && mods.length === 0) {
                root.recording = false;
                return;
            }
            const name = root.keyName(event.key);
            if (!name)
                return;
            root.recording = false;
            root.recorded(mods.concat([name]).join("+"));
        }
        onActiveFocusChanged: if (!activeFocus) root.recording = false
    }
}
