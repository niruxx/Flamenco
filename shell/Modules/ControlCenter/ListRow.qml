import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Rectangle {
    id: root
    property string icon
    property string title
    property string subtitle
    property bool selected: false
    property bool busy: false
    default property alias trailing: trail.data
    signal clicked

    Layout.fillWidth: true
    implicitHeight: 54
    radius: Theme.rMd
    color: selected ? Theme.alpha(Theme.accent, 0.16) : Theme.surfaceHigh
    Behavior on color { CAnim {} }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 10
        spacing: 12

        FIcon {
            icon: root.icon
            color: root.selected ? Theme.accent : Theme.text
            fill: root.selected ? 1 : 0
            RotationAnimation on rotation {
                running: root.busy
                from: 0; to: 360; duration: 1000; loops: Animation.Infinite
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            FText { Layout.fillWidth: true; text: root.title; elide: Text.ElideRight; font.weight: root.selected ? Font.Bold : Font.Normal }
            FText { Layout.fillWidth: true; visible: text !== ""; text: root.subtitle; dim: true; font.pixelSize: Theme.fsXs; elide: Text.ElideRight }
        }
        Row { id: trail; spacing: 4 }
    }

    StateLayer {
        z: -1
        onClicked: root.clicked()
    }
}
