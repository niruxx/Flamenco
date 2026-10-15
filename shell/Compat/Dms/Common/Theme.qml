pragma Singleton

import QtQuick
import Quickshell
import qs.Commons as F
import qs.Compat.Dms.DankCommon.Common as DankCommon

// Flamenco shim for DMS's Theme: its color roles and sizes, taken from Flamenco's
// palette, fonts and motion. It's also handed to DankCommon's Style, which
// DMS's shared widgets read their colors from.
Singleton {
    id: root

    Component.onCompleted: DankCommon.Style.theme = root

    // ── colors ──
    readonly property bool isLightMode: !F.Theme.dark
    readonly property string currentTheme: "flamenco"
    readonly property color primary: F.Theme.accent
    readonly property color primaryText: F.Theme.onAccent
    readonly property color onPrimary: F.Theme.onAccent
    readonly property color primaryContainer: blend(surfaceContainerHigh, primary, 0.45)
    readonly property color onPrimaryContainer: F.Theme.text
    readonly property color secondary: F.Theme.accent2
    readonly property color secondaryContainer: blend(surfaceContainerHigh, secondary, 0.35)
    readonly property color onSecondaryContainer: F.Theme.text
    readonly property color tertiary: F.Theme.accent3
    readonly property color surface: F.Theme.surface
    readonly property color surfaceText: F.Theme.text
    readonly property color onSurface: F.Theme.text
    readonly property color surfaceVariant: F.Theme.surfaceHigh
    readonly property color surfaceVariantText: F.Theme.textDim
    readonly property color surfaceTint: F.Theme.accent
    readonly property color background: F.Theme.bg
    readonly property color backgroundText: F.Theme.text
    readonly property color outline: F.Theme.border
    readonly property color outlineVariant: withAlpha(outline, 0.6)
    readonly property color surfaceContainerLowest: F.Theme.bg
    readonly property color surfaceContainerLow: blend(F.Theme.bg, F.Theme.surface, 0.6)
    readonly property color surfaceContainer: F.Theme.surface
    readonly property color surfaceContainerHigh: F.Theme.surfaceHigh
    readonly property color surfaceContainerHighest: F.Theme.surfaceHighest
    readonly property color error: F.Theme.error
    readonly property color onError: isLightMode ? "#ffffff" : "#1d1012"
    readonly property color errorText: F.Theme.error
    readonly property color errorContainer: blend(surfaceContainerHigh, error, 0.35)
    readonly property color warning: F.Theme.warning
    readonly property color success: F.Theme.success
    readonly property color info: F.Theme.accent2
    readonly property color tempWarning: "#ff9933"
    readonly property color tempDanger: "#ff5555"

    readonly property color onSurface_12: withAlpha(onSurface, 0.12)
    readonly property color onSurface_38: withAlpha(onSurface, 0.38)
    readonly property color primaryHover: withAlpha(primary, 0.12)
    readonly property color primaryHoverLight: withAlpha(primary, 0.08)
    readonly property color primaryPressed: withAlpha(primary, 0.16)
    readonly property color primarySelected: withAlpha(primary, 0.3)
    readonly property color primaryBackground: withAlpha(primary, 0.04)
    readonly property color surfaceHover: withAlpha(surfaceVariant, 0.08)
    readonly property color surfacePressed: withAlpha(surfaceVariant, 0.12)
    readonly property color surfaceLight: withAlpha(surfaceVariant, 0.1)
    readonly property color surfaceVariantAlpha: withAlpha(surfaceVariant, 0.2)
    readonly property color surfaceTextHover: withAlpha(surfaceText, 0.08)
    readonly property color surfaceTextSecondary: withAlpha(surfaceText, 0.6)
    readonly property color surfaceTextMedium: withAlpha(surfaceText, 0.7)
    readonly property color outlineButton: withAlpha(outline, 0.5)
    readonly property color outlineMedium: withAlpha(outline, layerOutlineOpacity)
    readonly property color outlineStrong: withAlpha(outline, Math.min(1, layerOutlineOpacity * 1.5))
    readonly property color outlineHeavy: withAlpha(outline, 0.2)
    readonly property color errorHover: withAlpha(error, 0.12)
    readonly property color errorPressed: withAlpha(error, 0.16)
    readonly property color errorSelected: withAlpha(error, 0.3)
    readonly property color shadowMedium: Qt.rgba(0, 0, 0, 0.08)
    readonly property color shadowStrong: Qt.rgba(0, 0, 0, 0.3)
    readonly property color focusRingColor: primary
    readonly property color widgetTextColor: surfaceText
    readonly property color widgetIconColor: surfaceText
    readonly property color widgetBaseHoverColor: withAlpha(surfaceText, 0.08)
    readonly property color widgetBaseBackgroundColor: "transparent"

    // surfaces
    readonly property real popupTransparency: F.Settings.data.appearance.panelOpacity ?? 1
    readonly property real floatingWindowTransparency: popupTransparency
    readonly property color floatingSurface: withAlpha(surfaceContainer, popupTransparency)
    readonly property color nestedSurface: withAlpha(surfaceContainerHigh, popupTransparency)
    readonly property color readableSurface: withAlpha(surfaceContainer, popupTransparency)
    readonly property color floatingWindowSurface: withAlpha(surfaceContainer, floatingWindowTransparency)
    readonly property color floatingWindowSurfaceHigh: withAlpha(surfaceContainerHigh, floatingWindowTransparency)
    readonly property color floatingWindowNestedSurface: floatingWindowSurfaceHigh
    readonly property color hostSurface: surfaceContainer
    readonly property color cardSurface: surfaceContainerHigh
    readonly property color chipSurface: surfaceContainerHighest
    readonly property color chipSurfaceNested: surfaceContainerHighest
    readonly property bool blurLayersActive: false
    readonly property bool transparentBlurLayers: false
    readonly property bool blurForegroundLayers: false
    readonly property bool isConnectedEffect: false
    readonly property bool connectedSurfaceBlurEnabled: false
    readonly property real layerOutlineOpacity: 0.12
    readonly property int layerOutlineWidth: 1
    readonly property int outlineWidth: 1
    readonly property int focusRingWidth: 2

    // ── sizes ──
    readonly property real fontScale: F.Theme.scale
    readonly property real spacingXXS: 2
    readonly property real spacingXS: 4
    readonly property real spacingS: 8
    readonly property real spacingM: 12
    readonly property real spacingL: 16
    readonly property real spacingXL: 24
    readonly property real fontSizeTiny: Math.round(fontScale * 9)
    readonly property real fontSizeExtraSmall: Math.round(fontScale * 10)
    readonly property real fontSizeSmall: Math.round(fontScale * 12)
    readonly property real fontSizeMedium: Math.round(fontScale * 14)
    readonly property real fontSizeLarge: Math.round(fontScale * 16)
    readonly property real fontSizeXLarge: Math.round(fontScale * 20)
    readonly property real fontSizeExtraLarge: Math.round(fontScale * 20)
    readonly property real fontSizeXXLarge: Math.round(fontScale * 24)
    readonly property real fontSizeDisplay: Math.round(fontScale * 32)
    readonly property real fontSizeDisplayLarge: Math.round(fontScale * 45)
    readonly property int fontWeightNormal: Font.Normal
    readonly property int fontWeightMedium: Font.Medium
    readonly property int fontWeightBold: Font.Bold
    readonly property string fontFamily: F.Theme.fontFamily
    readonly property string monoFontFamily: F.Theme.monoFamily
    readonly property string defaultFontFamily: F.Theme.fontFamily
    readonly property string defaultMonoFontFamily: F.Theme.monoFamily
    readonly property real iconSizeSmall: 16
    readonly property real iconSize: 24
    readonly property real iconSizeMedium: 24
    readonly property real iconSizeLarge: 32
    readonly property real chipIconSize: 18
    readonly property real cornerRadius: F.Theme.rMd
    readonly property real cornerRadiusXS: F.Theme.rXs
    readonly property real cornerRadiusSmall: F.Theme.rSm
    readonly property real cornerRadiusLarge: F.Theme.rLg
    readonly property real radius: F.Theme.rMd
    readonly property real fullRadius: 1000
    readonly property real buttonHeightXXS: 24
    readonly property real buttonHeightXS: 28
    readonly property real buttonHeightS: 32
    readonly property real buttonHeightM: 40
    readonly property real buttonMinWidth: 64
    readonly property real fieldHeight: 40
    readonly property real listItemHeight: 48
    readonly property real listItemTwoLineHeight: 64
    readonly property real menuItemHeight: 36
    readonly property real navigationIndicatorWidth: 64
    readonly property real barHeight: F.Theme.barHeight

    // ── motion ──
    readonly property int shorterDuration: F.Theme.dur(100)
    readonly property int shortDuration: F.Theme.dur(200)
    readonly property int mediumDuration: F.Theme.dur(300)
    readonly property int longDuration: F.Theme.dur(500)
    readonly property int extraLongDuration: F.Theme.dur(1000)
    readonly property int popoutAnimationDuration: F.Theme.dur(250)
    readonly property int modalAnimationDuration: F.Theme.dur(250)
    readonly property int currentAnimationBaseDuration: F.Theme.dur(300)
    readonly property int standardEasing: Easing.OutCubic
    readonly property int emphasizedEasing: Easing.OutQuart
    readonly property var expressiveCurves: ({
            emphasized: [0.05, 0, 0.133333, 0.06, 0.166667, 0.4, 0.208333, 0.82, 0.25, 1, 1, 1],
            emphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1],
            emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1],
            standard: [0.2, 0, 0, 1, 1, 1],
            standardAccel: [0.3, 0, 1, 1, 1, 1],
            standardDecel: [0, 0, 0, 1, 1, 1],
            expressiveFastSpatial: [0.42, 1.67, 0.21, 0.9, 1, 1],
            expressiveDefaultSpatial: [0.38, 1.21, 0.22, 1, 1, 1],
            expressiveEffects: [0.34, 0.8, 0.34, 1, 1, 1]
        })
    readonly property bool springMotionDisabled: currentAnimationBaseDuration <= 0

    // ── elevation (shadows) ──
    readonly property bool elevationEnabled: true
    readonly property real elevationBlurMax: 32
    readonly property string elevationLightDirection: "top"
    readonly property var elevationLevel1: ({ blurPx: 4, offsetX: 0, offsetY: 1, spreadPx: 0, alpha: 0.2 })
    readonly property var elevationLevel2: ({ blurPx: 8, offsetX: 0, offsetY: 4, spreadPx: 0, alpha: 0.25 })
    readonly property var elevationLevel3: ({ blurPx: 12, offsetX: 0, offsetY: 6, spreadPx: 0, alpha: 0.3 })

    function elevationShadowColor(level) {
        return Qt.rgba(0, 0, 0, (level && level.alpha !== undefined) ? level.alpha : 0.3);
    }
    function elevationOffsetXFor(level, direction, fallback) {
        return 0;
    }
    function elevationOffsetYFor(level, direction, fallback) {
        return level?.offsetY ?? fallback ?? 4;
    }
    function elevationOffsetX(level, fallback) {
        return 0;
    }
    function elevationOffsetY(level, fallback) {
        return level?.offsetY ?? fallback ?? 4;
    }
    function elevationRenderPadding(level, direction, fallbackOffset, extraPadding, minPadding) {
        return Math.max(minPadding ?? 0, (level?.blurPx ?? 8) + (extraPadding ?? 0));
    }
    function springPreset(name, baseDuration) {
        return { duration: baseDuration ?? mediumDuration, damping: 1, spring: 4 };
    }
    function variantDuration(baseDuration, entering) {
        return baseDuration;
    }

    // ── helpers ──
    function withAlpha(c, a) {
        if (!c || c.r === undefined)
            return Qt.rgba(0, 0, 0, 0);
        return Qt.rgba(c.r, c.g, c.b, a);
    }
    function blendAlpha(c, a) {
        if (!c || c.r === undefined)
            return Qt.rgba(0, 0, 0, 0);
        return Qt.rgba(c.r, c.g, c.b, c.a * a);
    }
    function blend(c1, c2, r) {
        return Qt.rgba(c1.r * (1 - r) + c2.r * r, c1.g * (1 - r) + c2.g * r, c1.b * (1 - r) + c2.b * r, c1.a * (1 - r) + c2.a * r);
    }
    function hoverTint(base) {
        return isLightMode ? Qt.darker(base, 1.2) : Qt.lighter(base, 1.2);
    }
    function luminance(c) {
        return c && c.r !== undefined ? 0.299 * c.r + 0.587 * c.g + 0.114 * c.b : 0;
    }
    function isLightColor(c, threshold = 0.5) {
        return luminance(c) > threshold;
    }
    function safeColor(value, fallback) {
        return value ? value : fallback;
    }
    function snap(value, dpr) {
        const s = dpr || 1;
        return Math.round(value * s) / s;
    }
    function snapEven(value, dpr) {
        const s = dpr || 1;
        return 2 * Math.round(value * s / 2) / s;
    }
    function px(value, dpr) {
        return snap(value, dpr);
    }
    function roleColor(mode) {
        switch (mode) {
        case "primary": case "pri": return primary;
        case "primaryContainer": return primaryContainer;
        case "secondary": case "sec": return secondary;
        case "secondaryContainer": return secondaryContainer;
        case "tertiary": case "ter": return tertiary;
        case "error": return error;
        case "surface": return surface;
        case "surfaceText": return surfaceText;
        default: return primary;
        }
    }
    function resolvedFontFamily(family) {
        return family || fontFamily;
    }
    function resolvedMonoFontFamily(family) {
        return family || monoFontFamily;
    }
    function barIconSize(barThickness, offset, maximizeIcon, iconScale) {
        const off = offset !== undefined ? offset : -6;
        const size = (maximizeIcon ?? false) ? iconSizeLarge : iconSize;
        return 2 * Math.round((barThickness / 48) * (size + off) * (iconScale ?? 1) / 2);
    }
    function barTextSize(barThickness, fontScale, maximizeText) {
        const scale = barThickness / 48;
        const k = (fontScale ?? 1) * ((maximizeText ?? false) ? 1.5 : 1);
        if (scale <= 0.75)
            return Math.round(fontSizeSmall * 0.9 * k);
        return Math.round((scale >= 1.25 ? fontSizeMedium : fontSizeSmall) * k);
    }
    function getBatteryIcon(level, isCharging, batteryAvailable) {
        if (!batteryAvailable)
            return "battery_std";
        if (isCharging)
            return level >= 90 ? "battery_charging_full" : level >= 60 ? "battery_charging_80" : level >= 30 ? "battery_charging_50" : "battery_charging_20";
        return level >= 95 ? "battery_full" : level >= 80 ? "battery_6_bar" : level >= 60 ? "battery_5_bar" : level >= 40 ? "battery_4_bar" : level >= 20 ? "battery_2_bar" : "battery_alert";
    }
    function getPowerProfileIcon(profile) {
        return profile === 2 ? "bolt" : profile === 0 ? "energy_savings_leaf" : "balance";
    }
    function getPowerProfileLabel(profile) {
        return profile === 2 ? "Performance" : profile === 0 ? "Power saver" : "Balanced";
    }
    function getFillMode(modeName) {
        return modeName === "Fit" ? Image.PreserveAspectFit : modeName === "Stretch" ? Image.Stretch : Image.PreserveAspectCrop;
    }
    // theme switching is Flamenco's (Settings → Appearance)
    function switchTheme(themeName, savePrefs, enableTransition) {}
    function setLightMode(light, savePrefs, enableTransition) {
        F.Settings.data.appearance.mode = light ? "light" : "dark";
    }
    function toggleLightMode(savePrefs) {
        setLightMode(!isLightMode);
    }
}
