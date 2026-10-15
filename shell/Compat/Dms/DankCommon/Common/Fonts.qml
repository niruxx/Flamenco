pragma Singleton

import QtQuick
import Quickshell
import qs.Commons as F

// Flamenco shim for DankCommon's Fonts: Flamenco's fonts and its Material Symbols.
Singleton {
    readonly property string sans: F.Theme.fontFamily
    readonly property string mono: F.Theme.monoFamily
    readonly property string icons: F.Theme.iconFont
    readonly property string nerd: F.Theme.monoFamily
}
