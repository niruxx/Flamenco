import QtQuick
import QtQuick.Effects
import qs.Commons
import qs.Services
import qs.Widgets

// One desktop widget: its background in the chosen style (card, glass or
// bare) and its content. Used on the desktop and, the same, in the editor.
Item {
    id: body

    required property var spec               // { id, type, size, text, … }
    property bool editing: false              // being arranged: content isn't interactive
    readonly property var cfg: Settings.data.desktop
    readonly property real k: spec.size === "s" ? 0.8 : spec.size === "l" ? 1.3 : 1
    readonly property int pad: Math.round(Theme.sp4 * k + 4)

    implicitWidth: content.implicitWidth + pad * 2
    implicitHeight: content.implicitHeight + pad * 2
    width: implicitWidth
    height: implicitHeight

    Rectangle {
        anchors.fill: parent
        visible: body.cfg.style !== "bare"
        radius: Theme.rXl
        color: body.cfg.style === "glass" ? Theme.alpha(Theme.bg, 0.15 + 0.3 * body.cfg.opacity) : Theme.alpha(Theme.surface, body.cfg.opacity)
        border.width: 1
        border.color: body.cfg.style === "glass" ? Theme.alpha(Theme.text, 0.16) : Theme.alpha(Theme.border, 0.6)
    }

    Loader {
        id: content
        anchors.centerIn: parent
        sourceComponent: ({ clock: clockC, weather: weatherC, system: systemC, media: mediaC, calendar: calendarC, note: noteC })[body.spec.type] ?? unknownC
        onLoaded: {
            item.k = Qt.binding(() => body.k);
            item.spec = Qt.binding(() => body.spec);
            item.editing = Qt.binding(() => body.editing);
        }
        // straight on the wallpaper: a soft shadow keeps text readable
        layer.enabled: body.cfg.style === "bare"
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Theme.alpha(Theme.shadow, 0.7)
            shadowBlur: 0.5
            blurMax: 16
        }
    }

    Component { id: clockC; ClockWidget {} }
    Component { id: weatherC; WeatherWidget {} }
    Component { id: systemC; SystemWidget {} }
    Component { id: mediaC; MediaWidget {} }
    Component { id: calendarC; CalendarWidget {} }
    Component { id: noteC; NoteWidget {} }
    Component {
        id: unknownC
        FText {
            property real k: 1
            property var spec
            property bool editing
            text: "Unknown widget"
            dim: true
        }
    }
}
