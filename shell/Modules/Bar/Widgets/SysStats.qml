import QtQuick
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

// CPU and memory (and the temperature, Settings → Bar): as icons and numbers,
// or as small ring gauges.
BarChip {
    id: root
    property string screenName
    property int barLevel: 0
    property bool barVisible: barLevel < 2
    readonly property var b: Settings.data.bar
    readonly property bool rings: b.statsStyle === "rings"
    highlighted: Panels.current === "performance"
    onClicked: Panels.toggle("performance", screenName, root)
    onMiddleClicked: Quickshell.execDetached(Paths.term(["btop"]))

    component Stat: BarFlow {
        property string icon
        property real value
        property string label
        property bool ring: false
        spacing: Theme.barVertical ? 0 : 4

        Item {
            implicitWidth: parent.ring ? Theme.barHeight - 16 : 16
            implicitHeight: implicitWidth

            Canvas {
                id: arc
                anchors.fill: parent
                visible: parent.parent.ring
                readonly property real v: Math.max(0, Math.min(1, parent.parent.value))
                readonly property color track: Theme.alpha(Theme.text, 0.15)
                readonly property color fillColor: v > 0.85 ? Theme.error : Theme.accent2
                onVChanged: requestPaint()
                onTrackChanged: requestPaint()
                onFillColorChanged: requestPaint()
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    const r = width / 2 - 1.5, c = width / 2;
                    ctx.lineWidth = 2.5;
                    ctx.lineCap = "round";
                    ctx.strokeStyle = track;
                    ctx.beginPath();
                    ctx.arc(c, c, r, 0, Math.PI * 2);
                    ctx.stroke();
                    if (v > 0) {
                        ctx.strokeStyle = fillColor;
                        ctx.beginPath();
                        ctx.arc(c, c, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * v);
                        ctx.stroke();
                    }
                }
            }
            FIcon {
                anchors.centerIn: parent
                icon: parent.parent.icon
                size: parent.parent.ring ? Math.round(parent.width * 0.5) : 16
                color: parent.parent.value > 0.85 ? Theme.error : Theme.accent2
            }
        }
        FText {
            text: parent.label
            mono: true
            font.pixelSize: Theme.barVertical ? Theme.fsXs : Theme.fsSm
        }
    }

    BarFlow {
        spacing: Theme.barVertical ? 6 : root.rings ? 12 : 10
        Stat { icon: "memory"; value: SystemStats.cpu; ring: root.rings; label: Math.round(SystemStats.cpu * 100) + (Theme.barVertical ? "" : "%") }
        Stat { icon: "developer_board"; value: SystemStats.mem; ring: root.rings; visible: root.barLevel < 1; label: Math.round(SystemStats.mem * 100) + (Theme.barVertical ? "" : "%") }
        Stat { icon: "thermostat"; value: SystemStats.temp / 100; ring: root.rings; visible: root.b.statsTemp && root.barLevel < 1 && SystemStats.temp > 0; label: Math.round(SystemStats.temp) + "°" }
    }
}
