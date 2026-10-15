pragma Singleton
// Vendored from https://github.com/AvengeMedia/DankMaterialShell (v1.6) and dank-qml-common (stable-1.6) (MIT) by tools/compat-vendor.py.
// Don't edit: change the vendoring tool or a Flamenco shim next to it.

import Quickshell
import qs.Compat.Dms.DankCommon.Common as DankCommon

Singleton {
    readonly property int noTimeout: DankCommon.Proc.noTimeout
    readonly property string dmsBin: DankCommon.Proc.dmsBin

    function runCommand(id, command, callback, debounceMs, timeoutMs, owner) {
        DankCommon.Proc.runCommand(id, command, callback, debounceMs, timeoutMs, owner);
    }

    function release(id) {
        DankCommon.Proc.release(id);
    }
}
