pragma Singleton
pragma ComponentBehavior: Bound
// Vendored from https://github.com/AvengeMedia/DankMaterialShell (v1.6) and dank-qml-common (stable-1.6) (MIT) by tools/compat-vendor.py.
// Don't edit: change the vendoring tool or a Flamenco shim next to it.

import QtQuick
import Quickshell

Singleton {
    property var backend: null

    readonly property bool isRtl: backend?.isRtl ?? false

    function tr(term, context, isRealContext) {
        return backend ? backend.tr(term, context, isRealContext) : term;
    }
}
