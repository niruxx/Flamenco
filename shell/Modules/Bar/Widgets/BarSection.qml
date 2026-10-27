import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

// One bar section (start / center / end). Lays widgets out in a row, or a
// column when the bar is vertical.
Rectangle {
    id: sec

    property var ids: []
    property string barSide: ""                // start | center | end: panels opened from here open on that side
    property var registry: ({})
    property bool islands: false
    property bool pills: false                 // framed bar: a rounder, lighter pill inside the bar, lifting on hover
    property bool vertical: false
    property int level: 0                      // bar compaction level, passed to widgets
    readonly property real size: vertical ? height : width

    // a section's thickness, and the room left around its items (the same on every side)
    readonly property int cross: pills ? Theme.barGroup : Theme.barHeight
    readonly property int pad: islands || pills ? Math.round((cross - Theme.barItem) / 2) : 0

    implicitWidth: vertical ? cross : grid.implicitWidth + pad * 2
    implicitHeight: vertical ? grid.implicitHeight + pad * 2 : cross
    width: implicitWidth
    height: implicitHeight
    // nested rounding: a pill is fully round; an island takes the bar's radius
    radius: pills ? cross / 2 : islands ? Math.min(Theme.barRadius, cross / 2) : 0
    color: pills ? Theme.mix(Theme.surfaceHigh, Theme.surfaceHighest, pillHover.hovered ? 0.6 : 0) : islands ? Theme.barBg : "transparent"
    border.width: pills ? 1 : islands && (Settings.data.bar.border ?? false) ? 1 : 0
    border.color: pills ? Theme.alpha(Theme.text, pillHover.hovered ? 0.1 : 0.04) : Theme.alpha(Theme.border, 0.7)
    Behavior on color { CAnim {} }
    HoverHandler { id: pillHover; enabled: sec.pills }
    visible: ids.length > 0 && (vertical ? grid.implicitHeight : grid.implicitWidth) > 0

    Behavior on implicitWidth { enabled: !sec.vertical; Anim { easing.bezierCurve: Theme.curves.emphasizedDecel } }
    Behavior on implicitHeight { enabled: sec.vertical; Anim { easing.bezierCurve: Theme.curves.emphasizedDecel } }

    // the surface finish on islands and pills (gloss / chrome)
    Finish { visible: (sec.islands || sec.pills) && (Settings.data.appearance.finish || "flat") !== "flat" }

    GridLayout {
        id: grid
        anchors.centerIn: parent
        flow: sec.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
        rowSpacing: Theme.barSpacing
        columnSpacing: Theme.barSpacing

        Repeater {
            model: sec.ids
            delegate: Loader {
                required property string modelData
                Layout.alignment: Qt.AlignCenter
                // "plugin:<id>" entries are plugins' widgets (Plugins service)
                // "tp:<kind>/<id>" are Noctalia and DMS plugins' widgets (ThirdParty service)
                sourceComponent: sec.registry[modelData] ?? (modelData.startsWith("plugin:") ? sec.registry["plugin"] ?? null
                    : modelData.startsWith("tp:") ? sec.registry["thirdparty"] ?? null
                    : modelData.startsWith("separator") ? sec.registry["separator"] ?? null
                    : modelData.startsWith("spacer") ? sec.registry["spacer"] ?? null
                    : modelData.startsWith("custom:") ? sec.registry["custom"] ?? null : null)
                // widgets that adapt to tight bars declare `barLevel`
                onLoaded: {
                    if (item && item.customId !== undefined)
                        item.customId = modelData;
                    if (item && item.pluginId !== undefined)
                        item.pluginId = modelData.slice(7);
                    if (item && item.key !== undefined && modelData.startsWith("tp:"))
                        item.key = modelData.slice(3);
                    if (item && item.barLevel !== undefined)
                        item.barLevel = Qt.binding(() => sec.level);
                }
                // widgets set `barVisible` (not `visible`) so a hidden one frees its slot
                visible: item !== null && (item.barVisible ?? true)
            }
        }
    }
}
