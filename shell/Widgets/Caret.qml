import QtQuick
import qs.Commons

// The text cursor in the shell's text fields, in the caret color (Appearance →
// Text cursor). Use it as a TextInput's or TextEdit's cursorDelegate:
//   cursorDelegate: Component { Caret {} }
// It blinks like the standard one, and stays lit while you type or move it.
Rectangle {
    id: root
    readonly property Item input: parent
    width: Math.max(2, Math.round(2 * Theme.scale))
    height: input ? input.cursorRectangle.height : 16
    radius: width / 2
    color: Theme.caret
    visible: input ? input.cursorVisible : false
    opacity: blink.lit ? 1 : 0

    Timer {
        id: blink
        property bool lit: true
        interval: 530
        repeat: true
        running: root.visible
        onRunningChanged: lit = true
        onTriggered: lit = !lit
    }
    Connections {
        target: root.input
        function onCursorPositionChanged() {
            blink.lit = true;
            blink.restart();
        }
    }
}
