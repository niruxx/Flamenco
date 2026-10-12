import QtQuick
import qs.Commons

// Bar-style history graph. `values` are 0..max, oldest first.
Item {
    id: root

    property var values: []
    property real max: 1
    property int slots: 60
    property color color: Theme.accent

    implicitHeight: 48

    Row {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        spacing: 1

        Repeater {
            // fixed slot count keeps delegates alive; each reads its own sample
            model: root.slots

            Rectangle {
                required property int index
                readonly property int sample: root.values.length - root.slots + index
                readonly property real v: sample >= 0 ? Math.min(1, (root.values[sample] ?? 0) / Math.max(root.max, 1e-9)) : 0
                width: Math.max(1, (root.width - (root.slots - 1)) / root.slots)
                height: Math.max(1, root.height * v)
                anchors.bottom: parent.bottom
                radius: Math.min(2, width / 2)
                color: root.color
                opacity: 0.35 + 0.65 * (index / root.slots)

                Behavior on height { Anim { duration: Theme.durMed } }
            }
        }
    }
}
