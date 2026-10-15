pragma Singleton
pragma ComponentBehavior: Bound
// Vendored from https://github.com/AvengeMedia/DankMaterialShell (v1.6) and dank-qml-common (stable-1.6) (MIT) by tools/compat-vendor.py.
// Don't edit: change the vendoring tool or a Flamenco shim next to it.

import QtQuick
import Quickshell

Singleton {
    property var backend: null

    readonly property var _noop: ({
            debug: function () {},
            info: function () {},
            warn: function () {},
            error: function () {},
            fatal: function () {}
        })

    function scoped(module) {
        return backend ? backend.scoped(module) : _noop;
    }
}
