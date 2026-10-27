import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.Commons
import qs.Services
import qs.Widgets

// Quick settings → Bluetooth: your devices (click to connect or disconnect) and the
// ones nearby (click to pair). It looks for devices while it's open; the radar
// button shows that and starts a new search.
DetailPage {
    id: page
    title: I18n.tr("Bluetooth")

    // scanning while it's on screen (quick settings keeps the page when it closes)
    readonly property bool shown: Panels.current === "control" && Panels.controlDetail === "bluetooth"
    property bool watching: false
    function follow() {
        if (shown !== watching) {
            watching = shown;
            BluetoothState.watch(shown);
        }
    }
    onShownChanged: follow()
    Component.onCompleted: follow()
    Component.onDestruction: if (watching) BluetoothState.watch(false)

    headerExtra: [
        FIconButton {
            icon: "radar"
            active: BluetoothState.scanning
            disabled: !BluetoothState.enabled
            onClicked: BluetoothState.scanning ? BluetoothState.stopScan() : BluetoothState.startScan()
        },
        FSwitch {
            anchors.verticalCenter: parent.verticalCenter
            checked: BluetoothState.enabled
            onToggled: c => BluetoothState.setEnabled(c)
        }
    ]

    FText {
        Layout.fillWidth: true
        visible: !BluetoothState.available || !BluetoothState.enabled
        text: !BluetoothState.available ? I18n.tr("No Bluetooth adapter (is bluetooth.service running?)") : I18n.tr("Bluetooth is off")
        dim: true
        wrapMode: Text.Wrap
    }

    BluetoothPairCard { Layout.fillWidth: true }

    FText {
        visible: BluetoothState.enabled && BluetoothState.mine.length > 0
        text: I18n.tr("My devices")
        font.pixelSize: Theme.fsSm
        font.weight: Font.DemiBold
        color: Theme.accent
    }
    Repeater {
        model: BluetoothState.enabled ? BluetoothState.mine : []
        ListRow {
            required property var modelData
            icon: BluetoothState.kindIcon(modelData)
            title: modelData.name || modelData.address
            subtitle: (modelData.connected ? I18n.tr("Connected") : I18n.tr("Not connected")) + (modelData.batteryAvailable ? " · " + Math.round(modelData.battery * 100) + "%" : "")
            selected: modelData.connected
            busy: modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting
            onClicked: BluetoothState.toggleDevice(modelData)
        }
    }

    RowLayout {
        visible: BluetoothState.enabled
        Layout.fillWidth: true
        Layout.topMargin: Theme.sp2
        FText {
            text: I18n.tr("Nearby")
            font.pixelSize: Theme.fsSm
            font.weight: Font.DemiBold
            color: Theme.accent
        }
        FText {
            Layout.fillWidth: true
            text: BluetoothState.scanning ? I18n.tr("Searching…") : ""
            dim: true
            font.pixelSize: Theme.fsXs
        }
    }
    Repeater {
        model: BluetoothState.enabled ? BluetoothState.nearby : []
        ListRow {
            required property var modelData
            icon: BluetoothState.kindIcon(modelData)
            title: modelData.name || modelData.address
            subtitle: BluetoothState.pairing === modelData.address ? I18n.tr("Pairing…") : I18n.tr("Click to pair") + (BluetoothState.bars(modelData) > 0 ? " · " + ["", "weak", "fair", "good", "strong"][BluetoothState.bars(modelData)] + " signal" : "")
            busy: BluetoothState.pairing === modelData.address
            onClicked: BluetoothState.pair(modelData)
        }
    }
    FText {
        Layout.fillWidth: true
        visible: BluetoothState.enabled && BluetoothState.nearby.length === 0
        text: BluetoothState.scanning ? I18n.tr("Put the device in pairing mode; it shows up here") : I18n.tr("Nothing nearby. Press the radar to look again")
        dim: true
        font.pixelSize: Theme.fsSm
        wrapMode: Text.Wrap
    }
}
