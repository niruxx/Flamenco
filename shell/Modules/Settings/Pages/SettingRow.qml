import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

// Label + description on the left, control on the right.
Item {
    id: root
    property string title
    property string subtitle
    property string icon
    default property alias control: slot.data

    Layout.fillWidth: true
    implicitHeight: Math.max(60, lay.implicitHeight + 24)

    RowLayout {
        id: lay
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 14

        FIcon {
            visible: root.icon !== ""
            icon: root.icon
            color: Theme.textDim
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            FText { Layout.fillWidth: true; text: root.title; font.weight: Font.Medium; wrapMode: Text.Wrap }
            FText { Layout.fillWidth: true; visible: text !== ""; text: root.subtitle; dim: true; font.pixelSize: Theme.fsSm; wrapMode: Text.Wrap }
        }
        Item {
            id: slot
            Layout.preferredWidth: childrenRect.width
            Layout.preferredHeight: childrenRect.height
        }
    }
}
