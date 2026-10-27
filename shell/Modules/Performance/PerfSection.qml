import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

FCard {
    id: section
    default property alias body: sectionCol.data
    property string title
    property string icon
    property string action: ""               // a button at the right of the title
    signal actionClicked

    Layout.fillWidth: true
    implicitHeight: sectionCol.implicitHeight + Theme.sp4 * 2

    ColumnLayout {
        id: sectionCol
        anchors.fill: parent
        anchors.margins: Theme.sp4
        spacing: Theme.sp2
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            FIcon { icon: section.icon; size: 18; color: Theme.accent }
            FText { Layout.fillWidth: true; text: section.title; font.weight: Font.Bold }
            FButton { visible: section.action !== ""; text: section.action; variant: "text"; implicitHeight: 28; onClicked: section.actionClicked() }
        }
    }
}
