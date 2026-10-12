import QtQuick
import QtQuick.Layouts
import qs.Commons

Rectangle {
    id: root

    property alias text: input.text
    property alias input: input
    property string placeholder: ""
    property string icon: ""
    property bool password: false
    property int fontSize: Theme.fsMd

    signal accepted
    signal edited(string text)
    signal keyPressed(var event)
    signal editingFinished

    implicitHeight: 42
    implicitWidth: 240
    radius: Theme.rMd
    color: Theme.surfaceHighest
    border.width: input.activeFocus ? 2 : 1
    border.color: input.activeFocus ? Theme.accent : Theme.border

    Behavior on border.color { CAnim {} }

    function focusInput() {
        input.forceActiveFocus();
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 8

        FIcon {
            visible: root.icon !== ""
            icon: root.icon
            color: input.activeFocus ? Theme.accent : Theme.textDim
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            TextInput {
                id: input
                anchors.fill: parent
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.text
                selectionColor: Theme.accent
                selectedTextColor: Theme.onAccent
                font.family: Theme.fontFamily
                font.pixelSize: root.fontSize
                echoMode: root.password ? TextInput.Password : TextInput.Normal
                clip: true
                onAccepted: root.accepted()
                onTextEdited: root.edited(text)
                Keys.onPressed: event => root.keyPressed(event)
                onEditingFinished: root.editingFinished()
            }

            FText {
                anchors.fill: parent
                text: root.placeholder
                dim: true
                visible: input.text === ""
                opacity: input.activeFocus ? 0.6 : 1
            }
        }
    }
}
