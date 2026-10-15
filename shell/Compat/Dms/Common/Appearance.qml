pragma Singleton
// Vendored from https://github.com/AvengeMedia/DankMaterialShell (v1.6) and dank-qml-common (stable-1.6) (MIT) by tools/compat-vendor.py.
// Don't edit: change the vendoring tool or a Flamenco shim next to it.

import Quickshell
import qs.Compat.Dms.DankCommon.Common as DankCommon

Singleton {
    readonly property var rounding: DankCommon.Appearance.rounding
    readonly property var spacing: DankCommon.Appearance.spacing
    readonly property var fontSize: DankCommon.Appearance.fontSize
    readonly property var anim: DankCommon.Appearance.anim
}
