import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

// Scrollable settings page with a title.
FScroll {
    id: root
    property string title
    property string subtitle
    default property alias body: col.data

    contentHeight: col.implicitHeight + 64

    ColumnLayout {
        id: col
        x: 40
        y: 32
        width: Math.min(760, root.width - 80)
        spacing: Theme.sp4

        FText {
            text: root.title
            font.pixelSize: Theme.fsXxl
            font.weight: Font.Bold
        }
        FText {
            Layout.fillWidth: true
            visible: text !== ""
            text: root.subtitle
            dim: true
            wrapMode: Text.Wrap
            Layout.bottomMargin: Theme.sp2
        }
    }
}
