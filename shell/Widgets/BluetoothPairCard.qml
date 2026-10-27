import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services

// Pairing a Bluetooth device, in quick settings and Settings → Bluetooth: what's
// going on, and what the device asks (confirm a code, type a PIN, or type a code
// shown here on a keyboard). Shown while pairing, and a moment after.
Rectangle {
    id: root
    readonly property var p: BluetoothState.prompt
    readonly property bool busy: BluetoothState.pairing !== ""
    visible: busy || BluetoothState.pairStatus !== ""
    implicitHeight: col.implicitHeight + Theme.sp3 * 2
    radius: Theme.rLg
    color: Theme.alpha(Theme.accent, 0.1)
    border.width: 1
    border.color: Theme.alpha(Theme.accent, 0.35)

    ColumnLayout {
        id: col
        x: Theme.sp3
        y: Theme.sp3
        width: parent.width - Theme.sp3 * 2
        spacing: Theme.sp2

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.sp2
            FIcon {
                icon: root.busy ? "bluetooth_searching" : BluetoothState.pairStatus === "Connected" ? "check_circle" : "info"
                color: Theme.accent
                fill: 1
            }
            FText {
                Layout.fillWidth: true
                text: root.busy ? (root.p ? BluetoothState.pairName : I18n.tr("Pairing with ") + BluetoothState.pairName + "…")
                    : BluetoothState.pairStatus === "Connected" ? BluetoothState.pairName + " is connected" : BluetoothState.pairStatus
                font.weight: Font.DemiBold
                wrapMode: Text.Wrap
            }
            FButton {
                visible: root.busy
                text: I18n.tr("Cancel")
                variant: "text"
                implicitHeight: 30
                onClicked: BluetoothState.cancelPair()
            }
        }

        // ── what it asks ──
        FText {
            Layout.fillWidth: true
            visible: !!root.p
            text: !root.p ? "" : root.p.kind === "confirm" ? I18n.tr("Does it show this code?")
                : root.p.kind === "display" ? "Type this code on it, then press Enter:"
                : root.p.kind === "pin" ? "Type its PIN (often 0000 or 1234 if it doesn't say)" : "Type the passkey it shows"
            dim: true
            wrapMode: Text.Wrap
        }
        FText {
            visible: !!root.p && (root.p.kind === "confirm" || root.p.kind === "display")
            text: root.p?.passkey ?? ""
            font.pixelSize: Theme.fsXxl
            font.weight: Font.Bold
            font.letterSpacing: 4
            mono: true
            color: Theme.accent
        }
        RowLayout {
            visible: !!root.p && root.p.kind === "confirm"
            spacing: Theme.sp2
            FButton { text: I18n.tr("Yes, it does"); icon: "check"; onClicked: BluetoothState.answer("yes") }
            FButton { text: I18n.tr("No"); variant: "tonal"; onClicked: BluetoothState.answer("no") }
        }
        RowLayout {
            visible: !!root.p && (root.p.kind === "pin" || root.p.kind === "passkey")
            Layout.fillWidth: true
            spacing: Theme.sp2
            FTextField {
                id: code
                Layout.fillWidth: true
                implicitHeight: 36
                placeholder: root.p?.kind === "pin" ? I18n.tr("PIN") : I18n.tr("Passkey")
                onAccepted: {
                    BluetoothState.answer(text.trim());
                    text = "";
                }
            }
            FButton {
                text: I18n.tr("Pair")
                disabled: code.text.trim() === ""
                onClicked: {
                    BluetoothState.answer(code.text.trim());
                    code.text = "";
                }
            }
        }
    }
}
