import QtQuick
import QtQuick.Layouts
import qs.Commons

// A tonal segmented picker. Arrow keys move selection; Tab visits the group.
// options: [{ value, label, icon? }]
Rectangle {
    id: root

    property var options: []
    property var current
    signal selected(var value)

    property real segmentGap: 0
    readonly property real actualGap: Math.min(Math.max(0, segmentGap), Math.max(0, width - inset * 2) / Math.max(1, options.length * 2))
    readonly property int index: options.findIndex(o => o.value === current)
    readonly property real inset: Theme.sp1
    readonly property real segWidth: Math.max(0, width - inset * 2 - actualGap * Math.max(0, options.length - 1)) / Math.max(1, options.length)

    implicitHeight: Theme.controlHeight
    implicitWidth: options.length * Math.round(110 * Theme.scale)
    radius: height / 2
    color: Theme.surfaceHighest
    activeFocusOnTab: options.length > 0
    Accessible.role: Accessible.Grouping
    Accessible.name: index >= 0 ? options[index].label : ""

    function selectAt(i) {
        if (options.length)
            selected(options[(i + options.length) % options.length].value);
    }

    Keys.onPressed: event => {
        if (!options.length)
            return;
        if (event.key === Qt.Key_Right || event.key === Qt.Key_Down)
            selectAt(index < 0 ? 0 : index + 1);
        else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up)
            selectAt(index < 0 ? options.length - 1 : index - 1);
        else if (event.key === Qt.Key_Home)
            selectAt(0);
        else if (event.key === Qt.Key_End)
            selectAt(options.length - 1);
        else if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (!event.isAutoRepeat)
                selectAt(Math.max(0, index));
        } else
            return;
        event.accepted = true;
    }

    Rectangle {
        visible: root.index >= 0
        y: root.inset
        x: root.inset + Math.max(0, root.index) * (root.segWidth + root.actualGap)
        width: root.segWidth
        height: Math.max(0, parent.height - root.inset * 2)
        radius: height / 2
        color: Theme.accentContainer

        Behavior on x { Anim { easing.bezierCurve: Theme.curves.emphasizedDecel; duration: Theme.durMed } }
        Behavior on width { Anim {} }
    }

    Row {
        spacing: root.actualGap
        x: root.inset
        y: root.inset
        Repeater {
            model: root.options
            delegate: Item {
                id: segment
                required property var modelData
                required property int index
                width: root.segWidth
                height: Math.max(0, root.height - root.inset * 2)
                property real radius: height / 2
                Accessible.role: Accessible.RadioButton
                Accessible.name: modelData.label
                Accessible.checkable: true
                Accessible.checked: index === root.index
                Accessible.onPressAction: root.selected(modelData.value)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.sp2
                    anchors.rightMargin: Theme.sp2
                    spacing: Theme.sp1
                    Item { Layout.fillWidth: true; Layout.preferredWidth: 0 }
                    FIcon {
                        visible: !!segment.modelData.icon
                        icon: segment.modelData.icon ?? ""
                        size: Math.round(18 * Theme.scale)
                        color: segment.index === root.index ? Theme.onAccentContainer : Theme.textDim
                    }
                    FText {
                        Layout.maximumWidth: Math.max(0, segment.width - Theme.sp2 * 2 - (segment.modelData.icon ? 18 * Theme.scale + Theme.sp1 : 0))
                        text: segment.modelData.label
                        elide: Text.ElideRight
                        font.pixelSize: Theme.fsSm
                        font.weight: Font.DemiBold
                        color: segment.index === root.index ? Theme.onAccentContainer : Theme.text
                    }
                    Item { Layout.fillWidth: true; Layout.preferredWidth: 0 }
                }

                StateLayer {
                    tint: Theme.text
                    onClicked: {
                        root.forceActiveFocus(Qt.MouseFocusReason);
                        root.selected(segment.modelData.value);
                    }
                }
            }
        }
    }

    FocusRing {}
}
