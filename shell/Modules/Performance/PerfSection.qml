import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

FCard {
    id: section
    default property alias body: sectionCol.data
    property string title
    property string icon

    Layout.fillWidth: true
    implicitHeight: sectionCol.implicitHeight + Theme.sp4 * 2

    ColumnLayout {
        id: sectionCol
        anchors.fill: parent
        anchors.margins: Theme.sp4
        spacing: Theme.sp2
        RowLayout {
            spacing: 8
            FIcon { icon: section.icon; size: 18; color: Theme.accent }
            FText { text: section.title; font.weight: Font.Bold }
        }
    }
}
