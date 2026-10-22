pragma Singleton

import QtQuick
import Quickshell

// Design tokens: colors, shape, type, motion. Everything visual reads from here.
Singleton {
    id: root

    readonly property var a: Settings.data.appearance
    readonly property bool dark: a.mode !== "light"
    readonly property string paletteName: a.palette
    readonly property var basePalette: (paletteName === "wallpaper" && ColorGen.available) ? (dark ? ColorGen.dark : ColorGen.light) : Palettes.get(paletteName, dark)
    readonly property var palette: withAccent(basePalette, a.accentOverride)

    // Appearance → Accent color: swap the palette's accent (and pick readable text on it)
    function withAccent(p, c) {
        if (!/^#[0-9a-fA-F]{6}$/.test(c || ""))
            return p;
        const o = Object.assign({}, p);
        const q = Qt.color(c);
        o.accent = c;
        o.onAccent = (0.2126 * q.r + 0.7152 * q.g + 0.0722 * q.b) > 0.55 ? "#161616" : "#ffffff";
        return o;
    }

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

    // ── transparency (Appearance → Transparency) ──
    // each part's opacity (-1: the panels'), all scaled by the whole-UI slider
    function opacityOf(v) {
        const own = v === undefined || v < 0 ? a.panelOpacity : v;
        return Math.max(0, Math.min(1, own * (a.uiOpacity ?? 1)));
    }
    readonly property real panelOp: opacityOf(a.panelOpacity)
    readonly property real barOp: opacityOf(a.barOpacity)
    readonly property real popupOp: opacityOf(a.popupOpacity)
    readonly property real switcherOp: opacityOf(a.switcherOpacity)
    readonly property real settingsOp: opacityOf(a.settingsOpacity ?? 1)
    readonly property color panelBg: alpha(surface, panelOp)
    readonly property color barBg: alpha(bg, barOp)
    readonly property color popupBg: alpha(surface, popupOp)
    readonly property color switcherBg: alpha(surface, switcherOp)
    // panels grow out of the bar as one surface (not with the islands bar style)
    readonly property bool blendPanels: a.blendPanels && !["islands", "capsule", "minimal"].includes(Settings.data.bar.style) && Settings.data.bar.position !== "free"

    function alpha(c, value) {
        return Qt.rgba(c.r, c.g, c.b, value);
    }

    function mix(c1, c2, t) {
        // colors given as text ("#ffffff") too: read as colors, or the result is no color at all
        if (typeof c1 === "string")
            c1 = Qt.color(c1);
        if (typeof c2 === "string")
            c2 = Qt.color(c2);
        return Qt.rgba(c1.r * (1 - t) + c2.r * t, c1.g * (1 - t) + c2.g * t, c1.b * (1 - t) + c2.b * t, c1.a * (1 - t) + c2.a * t);
    }

    // ── Shape ──
    // radii and spacing grow with the UI scale, like the text, so a bigger UI
    // keeps its proportions instead of crowding (they used to stay fixed)
    readonly property real round: Math.max(0, a.roundness)
    readonly property int rXs: Math.round(6 * round * scale)
    readonly property int rSm: Math.round(10 * round * scale)
    readonly property int rMd: Math.round(16 * round * scale)
    readonly property int rLg: Math.round(22 * round * scale)
    readonly property int rXl: Math.round(30 * round * scale)

    readonly property int gap: Math.round(8 * scale)
    readonly property int sp1: Math.round(4 * scale)
    readonly property int sp2: Math.round(8 * scale)
    readonly property int sp3: Math.round(12 * scale)
    readonly property int sp4: Math.round(16 * scale)
    readonly property int sp5: Math.round(24 * scale)
    readonly property int sp6: Math.round(32 * scale)

    // ── Rhythm ──
    // One distance between the screen's edge, the bar, panels, pop-ups and windows:
    // the windows' gap (Settings → Windows & Layout), so a floating bar, a panel and
    // a window all line up along the same edge.
    readonly property int edge: Math.max(4, Math.min(24, Settings.data.windows.gaps ?? 12))

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

    // Google Sans Flex / Code, the default text fonts, also bundled (the package
    // also links them into /usr/share/fonts for other apps and the greeter).
    // Loading them registers the families for the whole shell.
    FontLoader { source: "file://" + Quickshell.shellDir + "/assets/fonts/GoogleSansFlex.ttf" }
    FontLoader { source: "file://" + Quickshell.shellDir + "/assets/fonts/GoogleSansCode.ttf" }
    FontLoader { source: "file://" + Quickshell.shellDir + "/assets/fonts/GoogleSansCode-Italic.ttf" }

    // icon look (Settings → Appearance): filled and a little heavier by default,
    // like Material 3 Expressive
    readonly property real iconFill: a.iconStyle === "outlined" ? 0 : 1
    readonly property int iconWeight: a.iconWeight > 0 ? a.iconWeight : 500
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
    readonly property string barStyle: barCfg.style || "islands"
    // styles that sit flush on the screen's edge
    readonly property bool barFlush: barStyle === "attached" || barStyle === "framed"
    // the bar's distance from the screen edge: its own setting, else the windows' gap
    readonly property int barMargin: barFlush ? 0 : (barCfg.margin ?? -1) >= 0 ? Math.round(barCfg.margin * scale) : edge

    // Bar metrics: every style is built from these, so items sit the same distance
    // from the bar's (or their group's) edges on all four sides, and rounded
    // shapes nest (an item's radius plus its inset is its container's radius).
    //  - barInset: space around items inside the bar (or an island)
    //  - barGroup: height of a section's pill (framed / capsule pills inside a bar)
    //  - barItem:  height of a bar item (icon buttons, chips)
    readonly property bool barPills: barStyle === "framed"
    readonly property int barInset: Math.max(3, Math.round(barHeight * 0.125))
    readonly property int barPillPad: Math.max(2, Math.round(barInset * 0.66))
    readonly property int barGroup: barPills ? barHeight - 2 * barPillPad : barHeight
    readonly property int barItem: barPills ? barGroup - 2 * barPillPad : barHeight - 2 * barInset
    // space between items in a section
    readonly property int barSpacing: Math.round(Math.max(2, barInset * 0.8) * ((barCfg.spacing ?? 1) > 0 ? barCfg.spacing : 1))
    // the bar's own corner radius: its setting (px), else the theme's, never more than a full round end
    readonly property int barRadius: Math.min((barCfg.radius ?? -1) >= 0 ? Math.round(barCfg.radius * scale) : rLg, Math.floor(barHeight / 2))

    // ── Motion ──
    readonly property real speed: a.animSpeed
    readonly property string motion: ["expressive", "smooth", "snappy", "minimal"].includes(a.motionStyle) ? a.motionStyle : "expressive"
    // snappy and minimal also shorten everything a bit
    readonly property real styleFactor: motion === "snappy" ? 0.7 : motion === "minimal" ? 0.85 : 1
    function dur(ms) {
        return speed <= 0 ? 0 : Math.round(ms * styleFactor / speed);
    }
    // an area's own speed on top (Settings → Appearance → Motion): panels, notifications, bar,
    // workspaces, dock, launcher, lock. 0 turns that area's animations off.
    function areaSpeed(area) {
        const v = (a.motionAreas || {})[area];
        return v === undefined ? 1 : Number(v);
    }
    function durA(area, ms) {
        const m = areaSpeed(area);
        return m <= 0 ? 0 : Math.round(dur(ms) / m);
    }
    readonly property bool hoverZoom: a.hoverZoom !== false && motion !== "minimal"
    readonly property bool ripple: a.ripple !== false
    readonly property int durShort: dur(150)
    readonly property int durMed: dur(280)
    readonly property int durLong: dur(450)
    readonly property int durXl: dur(650)

    // Bezier splines, from the Material 3 expressive motion spec.
    // The motion style swaps these, so every animation follows it: expressive keeps the
    // springs' overshoot, smooth and minimal drop it, snappy uses quick decelerations.
    readonly property QtObject curves: QtObject {
        readonly property string m: root.motion
        readonly property list<real> standard: [0.2, 0, 0, 1, 1, 1]
        readonly property list<real> standardAccel: [0.3, 0, 1, 1, 1, 1]
        readonly property list<real> standardDecel: [0, 0, 0, 1, 1, 1]
        readonly property list<real> emphasized: m === "snappy" || m === "minimal" ? [0.2, 0, 0, 1, 1, 1] : [0.05, 0, 2 / 15, 0.06, 1 / 6, 0.4, 5 / 24, 0.82, 0.25, 1, 1, 1]
        readonly property list<real> emphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1]
        readonly property list<real> emphasizedDecel: m === "snappy" ? [0, 0, 0, 1, 1, 1] : [0.05, 0.7, 0.1, 1, 1, 1]
        readonly property list<real> spring: m === "expressive" ? [0.38, 1.21, 0.22, 1, 1, 1] : m === "snappy" ? [0.1, 0.6, 0.2, 1, 1, 1] : [0.05, 0.7, 0.1, 1, 1, 1]
        readonly property list<real> springFast: m === "expressive" ? [0.42, 1.67, 0.21, 0.9, 1, 1] : m === "snappy" ? [0.1, 0.6, 0.2, 1, 1, 1] : [0.05, 0.7, 0.1, 1, 1, 1]
    }
}
