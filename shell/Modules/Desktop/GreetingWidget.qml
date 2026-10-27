import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

// A greeting for the time of day, with your first name, and a line about the
// day: the next event, or the weather.
ColumnLayout {
    id: root
    property real k: 1
    property var spec
    property bool editing: false
    readonly property int hour: Time.now.getHours()
    readonly property string part: hour < 5 ? "Good night" : hour < 12 ? "Good morning" : hour < 18 ? "Good afternoon" : "Good evening"
    readonly property string first: Users.fullName.split(" ")[0] || Paths.user
    readonly property var nextEvent: Events.events.find(e => !e.allDay && new Date(e.start) >= Time.now && Events.key(new Date(e.start)) === Events.key(Time.now)) ?? null
    spacing: Math.round(2 * k)

    FText {
        text: root.part + ","
        font.pixelSize: Math.round(Theme.fsXl * root.k)
        dim: true
    }
    FText {
        text: root.first
        font.pixelSize: Math.round(44 * root.k)
        font.weight: Font.Bold
        color: Theme.accent
    }
    FText {
        Layout.topMargin: Math.round(4 * root.k)
        text: I18n.locale.toString(Time.now, "dddd d MMMM") + (root.nextEvent ? " · next: " + root.nextEvent.title + " at " + Qt.formatTime(new Date(root.nextEvent.start), Time.use24h ? I18n.tr("HH:mm") : "h:mm AP")
            : Weather.ready ? " · " + Math.round(Weather.temp) + Weather.unit + " " + Weather.description.toLowerCase() : "")
        font.pixelSize: Math.round(Theme.fsMd * root.k)
        dim: true
    }
}
