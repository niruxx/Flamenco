import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

// A settings page: centered (like GNOME Settings), with its badge, title and a
// line on what it's for at the top, then its groups. The settings window sets
// `pageIcon` / `pageTint` from the sidebar.
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
        width: Math.min(720, root.width - 64)
        x: Math.max(32, (root.width - width) / 2)
        y: 24
        spacing: Theme.sp4

        // hero
        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: Theme.sp2
            spacing: 16
            Rectangle {
                visible: root.pageIcon !== ""
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
                    font.pixelSize: Theme.fsXxl
                    font.weight: Font.Bold
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
