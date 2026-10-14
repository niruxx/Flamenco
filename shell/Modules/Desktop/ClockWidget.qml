import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

// The time, large, and the date under it.
ColumnLayout {
    id: root
    property real k: 1
    property var spec
    property bool editing: false
    spacing: Math.round(2 * k)

    Row {
        Layout.alignment: Qt.AlignHCenter
        spacing: Math.round(6 * root.k)
        FText {
            id: hm
            text: Qt.formatDateTime(Time.now, Time.use24h ? "HH:mm" : "h:mm")
            font.pixelSize: Math.round(76 * root.k)
            font.weight: Font.Light
            font.letterSpacing: -2
        }
        FText {
            visible: !Time.use24h
            anchors.baseline: hm.baseline
            text: Qt.formatDateTime(Time.now, "AP")
            font.pixelSize: Math.round(20 * root.k)
            dim: true
        }
    }
    FText {
        Layout.alignment: Qt.AlignHCenter
        text: Time.date
        font.pixelSize: Math.round(Theme.fsLg * root.k)
        color: Theme.accent
        font.weight: Font.Medium
    }
}
