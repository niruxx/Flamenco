import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services
import qs.Widgets

// The screen frame (Settings → Appearance → Screen frame; part of the Flamenco
// layout): a band in the bar's color along the screen's other edges, with the
// desktop's corners rounded inside it, so bar and frame read as one surface
// around the wallpaper. Drawn on a click-through layer; thin windows along each
// edge reserve its width so windows don't slide under it. It grows in from the
// edges after login, with the bar.
Scope {
    id: root

    readonly property var a: Settings.data.appearance
    readonly property bool on: a.screenFrame ?? false
    readonly property int w: Math.max(0, Math.min(24, a.frameWidth ?? 6))
    readonly property int r: Math.max(0, Math.min(48, a.frameRadius ?? 18))
    readonly property color tone: Theme.barBg
    // the bar's edge: it draws that side itself while it holds its space
    readonly property string barEdge: Theme.barPos
    readonly property bool barHolds: Settings.data.bar.position !== "free" && ((Settings.data.bar.hide || "never") === "never" && !Panels.barHidden || Settings.data.bar.hideKeepSpace)
    readonly property int barThick: Theme.barHeight + Theme.barMargin

    // grows in after login (with the bar), and when turned on
    Item {
        id: grow
        property real v: 0
        Component.onCompleted: v = Qt.binding(() => root.on ? 1 : 0)
        Behavior on v { Anim { duration: Theme.durA("bar", 700); easing.bezierCurve: Theme.curves.emphasizedDecel } }
    }
    readonly property real g: Math.min(grow.v, SessionFx.revealBar)

    // a square with a quarter circle cut out: the bar's color in a desktop corner
    // (drawn for the top-left; rotated for the others)
    component Corner: Canvas {
        property real size: 0
        width: Math.max(1, Math.ceil(size))
        height: width
        visible: size > 0.5
        readonly property color c: root.tone
        onCChanged: requestPaint()
        onWidthChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.fillStyle = c;
            ctx.beginPath();
            ctx.moveTo(0, 0);
            ctx.lineTo(width, 0);
            ctx.arc(width, height, width, -Math.PI / 2, Math.PI, true);
            ctx.lineTo(0, 0);
            ctx.closePath();
            ctx.fill();
        }
    }

    // ── the drawing, click-through ──
    Variants {
        model: root.on || grow.v > 0 ? Quickshell.screens : []

        PanelWindow {
            id: win
            required property ShellScreen modelData
            readonly property real fw: root.w * root.g
            readonly property real fr: root.r * root.g
            // where the desktop starts on each side
            function inset(edge) {
                return edge === root.barEdge && root.barHolds ? root.barThick : fw;
            }
            readonly property real iT: inset("top")
            readonly property real iB: inset("bottom")
            readonly property real iL: inset("left")
            readonly property real iR: inset("right")

            screen: modelData
            color: "transparent"
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "flamenco-frame"
            mask: Region {}

            // the bands (not on the bar's side while it's there: it is that band)
            Rectangle { visible: !(root.barEdge === "top" && root.barHolds); x: 0; y: 0; width: win.width; height: win.iT; color: root.tone }
            Rectangle { visible: !(root.barEdge === "bottom" && root.barHolds); x: 0; y: win.height - win.iB; width: win.width; height: win.iB; color: root.tone }
            Rectangle { visible: !(root.barEdge === "left" && root.barHolds); x: 0; y: win.iT; width: win.iL; height: win.height - win.iT - win.iB; color: root.tone }
            Rectangle { visible: !(root.barEdge === "right" && root.barHolds); x: win.width - win.iR; y: win.iT; width: win.iR; height: win.height - win.iT - win.iB; color: root.tone }

            // the rounded corners of the desktop, inside the frame
            Corner { size: win.fr; x: win.iL; y: win.iT; rotation: 0 }
            Corner { size: win.fr; x: win.width - win.iR - width; y: win.iT; rotation: 90 }
            Corner { size: win.fr; x: win.width - win.iR - width; y: win.height - win.iB - height; rotation: 180 }
            Corner { size: win.fr; x: win.iL; y: win.height - win.iB - height; rotation: 270 }
        }
    }

    // ── its width, kept free of windows (each side but the bar's, while the bar holds it) ──
    Variants {
        model: root.on ? Quickshell.screens : []

        Scope {
            id: scr
            required property ShellScreen modelData
            Variants {
                model: ["top", "bottom", "left", "right"].filter(e => !(e === root.barEdge && root.barHolds))
                PanelWindow {
                    required property string modelData
                    screen: scr.modelData
                    color: "transparent"
                    anchors {
                        top: modelData !== "bottom"
                        bottom: modelData !== "top"
                        left: modelData !== "right"
                        right: modelData !== "left"
                    }
                    implicitWidth: modelData === "left" || modelData === "right" ? Math.max(1, root.w) : 0
                    implicitHeight: modelData === "top" || modelData === "bottom" ? Math.max(1, root.w) : 0
                    exclusiveZone: root.w
                    WlrLayershell.layer: WlrLayer.Bottom
                    WlrLayershell.namespace: "flamenco-frame-space"
                    mask: Region {}
                }
            }
        }
    }
}
