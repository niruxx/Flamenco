import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.Commons
import qs.Services
import qs.Widgets

// Settings → Bluetooth: on or off, whether others can find this computer, your
// devices (connect, disconnect, forget) and the ones nearby (pair, with the code
// or PIN they ask for). It looks for devices while it's open.
Page {
    id: page
    title: "Bluetooth"
    subtitle: "Pair headphones, keyboards, mice, phones and other devices. Put a device in pairing mode and it shows up under Nearby."
    readonly property var ad: BluetoothState.adapter
    property string forgetting: ""            // asks once more before forgetting

    // scanning while the page is on screen
    readonly property bool shown: Panels.settingsOpen && Panels.settingsPage === "bluetooth"
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

    Group {
        SettingRow {
            title: "Bluetooth"
            subtitle: !BluetoothState.available ? "No Bluetooth adapter found (is bluetooth.service running? Settings → System check)"
                : BluetoothState.enabled ? (BluetoothState.connected.length ? "Connected to " + BluetoothState.connected.map(d => d.name).join(", ") : "On") : "Off"
            icon: BluetoothState.icon
            FSwitch {
                enabled: BluetoothState.available
                checked: BluetoothState.enabled
                onToggled: c => BluetoothState.setEnabled(c)
            }
        }
        SettingRow {
            visible: BluetoothState.enabled
            title: "Visible as “" + (page.ad?.name ?? "") + "”"
            subtitle: (page.ad?.discoverable ?? false) ? "Other devices can find this computer now" : "Other devices can't find this computer (devices you pair from here don't need this)"
            icon: "visibility"
            FSwitch {
                checked: page.ad?.discoverable ?? false
                onToggled: c => {
                    if (page.ad)
                        page.ad.discoverable = c;
                }
            }
        }
    }

    BluetoothPairCard { Layout.fillWidth: true }

    Group {
        visible: BluetoothState.enabled
        title: "My devices"
        SettingRow {
            visible: BluetoothState.mine.length === 0
            title: "None yet"
            subtitle: "Devices you pair show up here"
            icon: "info"
        }
        Repeater {
            model: BluetoothState.enabled ? BluetoothState.mine : []
            SettingRow {
                id: drow
                required property var modelData
                readonly property bool moving: modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting
                title: modelData.name || modelData.address
                subtitle: (moving ? (modelData.state === BluetoothDeviceState.Connecting ? "Connecting…" : "Disconnecting…") : modelData.connected ? "Connected" : "Not connected")
                    + (modelData.batteryAvailable ? " · battery " + Math.round(modelData.battery * 100) + "%" : "")
                icon: BluetoothState.kindIcon(modelData)
                Row {
                    spacing: 6
                    FButton {
                        text: drow.modelData.connected ? "Disconnect" : "Connect"
                        variant: drow.modelData.connected ? "tonal" : "filled"
                        disabled: drow.moving
                        onClicked: BluetoothState.toggleDevice(drow.modelData)
                    }
                    FButton {
                        text: page.forgetting === drow.modelData.address ? "Sure?" : "Forget"
                        variant: "text"
                        onClicked: {
                            if (page.forgetting === drow.modelData.address) {
                                BluetoothState.forget(drow.modelData);
                                page.forgetting = "";
                            } else {
                                page.forgetting = drow.modelData.address;
                            }
                        }
                    }
                }
            }
        }
    }

    Group {
        visible: BluetoothState.enabled
        title: "Options"
        SwitchRow { title: "Reconnect my devices"; subtitle: "When Bluetooth comes on (and at login), devices you've paired and trust connect again"; icon: "bluetooth_connected"; target: Settings.data.bluetooth; key: "autoConnect" }
        SwitchRow { title: "Signal strength"; subtitle: "How close nearby devices are, while searching"; icon: "signal_cellular_alt"; target: Settings.data.bluetooth; key: "signal" }
        SwitchRow { title: "Devices without a name"; subtitle: "Some devices only give an address until they're paired"; icon: "help"; target: Settings.data.bluetooth; key: "showUnnamed" }
    }

    Group {
        visible: BluetoothState.enabled
        title: "Nearby"
        SettingRow {
            title: BluetoothState.scanning ? "Searching…" : "Not searching"
            subtitle: BluetoothState.nearby.length ? BluetoothState.nearby.length + " found" : "Put the device in pairing mode (often: hold its power or Bluetooth button until a light blinks)"
            icon: "bluetooth_searching"
            FButton {
                text: BluetoothState.scanning ? "Stop" : "Search again"
                variant: "tonal"
                onClicked: BluetoothState.scanning ? BluetoothState.stopScan() : BluetoothState.startScan()
            }
        }
        Repeater {
            model: BluetoothState.enabled ? BluetoothState.nearby : []
            SettingRow {
                id: nrow
                required property var modelData
                readonly property int bars: BluetoothState.bars(modelData)
                title: modelData.name || modelData.address
                subtitle: (bars > 0 ? ["", "Weak signal", "Fair signal", "Good signal", "Strong signal"][bars] + " · " : "") + modelData.address
                icon: BluetoothState.kindIcon(modelData)
                FButton {
                    text: BluetoothState.pairing === nrow.modelData.address ? "Pairing…" : "Pair"
                    disabled: BluetoothState.pairing !== ""
                    onClicked: BluetoothState.pair(nrow.modelData)
                }
            }
        }
    }
}
