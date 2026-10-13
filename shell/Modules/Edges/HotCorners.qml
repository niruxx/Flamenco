import QtQuick
import Quickshell
import qs.Commons

// Hot corners: a few pixels in each screen corner that run an action once
// the pointer rests there (Settings → Screen edges).
Variants {
    model: Settings.data.edges.enabled ? Quickshell.screens : []

    Scope {
        id: scope
        required property ShellScreen modelData

        Corner { output: scope.modelData; key: "topLeft"; atTop: true; atLeft: true }
        Corner { output: scope.modelData; key: "topRight"; atTop: true; atLeft: false }
        Corner { output: scope.modelData; key: "bottomLeft"; atTop: false; atLeft: true }
        Corner { output: scope.modelData; key: "bottomRight"; atTop: false; atLeft: false }
    }
}
