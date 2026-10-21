import QtQuick
import qs.Commons
import qs.Services
import qs.Widgets

// Little bars that move with what's playing (cava). Shows while something plays.
Item {
    id: root

    property string screenName
    property int barLevel: 0
    property bool barVisible: Cava.available && Media.playing && barLevel < 2
    readonly property bool vertical: Theme.barVertical
    readonly property int count: 10
    readonly property int thick: Theme.barItem - 8

    implicitWidth: vertical ? thick : count * 4 + (count - 1) * 2
    implicitHeight: vertical ? count * 4 + (count - 1) * 2 : thick

    // cava only runs while a visualizer is showing
    Component.onCompleted: if (barVisible) Cava.users++
    onBarVisibleChanged: Cava.users += barVisible ? 1 : -1
    Component.onDestruction: if (barVisible) Cava.users--

    Grid {
        anchors.centerIn: parent
        columns: root.vertical ? 1 : root.count
        spacing: 2
        verticalItemAlignment: Grid.AlignBottom
        horizontalItemAlignment: Grid.AlignLeft
        Repeater {
            model: root.count
            Rectangle {
                required property int index
                // spread cava's bars over ours
                readonly property real v: Cava.values.length ? Cava.values[Math.floor(index * Cava.values.length / root.count)] : 0
                width: root.vertical ? Math.max(3, root.thick * (0.12 + 0.88 * v)) : 4
                height: root.vertical ? 4 : Math.max(3, root.thick * (0.12 + 0.88 * v))
                radius: 2
                color: Theme.accent
                opacity: 0.55 + 0.45 * v
                Behavior on height { enabled: !root.vertical; NumberAnimation { duration: 60 } }
                Behavior on width { enabled: root.vertical; NumberAnimation { duration: 60 } }
            }
        }
    }
}
