import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

// Multi-line monospace editor bound to a settings key. Saves on focus loss / Ctrl+S.
Rectangle {
    id: root
    property var target
    property string key
    property string placeholder

    Layout.fillWidth: true
    Layout.margins: 8
    implicitHeight: Math.max(140, edit.contentHeight + 28)
    radius: Theme.rMd
    color: Theme.bg
    border.width: edit.activeFocus ? 2 : 1
    border.color: edit.activeFocus ? Theme.accent : Theme.border

    function save() {
        if (target[key] !== edit.text)
            target[key] = edit.text;
    }

    TextEdit {
        id: edit
        anchors.fill: parent
        anchors.margins: 14
        text: root.target[root.key]
        color: Theme.text
        selectionColor: Theme.accent
        selectedTextColor: Theme.onAccent
        font.family: Theme.monoFamily
        font.pixelSize: Theme.fsSm
        wrapMode: TextEdit.Wrap
        selectByMouse: true
        onActiveFocusChanged: if (!activeFocus) root.save()
        Keys.onPressed: event => {
            if (event.key === Qt.Key_S && event.modifiers & Qt.ControlModifier) {
                root.save();
                event.accepted = true;
            }
        }
    }

    FText {
        anchors.fill: edit
        verticalAlignment: Text.AlignTop
        visible: edit.text === ""
        text: root.placeholder
        mono: true
        dim: true
        opacity: 0.6
        font.pixelSize: Theme.fsSm
    }
}
