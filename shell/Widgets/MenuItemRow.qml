import QtQuick
import QtQuick.Layouts
import qs.Commons

// A row in one of the shell's menus (the desktop's right-click menu…): an icon,
// a label, and optionally a hint on the right.
Rectangle {
    id: mr
    property string label
    property string leadIcon: ""
    property string hint: ""
    property bool danger: false
    signal activated

    Layout.fillWidth: true
    implicitHeight: 34
    radius: Theme.rSm
    color: "transparent"
    opacity: enabled ? 1 : 0.45

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 12
        FIcon {
            visible: mr.leadIcon !== ""
            icon: mr.leadIcon
            size: 18
            color: mr.danger ? Theme.error : Theme.text
        }
        FText {
            Layout.fillWidth: true
            text: mr.label
            color: mr.danger ? Theme.error : Theme.text
            elide: Text.ElideRight
        }
        FText {
            visible: mr.hint !== ""
            text: mr.hint
            dim: true
            font.pixelSize: Theme.fsXs
        }
    }

    StateLayer {
        disabled: !mr.enabled
        onClicked: mr.activated()
    }
}
