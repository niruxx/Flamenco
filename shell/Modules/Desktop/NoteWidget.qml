import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

// A note typed right on the desktop; saved as you type.
ColumnLayout {
    id: root
    property real k: 1
    property var spec
    property bool editing: false
    spacing: Math.round(Theme.sp2 * k)
    width: Math.round(250 * k)

    FText {
        text: "Note"
        color: Theme.accent
        font.weight: Font.DemiBold
        font.pixelSize: Math.round(Theme.fsSm * root.k)
    }
    Item {
        Layout.fillWidth: true
        implicitHeight: Math.max(Math.round(110 * root.k), edit.contentHeight)
        TextEdit {
            cursorDelegate: Component { Caret {} }
            id: edit
            anchors.fill: parent
            readOnly: root.editing
            wrapMode: TextEdit.Wrap
            selectByMouse: true
            color: Theme.text
            selectionColor: Theme.alpha(Theme.accent, 0.4)
            font.family: Theme.fontFamily
            font.pixelSize: Math.round(Theme.fsMd * root.k)
            text: root.spec?.text ?? ""
            // save a moment after typing stops
            onTextChanged: if (activeFocus) save.restart()
            onActiveFocusChanged: if (!activeFocus && root.spec && text !== root.spec.text) Desk.update(root.spec.id, { text: text })
        }
        FText {
            visible: edit.text === "" && !edit.activeFocus
            text: root.editing ? "Type here once you're done arranging" : "Click to type…"
            dim: true
            font.pixelSize: Math.round(Theme.fsMd * root.k)
        }
        Timer {
            id: save
            interval: 800
            onTriggered: if (root.spec && edit.text !== root.spec.text) Desk.update(root.spec.id, { text: edit.text })
        }
    }
}
