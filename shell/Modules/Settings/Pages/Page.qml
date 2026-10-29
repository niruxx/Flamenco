import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

// A centered settings page with a prominent title and a
// line on what it's for, then its groups of rounded rows. (`pageIcon` /
// `pageTint` are still set by the window, for pages that use them.)
FScroll {
    id: root
    property string title
    property string subtitle
    property string pageIcon: ""
    property color pageTint: Theme.accent
    default property alias body: col.data

    readonly property real pageInset: Math.min(Theme.sp5, width / 12)
    contentHeight: col.implicitHeight + Theme.sp6 * 2

    ColumnLayout {
        id: col
        width: Math.max(0, Math.min(Theme.pageMaxWidth, root.width - root.gutter - root.pageInset * 2))
        x: (root.width - root.gutter - width) / 2
        y: Theme.sp6
        spacing: Theme.sp4

        // hero
        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: Theme.sp2
            spacing: 16
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.sp2
                FText {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    text: root.title
                    font.pixelSize: Math.round(Theme.fsXxl * 1.1)
                    font.weight: Font.DemiBold
                }
                FText {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: root.subtitle
                    dim: true
                    wrapMode: Text.Wrap
                }
            }
        }
    }
}
