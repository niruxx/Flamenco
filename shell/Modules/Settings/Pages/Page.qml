import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

// A settings page on the settings window's panel: a large, light title and a
// line on what it's for, then its groups of rounded rows. (`pageIcon` /
// `pageTint` are still set by the window, for pages that use them.)
FScroll {
    id: root
    property string title
    property string subtitle
    property string pageIcon: ""
    property color pageTint: Theme.accent
    default property alias body: col.data

    contentHeight: col.implicitHeight + 72

    ColumnLayout {
        id: col
        width: Math.min(820, root.width - 48)
        x: 24
        y: 22
        spacing: Theme.sp4

        // hero
        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: Theme.sp2
            spacing: 16
            Rectangle {
                visible: false
                Layout.preferredWidth: 52
                Layout.preferredHeight: 52
                Layout.alignment: Qt.AlignTop
                radius: 15
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.lighter(root.pageTint, 1.18) }
                    GradientStop { position: 1; color: root.pageTint }
                }
                FIcon { anchors.centerIn: parent; icon: root.pageIcon; size: 30; fill: 1; color: "#ffffff" }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                FText {
                    text: root.title
                    font.pixelSize: Math.round(Theme.fsXxl * 1.1)
                    font.weight: Font.Normal
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
