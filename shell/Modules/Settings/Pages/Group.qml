import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

// A titled card holding rows.
ColumnLayout {
    id: root
    property string title
    default property alias rows: card.data

    Layout.fillWidth: true
    spacing: Theme.sp2

    FText {
        visible: root.title !== ""
        text: root.title.toUpperCase()
        color: Theme.accent
        font.pixelSize: Theme.fsXs
        font.weight: Font.Bold
        font.letterSpacing: 1.2
        Layout.leftMargin: 4
        Layout.topMargin: Theme.sp2
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: card.implicitHeight + 8
        radius: Theme.rLg
        color: Theme.surface

        ColumnLayout {
            id: card
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 4
            spacing: 0
        }
    }
}
