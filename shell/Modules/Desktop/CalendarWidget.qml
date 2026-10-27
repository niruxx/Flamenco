import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

// This month, with today marked, dots on days with events (your calendars and
// Online Accounts), and the next few events under it (not in the small size).
ColumnLayout {
    id: root
    property real k: 1
    property var spec
    property bool editing: false
    readonly property date today: Time.now
    readonly property int first: Time.firstDay                            // 0 = Sunday
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
        text: I18n.locale.toString(root.today, "MMMM yyyy")
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
                text: I18n.locale.dayName((root.first + index) % 7, Locale.NarrowFormat)
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
                readonly property bool busy: modelData > 0 && !!Events.busyDays[Events.key(new Date(root.today.getFullYear(), root.today.getMonth(), modelData))]
                Rectangle {
                    visible: parent.busy
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Math.round(2 * root.k)
                    width: Math.round(4 * root.k)
                    height: width
                    radius: width / 2
                    color: parent.isToday ? Theme.onAccent : Theme.accent3
                }
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

    // what's next
    Repeater {
        model: root.spec?.size === "s" ? [] : Events.events.filter(e => new Date(e.end || e.start) >= root.today).slice(0, root.spec?.size === "l" ? 4 : 2)
        RowLayout {
            id: up
            required property var modelData
            Layout.fillWidth: true
            Layout.maximumWidth: Math.round(7 * 34 * root.k)
            spacing: Math.round(8 * root.k)
            Rectangle {
                Layout.preferredWidth: Math.max(3, Math.round(3 * root.k))
                Layout.preferredHeight: Math.round(28 * root.k)
                radius: width / 2
                color: up.modelData.color || Theme.accent
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                FText { Layout.fillWidth: true; text: up.modelData.title; font.pixelSize: Math.round(Theme.fsSm * root.k); font.weight: Font.Medium; elide: Text.ElideRight }
                FText { Layout.fillWidth: true; text: I18n.locale.toString(new Date(up.modelData.start), "ddd d") + " · " + Events.timeOf(up.modelData); dim: true; font.pixelSize: Math.round(Theme.fsXs * root.k); elide: Text.ElideRight }
            }
        }
    }
}
