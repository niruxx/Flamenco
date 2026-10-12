pragma Singleton

import QtQuick
import Quickshell

// Design tokens: colors, shape, type, motion. Everything visual reads from here.
Singleton {
    id: root

    readonly property var a: Settings.data.appearance
    readonly property bool dark: a.mode !== "light"
    readonly property string paletteName: a.palette
    readonly property var palette: (paletteName === "wallpaper" && ColorGen.available) ? (dark ? ColorGen.dark : ColorGen.light) : Palettes.get(paletteName, dark)

    // ── Colors ──
    // Palette switches cross-fade: `t` runs 0 → 1 from the previous palette to
    // the new one. (A Behavior per color would be simpler, but Behaviors on a
    // non-Item object crash Qt 6.12 during deferred creation.)
    readonly property var roles: ["bg", "surface", "surfaceHigh", "surfaceHighest", "border", "text", "textDim", "accent", "onAccent", "accent2", "accent3", "error", "warning", "success"]
    property var from: palette
    property real t: 1

    onPaletteChanged: {
        const snap = {};
        for (const r of roles)
            snap[r] = String(root[r]);
        from = snap;
        t = 0;
        fade.restart();
    }

    NumberAnimation {
        id: fade
        target: root
        property: "t"
        from: 0
        to: 1
        duration: root.durXl
        easing.type: Easing.OutCubic
    }

    function role(r) {
        return t >= 1 ? Qt.color(palette[r]) : mix(Qt.color(from[r]), Qt.color(palette[r]), t);
    }

    readonly property color bg: role("bg")
    readonly property color surface: role("surface")
    readonly property color surfaceHigh: role("surfaceHigh")
    readonly property color surfaceHighest: role("surfaceHighest")
    readonly property color border: role("border")
    readonly property color text: role("text")
    readonly property color textDim: role("textDim")
    readonly property color accent: role("accent")
    readonly property color onAccent: role("onAccent")
    readonly property color accent2: role("accent2")
    readonly property color accent3: role("accent3")
    readonly property color error: role("error")
    readonly property color warning: role("warning")
    readonly property color success: role("success")
    readonly property color shadow: "#000000"

    readonly property color panelBg: alpha(surface, a.panelOpacity)
    readonly property color barBg: alpha(bg, a.panelOpacity)

    function alpha(c, value) {
        return Qt.rgba(c.r, c.g, c.b, value);
    }

    function mix(c1, c2, t) {
        return Qt.rgba(c1.r * (1 - t) + c2.r * t, c1.g * (1 - t) + c2.g * t, c1.b * (1 - t) + c2.b * t, c1.a * (1 - t) + c2.a * t);
    }

    // ── Shape ──
    readonly property real round: Math.max(0, a.roundness)
    readonly property int rXs: Math.round(6 * round)
    readonly property int rSm: Math.round(10 * round)
    readonly property int rMd: Math.round(16 * round)
    readonly property int rLg: Math.round(22 * round)
    readonly property int rXl: Math.round(30 * round)

    readonly property int gap: 8
    readonly property int sp1: 4
    readonly property int sp2: 8
    readonly property int sp3: 12
    readonly property int sp4: 16
    readonly property int sp5: 24
    readonly property int sp6: 32

    // ── Type ──
    readonly property real scale: a.uiScale > 0 ? a.uiScale : 1
    readonly property string fontFamily: a.fontFamily
    readonly property string monoFamily: a.monoFamily
    // Icons come from the bundled Material Symbols font (assets/fonts), so no
    // system install is needed. Falls back to an installed copy by family name.
    readonly property string iconFont: iconLoader.status === FontLoader.Ready ? iconLoader.name : "Material Symbols Rounded"

    FontLoader {
        id: iconLoader
        source: "file://" + Quickshell.shellDir + "/assets/fonts/MaterialSymbolsRounded.ttf"
    }
    readonly property int fsXs: Math.round(11 * scale)
    readonly property int fsSm: Math.round(12 * scale)
    readonly property int fsMd: Math.round(14 * scale)
    readonly property int fsLg: Math.round(16 * scale)
    readonly property int fsXl: Math.round(20 * scale)
    readonly property int fsXxl: Math.round(28 * scale)
    readonly property int fsHuge: Math.round(96 * scale)
    readonly property int iconSize: Math.round(20 * scale)

    // ── Bar ──
    readonly property var barCfg: Settings.data.bar
    readonly property string barPos: ["top", "bottom", "left", "right"].includes(barCfg.position) ? barCfg.position : "top"
    readonly property bool barVertical: barPos === "left" || barPos === "right"
    // panels hang from the top unless the bar is at the bottom
    readonly property bool barTop: barPos !== "bottom"
    // bar thickness (height when horizontal, width when vertical)
    readonly property int barHeight: Math.round(barCfg.height * scale)
    readonly property int barMargin: barCfg.style === "attached" ? 0 : gap

    // ── Motion ──
    readonly property real speed: a.animSpeed
    function dur(ms) {
        return speed <= 0 ? 0 : Math.round(ms / speed);
    }
    readonly property int durShort: dur(150)
    readonly property int durMed: dur(280)
    readonly property int durLong: dur(450)
    readonly property int durXl: dur(650)

    // Bezier splines, from the Material 3 expressive motion spec.
    readonly property QtObject curves: QtObject {
        readonly property list<real> standard: [0.2, 0, 0, 1, 1, 1]
        readonly property list<real> standardAccel: [0.3, 0, 1, 1, 1, 1]
        readonly property list<real> standardDecel: [0, 0, 0, 1, 1, 1]
        readonly property list<real> emphasized: [0.05, 0, 2 / 15, 0.06, 1 / 6, 0.4, 5 / 24, 0.82, 0.25, 1, 1, 1]
        readonly property list<real> emphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1]
        readonly property list<real> emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]
        readonly property list<real> spring: [0.38, 1.21, 0.22, 1, 1, 1]
        readonly property list<real> springFast: [0.42, 1.67, 0.21, 0.9, 1, 1]
    }
}
