import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

// Network: where you're connected, down and up speeds now, and the last two
// minutes as a graph.
ColumnLayout {
    id: root
    property real k: 1
    property var spec
    property bool editing: false
    implicitWidth: Math.round(260 * k)
    spacing: Math.round(Theme.sp2 * k)

    RowLayout {
        spacing: Math.round(8 * root.k)
        FIcon { icon: Network.icon; size: Math.round(20 * root.k); fill: 1; color: Theme.accent }
        FText { Layout.fillWidth: true; text: Network.label; font.weight: Font.DemiBold; font.pixelSize: Math.round(Theme.fsMd * root.k); elide: Text.ElideRight }
    }
    RowLayout {
        spacing: Math.round(Theme.sp4 * root.k)
        Repeater {
            model: [{ icon: "arrow_downward", v: SystemStats.netDown, c: Theme.accent }, { icon: "arrow_upward", v: SystemStats.netUp, c: Theme.accent3 }]
            Row {
                required property var modelData
                spacing: Math.round(4 * root.k)
                FIcon { anchors.verticalCenter: parent.verticalCenter; icon: parent.modelData.icon; size: Math.round(16 * root.k); color: parent.modelData.c }
                FText { anchors.verticalCenter: parent.verticalCenter; text: SystemStats.formatBytes(parent.modelData.v, true); mono: true; font.pixelSize: Math.round(Theme.fsMd * root.k) }
            }
        }
    }
    FSparkline {
        Layout.fillWidth: true
        implicitHeight: Math.round(46 * root.k)
        values: SystemStats.netHistory
        max: Math.max(1, ...SystemStats.netHistory)
        color: Theme.accent
    }
}
