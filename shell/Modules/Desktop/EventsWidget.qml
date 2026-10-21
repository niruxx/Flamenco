import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

// Up next: the coming events from your calendars (Settings → Online Accounts and
// Clock & Weather → Calendars), each in its calendar's color.
ColumnLayout {
    id: root
    property real k: 1
    property var spec
    property bool editing: false
    readonly property int count: spec?.size === "s" ? 2 : spec?.size === "l" ? 6 : 4
    readonly property var next: Events.events.filter(e => new Date(e.allDay ? e.end || e.start : e.end || e.start) >= Time.now).slice(0, count)
    function dayOf(e) {
        const d = new Date(e.start), t = new Date(Time.now);
        const k = Events.key(d), today = Events.key(t);
        t.setDate(t.getDate() + 1);
        return k === today ? "Today" : k === Events.key(t) ? "Tomorrow" : Qt.formatDate(d, "ddd d MMM");
    }
    implicitWidth: Math.round(270 * k)
    spacing: Math.round(Theme.sp2 * k)

    RowLayout {
        spacing: Math.round(6 * root.k)
        FIcon { icon: "event_upcoming"; size: Math.round(18 * root.k); fill: 1; color: Theme.accent }
        FText { text: "Up next"; font.weight: Font.DemiBold; font.pixelSize: Math.round(Theme.fsLg * root.k) }
    }
    Repeater {
        model: root.next
        RowLayout {
            id: ev
            required property var modelData
            Layout.fillWidth: true
            spacing: Math.round(10 * root.k)
            Rectangle {
                Layout.preferredWidth: Math.max(3, Math.round(4 * root.k))
                Layout.fillHeight: true
                radius: width / 2
                color: ev.modelData.color || Theme.accent
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                FText {
                    Layout.fillWidth: true
                    text: ev.modelData.title
                    font.weight: Font.Medium
                    font.pixelSize: Math.round(Theme.fsMd * root.k)
                    elide: Text.ElideRight
                }
                FText {
                    Layout.fillWidth: true
                    text: root.dayOf(ev.modelData) + " · " + Events.timeOf(ev.modelData) + (ev.modelData.location ? " · " + ev.modelData.location : "")
                    dim: true
                    font.pixelSize: Math.round(Theme.fsXs * root.k)
                    elide: Text.ElideRight
                }
            }
        }
    }
    FText {
        visible: root.next.length === 0
        Layout.fillWidth: true
        text: (Settings.data.calendar.sources || []).length ? "Nothing coming up" : "No calendars yet: add them in Settings → Online Accounts"
        dim: true
        wrapMode: Text.Wrap
        font.pixelSize: Math.round(Theme.fsSm * root.k)
    }
}
