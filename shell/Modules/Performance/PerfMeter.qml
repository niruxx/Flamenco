import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: meter
    property string label
    property string detail
    property real value
    property color barColor: Theme.accent

    Layout.fillWidth: true
    spacing: 4

    RowLayout {
        Layout.fillWidth: true
        FText { text: meter.label; font.weight: Font.Medium; Layout.fillWidth: true; elide: Text.ElideRight }
        FText { text: meter.detail; dim: true; mono: true; font.pixelSize: Theme.fsSm }
    }
    Rectangle {
        Layout.fillWidth: true
        height: 6
        radius: 3
        color: Theme.surfaceHighest
        Rectangle {
            height: parent.height
            radius: 3
            width: parent.width * Math.max(0, Math.min(1, meter.value))
            color: meter.value > 0.9 ? Theme.error : meter.barColor
            Behavior on width { Anim { easing.bezierCurve: Theme.curves.emphasizedDecel } }
        }
    }
}
