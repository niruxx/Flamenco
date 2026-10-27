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
    // a size change (S / M / L) grows or shrinks it instead of jumping
    Behavior on width { Anim { duration: Theme.durMed; easing.bezierCurve: Theme.curves.emphasizedDecel } }
    Behavior on height { Anim { duration: Theme.durMed; easing.bezierCurve: Theme.curves.emphasizedDecel } }

    // ── a little life: it pops in when it appears, lifts a touch under the pointer ──
    // (on an inner layer: the desktop drives this item's own opacity and position at login)
    property real appear: 0
    Component.onCompleted: popIn.start()
    NumberAnimation {
        id: popIn
        target: body
        property: "appear"
        from: 0
        to: 1
        duration: Theme.durLong
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Theme.curves.spring
    }
    HoverHandler { id: lift }
    readonly property bool lifted: lift.hovered && !editing && Theme.hoverZoom

    Item {
        id: face
        anchors.fill: parent
        opacity: Math.min(1, body.appear)
        scale: (0.92 + 0.08 * body.appear) * (body.lifted ? 1.025 : 1)
        Behavior on scale { enabled: body.appear >= 1; Anim { duration: Theme.durMed; easing.bezierCurve: Theme.curves.springFast } }

    Rectangle {
        anchors.fill: parent
        visible: body.cfg.style !== "bare"
        radius: Theme.rXl
        color: body.cfg.style === "glass" ? Theme.alpha(Theme.bg, 0.15 + 0.3 * body.cfg.opacity) : Theme.alpha(Theme.surface, body.cfg.opacity)
        border.width: 1
        // its edge brightens while the pointer is on it
        border.color: body.lifted ? Theme.alpha(Theme.accent, 0.55) : body.cfg.style === "glass" ? Theme.alpha(Theme.text, 0.16) : Theme.alpha(Theme.border, 0.6)
        Behavior on border.color { CAnim {} }
    }

    Loader {
        id: content
        anchors.centerIn: parent
        sourceComponent: ({ clock: clockC, weather: weatherC, system: systemC, media: mediaC, calendar: calendarC, note: noteC,
                events: eventsC, greeting: greetingC, photo: photoC, battery: batteryC, network: networkC, apps: appsC, visualizer: visualizerC })[body.spec.type] ?? unknownC
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
    }

    Component { id: clockC; ClockWidget {} }
    Component { id: weatherC; WeatherWidget {} }
    Component { id: systemC; SystemWidget {} }
    Component { id: mediaC; MediaWidget {} }
    Component { id: calendarC; CalendarWidget {} }
    Component { id: noteC; NoteWidget {} }
    Component { id: eventsC; EventsWidget {} }
    Component { id: greetingC; GreetingWidget {} }
    Component { id: photoC; PhotoWidget {} }
    Component { id: batteryC; BatteryWidget {} }
    Component { id: networkC; NetworkWidget {} }
    Component { id: appsC; AppsWidget {} }
    Component { id: visualizerC; VisualizerWidget {} }
    Component {
        id: unknownC
        FText {
            property real k: 1
            property var spec
            property bool editing
            text: I18n.tr("Unknown widget")
            dim: true
        }
    }
}
