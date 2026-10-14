import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

// This month, with today marked.
ColumnLayout {
    id: root
    property real k: 1
    property var spec
    property bool editing: false
    readonly property date today: Time.now
    readonly property int first: Qt.locale().firstDayOfWeek % 7           // 0 = Sunday
    // the days to show: blanks before the 1st, then 1…n
    readonly property var cells: {
        const y = today.getFullYear(), m = today.getMonth();
        const lead = (new Date(y, m, 1).getDay() - first + 7) % 7;
        const n = new Date(y, m + 1, 0).getDate();
        const out = [];
        for (let i = 0; i < lead; i++)
            out.push(0);
        for (let d = 1; d <= n; d++)
            out.push(d);
        return out;
    }
    spacing: Math.round(Theme.sp2 * k)

    FText {
        text: Qt.formatDate(root.today, "MMMM yyyy")
        font.weight: Font.DemiBold
        font.pixelSize: Math.round(Theme.fsLg * root.k)
    }
    Grid {
        columns: 7
        spacing: Math.round(2 * root.k)
        Repeater {
            model: 7
            FText {
                required property int index
                width: Math.round(32 * root.k)
                horizontalAlignment: Text.AlignHCenter
                text: Qt.locale().dayName((root.first + index) % 7, Locale.NarrowFormat)
                dim: true
                font.pixelSize: Math.round(Theme.fsXs * root.k)
            }
        }
        Repeater {
            model: root.cells
            Rectangle {
                required property int modelData
                readonly property bool isToday: modelData === root.today.getDate()
                width: Math.round(32 * root.k)
                height: Math.round(28 * root.k)
                radius: height / 2
                color: isToday ? Theme.accent : "transparent"
                FText {
                    anchors.centerIn: parent
                    visible: parent.modelData > 0
                    text: parent.modelData
                    color: parent.isToday ? Theme.onAccent : Theme.text
                    font.weight: parent.isToday ? Font.Bold : Font.Normal
                    font.pixelSize: Math.round(Theme.fsSm * root.k)
                }
            }
        }
    }
}
