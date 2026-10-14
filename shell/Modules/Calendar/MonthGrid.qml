import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

// Month calendar with sliding month changes.
ColumnLayout {
    id: root

    property int monthOffset: 0
    // the day clicked (events for it show under the grid); today by default
    property date selected: Time.now
    property int slideDir: 0
    property int cellHeight: 34
    readonly property date shown: {
        const n = Time.now;
        return new Date(n.getFullYear(), n.getMonth() + monthOffset, 1);
    }

    function go(d) {
        slideDir = d;
        monthOffset += d;
        gridAnim.restart();
    }

    spacing: Theme.sp2

    RowLayout {
        Layout.fillWidth: true
        FText {
            Layout.fillWidth: true
            text: Qt.formatDate(root.shown, "MMMM yyyy")
            font.pixelSize: Theme.fsLg
            font.weight: Font.Bold
        }
        FIconButton { icon: "today"; size: 30; visible: root.monthOffset !== 0; onClicked: root.go(-root.monthOffset) }
        FIconButton { icon: "chevron_left"; size: 30; onClicked: root.go(-1) }
        FIconButton { icon: "chevron_right"; size: 30; onClicked: root.go(1) }
    }

    GridLayout {
        id: grid
        Layout.fillWidth: true
        columns: 7
        rowSpacing: 2
        columnSpacing: 2

        ParallelAnimation {
            id: gridAnim
            NumberAnimation { target: grid; property: "opacity"; from: 0; to: 1; duration: Theme.durMed }
            NumberAnimation { target: gridShift; property: "x"; from: root.slideDir * 40; to: 0; duration: Theme.durLong; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curves.emphasizedDecel }
        }
        transform: Translate { id: gridShift }

        Repeater {
            model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
            FText {
                required property string modelData
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                dim: true
                font.pixelSize: Theme.fsXs
                font.weight: Font.Bold
            }
        }

        Repeater {
            model: 42
            Rectangle {
                id: cell
                required property int index
                readonly property int lead: (root.shown.getDay() + 6) % 7
                readonly property date day: new Date(root.shown.getFullYear(), root.shown.getMonth(), index - lead + 1)
                readonly property bool inMonth: day.getMonth() === root.shown.getMonth()
                readonly property bool today: day.toDateString() === Time.now.toDateString()
                readonly property bool picked: day.toDateString() === root.selected.toDateString()
                readonly property bool busy: !!Events.busyDays[Events.key(day)]

                Layout.fillWidth: true
                Layout.preferredHeight: root.cellHeight
                radius: today ? Theme.rMd : height / 2
                color: today ? Theme.accent : picked ? Theme.alpha(Theme.accent, 0.22) : hover.hovered ? Theme.surfaceHighest : "transparent"

                Behavior on color { CAnim { duration: Theme.durShort } }

                FText {
                    anchors.centerIn: parent
                    text: cell.day.getDate()
                    color: cell.today ? Theme.onAccent : cell.inMonth ? Theme.text : Theme.textDim
                    opacity: cell.inMonth ? 1 : 0.45
                    font.weight: cell.today ? Font.Bold : Font.Normal
                    font.pixelSize: Theme.fsSm
                }
                // a dot under days with events
                Rectangle {
                    visible: cell.busy
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 3
                    width: 4
                    height: 4
                    radius: 2
                    color: cell.today ? Theme.onAccent : Theme.accent
                }
                HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: root.selected = cell.day }
            }
        }
    }
}
