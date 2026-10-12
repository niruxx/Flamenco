import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

// Shared frame for control-center sub pages.
ColumnLayout {
    id: root
    property string title
    property alias headerExtra: extra.data
    default property alias body: bodyCol.data
    signal back

    spacing: Theme.sp3

    RowLayout {
        Layout.fillWidth: true
        FIconButton { icon: "arrow_back"; onClicked: root.back() }
        FText {
            Layout.fillWidth: true
            text: root.title
            font.pixelSize: Theme.fsLg
            font.weight: Font.Bold
        }
        Row { id: extra; spacing: 4 }
    }

    FScroll {
        Layout.fillWidth: true
        Layout.fillHeight: true
        contentHeight: bodyCol.implicitHeight
        ColumnLayout {
            id: bodyCol
            width: parent.width
            spacing: 6
        }
    }
}
