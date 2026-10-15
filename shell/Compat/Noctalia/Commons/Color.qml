pragma Singleton

import QtQuick
import Quickshell
import qs.Commons as F

// Flamenco shim: Noctalia's color roles, taken from Flamenco's palette.
Singleton {
    id: root

    readonly property color mPrimary: F.Theme.accent
    readonly property color mOnPrimary: F.Theme.onAccent
    readonly property color mSecondary: F.Theme.accent2
    readonly property color mOnSecondary: F.Theme.onAccent
    readonly property color mTertiary: F.Theme.accent3
    readonly property color mOnTertiary: F.Theme.onAccent
    readonly property color mError: F.Theme.error
    readonly property color mOnError: F.Theme.dark ? "#1d1012" : "#ffffff"
    readonly property color mWarning: F.Theme.warning
    readonly property color mSuccess: F.Theme.success
    readonly property color mSurface: F.Theme.surface
    readonly property color mOnSurface: F.Theme.text
    readonly property color mSurfaceVariant: F.Theme.surfaceHigh
    readonly property color mOnSurfaceVariant: F.Theme.textDim
    readonly property color mOutline: F.Theme.border
    readonly property color mOutlineVariant: F.Theme.alpha(F.Theme.border, 0.6)
    readonly property color mShadow: F.Theme.shadow
    readonly property color mBackground: F.Theme.bg
    readonly property color mOnBackground: F.Theme.text
    readonly property color mHover: F.Theme.accent2
    readonly property color mOnHover: F.Theme.onAccent
    readonly property color mPrimaryContainer: F.Theme.alpha(F.Theme.accent, 0.24)
    readonly property color mOnPrimaryContainer: F.Theme.text
    readonly property color mSecondaryContainer: F.Theme.alpha(F.Theme.accent2, 0.24)
    readonly property color mOnSecondaryContainer: F.Theme.text
    readonly property color mTertiaryContainer: F.Theme.alpha(F.Theme.accent3, 0.24)
    readonly property color mOnTertiaryContainer: F.Theme.text
    readonly property color mSurfaceContainer: F.Theme.surface
    readonly property color mSurfaceContainerHigh: F.Theme.surfaceHigh
    readonly property color mSurfaceContainerHighest: F.Theme.surfaceHighest

    property bool isTransitioning: false
    property bool reloadColors: false
    property bool skipTransition: true

    readonly property var colorKeyModel: [
        { "key": "none", "name": "None" },
        { "key": "primary", "name": "Primary" },
        { "key": "secondary", "name": "Secondary" },
        { "key": "tertiary", "name": "Tertiary" },
        { "key": "error", "name": "Error" }
    ]

    function resolveColorKey(key) {
        switch (key) {
        case "primary": return mPrimary;
        case "secondary": return mSecondary;
        case "tertiary": return mTertiary;
        case "error": return mError;
        default: return mOnSurface;
        }
    }
    function resolveOnColorKey(key) {
        switch (key) {
        case "primary": return mOnPrimary;
        case "secondary": return mOnSecondary;
        case "tertiary": return mOnTertiary;
        case "error": return mOnError;
        default: return mSurface;
        }
    }
    function resolveColorKeyOptional(key) {
        switch (key) {
        case "primary": return mPrimary;
        case "secondary": return mSecondary;
        case "tertiary": return mTertiary;
        case "error": return mError;
        default: return "transparent";
        }
    }
    function adaptiveOpacity(baseOpacity) {
        return F.Theme.dark ? baseOpacity : Math.pow(baseOpacity, 1.5);
    }
    function smartAlpha(baseColor, minAlpha = 0.4) {
        const a = Math.max(adaptiveOpacity(F.Settings.data.appearance.panelOpacity ?? 1), minAlpha);
        return Qt.alpha(baseColor, Math.max(0, baseColor.a - (1.0 - a)));
    }
}
