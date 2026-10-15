// Vendored from https://github.com/AvengeMedia/DankMaterialShell (v1.6) and dank-qml-common (stable-1.6) (MIT) by tools/compat-vendor.py.
// Don't edit: change the vendoring tool or a Flamenco shim next to it.
import QtQuick
import qs.Compat.Dms.DankCommon.Common

Rectangle {
    id: root

    property bool shown: true
    property bool blinkOn: true
    property int blinkTimeout: 10000

    readonly property int flashTime: Qt.styleHints.cursorFlashTime
    readonly property bool blinkEnabled: shown && flashTime > 1

    function resetBlink() {
        blinkOn = true;
        if (!blinkEnabled)
            return;
        blinkTimer.restart();
        if (blinkTimeout <= 0)
            return;
        blinkTimeoutTimer.restart();
    }

    width: 2
    radius: 1
    color: Style.primary
    visible: shown && blinkOn

    onShownChanged: resetBlink()

    Timer {
        id: blinkTimer
        running: root.blinkEnabled
        interval: root.flashTime / 2
        repeat: true
        onTriggered: root.blinkOn = !root.blinkOn
    }

    Timer {
        id: blinkTimeoutTimer
        running: blinkTimer.running && root.blinkTimeout > 0
        interval: root.blinkTimeout
        onTriggered: {
            blinkTimer.stop();
            root.blinkOn = true;
        }
    }
}
