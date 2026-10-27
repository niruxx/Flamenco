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
    title: I18n.tr("Bluetooth")
    subtitle: I18n.tr("Pair headphones, keyboards, mice, phones and other devices. Put a device in pairing mode and it shows up under Nearby.")
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
            title: I18n.tr("Bluetooth")
            subtitle: !BluetoothState.available ? I18n.tr("No Bluetooth adapter found (is bluetooth.service running? Settings → System check)")
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
            title: I18n.tr("Visible as “") + (page.ad?.name ?? "") + "”"
            subtitle: (page.ad?.discoverable ?? false) ? I18n.tr("Other devices can find this computer now") : I18n.tr("Other devices can't find this computer (devices you pair from here don't need this)")
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
        title: I18n.tr("My devices")
        SettingRow {
            visible: BluetoothState.mine.length === 0
            title: I18n.tr("None yet")
            subtitle: I18n.tr("Devices you pair show up here")
            icon: "info"
        }
        Repeater {
            model: BluetoothState.enabled ? BluetoothState.mine : []
            SettingRow {
                id: drow
                required property var modelData
                readonly property bool moving: modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting
                title: modelData.name || modelData.address
                subtitle: (moving ? (modelData.state === BluetoothDeviceState.Connecting ? I18n.tr("Connecting…") : I18n.tr("Disconnecting…")) : modelData.connected ? I18n.tr("Connected") : I18n.tr("Not connected"))
                    + (modelData.batteryAvailable ? " · battery " + Math.round(modelData.battery * 100) + "%" : "")
                icon: BluetoothState.kindIcon(modelData)
                Row {
                    spacing: 6
                    FButton {
                        text: drow.modelData.connected ? I18n.tr("Disconnect") : I18n.tr("Connect")
                        variant: drow.modelData.connected ? "tonal" : "filled"
                        disabled: drow.moving
                        onClicked: BluetoothState.toggleDevice(drow.modelData)
                    }
                    FButton {
                        text: page.forgetting === drow.modelData.address ? I18n.tr("Sure?") : I18n.tr("Forget")
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
        title: I18n.tr("Options")
        SwitchRow { title: I18n.tr("Reconnect my devices"); subtitle: I18n.tr("When Bluetooth comes on (and at login), devices you've paired and trust connect again"); icon: "bluetooth_connected"; target: Settings.data.bluetooth; key: "autoConnect" }
        SwitchRow { title: I18n.tr("Signal strength"); subtitle: I18n.tr("How close nearby devices are, while searching"); icon: "signal_cellular_alt"; target: Settings.data.bluetooth; key: "signal" }
        SwitchRow { title: I18n.tr("Devices without a name"); subtitle: I18n.tr("Some devices only give an address until they're paired"); icon: "help"; target: Settings.data.bluetooth; key: "showUnnamed" }
    }

    Group {
        visible: BluetoothState.enabled
        title: I18n.tr("Nearby")
        SettingRow {
            title: BluetoothState.scanning ? I18n.tr("Searching…") : I18n.tr("Not searching")
            subtitle: BluetoothState.nearby.length ? BluetoothState.nearby.length + " found" : I18n.tr("Put the device in pairing mode (often: hold its power or Bluetooth button until a light blinks)")
            icon: "bluetooth_searching"
            FButton {
                text: BluetoothState.scanning ? I18n.tr("Stop") : I18n.tr("Search again")
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
                    text: BluetoothState.pairing === nrow.modelData.address ? I18n.tr("Pairing…") : I18n.tr("Pair")
                    disabled: BluetoothState.pairing !== ""
                    onClicked: BluetoothState.pair(nrow.modelData)
                }
            }
        }
    }
}
