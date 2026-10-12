import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Rectangle {
    id: sec

    property var ids: []
    property var registry: ({})
    property bool islands: false

    implicitWidth: row.implicitWidth + (islands ? 12 : 0)
    radius: islands ? Theme.rLg : 0
    color: islands ? Theme.barBg : "transparent"
    visible: ids.length > 0 && row.implicitWidth > 0

    Behavior on implicitWidth { Anim { easing.bezierCurve: Theme.curves.emphasizedDecel } }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Repeater {
            model: sec.ids
            delegate: Loader {
                required property string modelData
                Layout.alignment: Qt.AlignVCenter
                sourceComponent: sec.registry[modelData] ?? null
                // widgets set `barVisible` (not `visible`) so a hidden one frees its slot
                visible: item !== null && (item.barVisible ?? true)
            }
        }
    }
}
