import QtQuick
import qs.Commons

// Segmented picker with a sliding selection pill.
// options: [{ value, label, icon? }]
Rectangle {
    id: root

    property var options: []
    property var current
    signal selected(var value)

    readonly property int index: Math.max(0, options.findIndex(o => o.value === current))
    readonly property real segWidth: (width - 8) / Math.max(1, options.length)

    implicitHeight: 40
    implicitWidth: options.length * 110
    radius: height / 2
    color: Theme.surfaceHighest

    Rectangle {
        y: 4
        x: 4 + root.index * root.segWidth
        width: root.segWidth
        height: parent.height - 8
        radius: height / 2
        color: Theme.accent

        Behavior on x { Anim { easing.bezierCurve: Theme.curves.spring; duration: Theme.durLong } }
        Behavior on width { Anim {} }
    }

    Row {
        x: 4
        y: 4
        Repeater {
            model: root.options
            delegate: Item {
                required property var modelData
                required property int index
                width: root.segWidth
                height: root.height - 8

                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    FIcon {
                        visible: !!modelData.icon
                        icon: modelData.icon ?? ""
                        size: 18
                        anchors.verticalCenter: parent.verticalCenter
                        color: index === root.index ? Theme.onAccent : Theme.text
                    }
                    FText {
                        text: modelData.label
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: Theme.fsSm
                        font.weight: Font.DemiBold
                        color: index === root.index ? Theme.onAccent : Theme.text
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.selected(modelData.value)
                }
            }
        }
    }
}
