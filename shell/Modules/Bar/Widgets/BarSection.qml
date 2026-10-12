import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

// One bar section (start / center / end). Lays widgets out in a row, or a
// column when the bar is vertical.
Rectangle {
    id: sec

    property var ids: []
    property var registry: ({})
    property bool islands: false
    property bool vertical: false

    readonly property int cross: Theme.barHeight

    implicitWidth: vertical ? cross : grid.implicitWidth + (islands ? 12 : 0)
    implicitHeight: vertical ? grid.implicitHeight + (islands ? 12 : 0) : cross
    width: implicitWidth
    height: implicitHeight
    radius: islands ? Theme.rLg : 0
    color: islands ? Theme.barBg : "transparent"
    visible: ids.length > 0 && (vertical ? grid.implicitHeight : grid.implicitWidth) > 0

    Behavior on implicitWidth { enabled: !sec.vertical; Anim { easing.bezierCurve: Theme.curves.emphasizedDecel } }
    Behavior on implicitHeight { enabled: sec.vertical; Anim { easing.bezierCurve: Theme.curves.emphasizedDecel } }

    GridLayout {
        id: grid
        anchors.centerIn: parent
        flow: sec.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
        rowSpacing: 4
        columnSpacing: 4

        Repeater {
            model: sec.ids
            delegate: Loader {
                required property string modelData
                Layout.alignment: Qt.AlignCenter
                sourceComponent: sec.registry[modelData] ?? null
                // widgets set `barVisible` (not `visible`) so a hidden one frees its slot
                visible: item !== null && (item.barVisible ?? true)
            }
        }
    }
}
