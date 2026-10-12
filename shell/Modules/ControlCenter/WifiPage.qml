import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

DetailPage {
    id: page
    title: "Wi-Fi"
    property string askFor: ""

    Component.onCompleted: Network.scan(true)

    headerExtra: [
        FIconButton {
            icon: "refresh"
            onClicked: Network.scan(true)
            RotationAnimation on rotation { running: Network.scanning; from: 0; to: 360; duration: 900; loops: Animation.Infinite }
        },
        FSwitch {
            anchors.verticalCenter: parent.verticalCenter
            checked: Network.wifiEnabled
            onToggled: c => Network.setWifi(c)
        }
    ]

    FText {
        visible: Network.lastError !== ""
        Layout.fillWidth: true
        text: Network.lastError
        color: Theme.error
        wrapMode: Text.Wrap
        font.pixelSize: Theme.fsSm
    }

    Repeater {
        model: Network.networks

        ColumnLayout {
            required property var modelData
            Layout.fillWidth: true
            spacing: 6

            ListRow {
                icon: modelData.signal > 75 ? "signal_wifi_4_bar" : modelData.signal > 50 ? "network_wifi_3_bar" : modelData.signal > 25 ? "network_wifi_2_bar" : "network_wifi_1_bar"
                title: modelData.ssid
                subtitle: modelData.active ? "Connected" : Network.connecting === modelData.ssid ? "Connecting…" : (modelData.secure ? "Secured" : "Open") + " · " + modelData.signal + "%"
                selected: modelData.active
                onClicked: {
                    if (modelData.active)
                        Network.disconnect();
                    else if (modelData.secure)
                        page.askFor = page.askFor === modelData.ssid ? "" : modelData.ssid;
                    else
                        Network.connect(modelData.ssid, "");
                }
                FIcon {
                    visible: modelData.secure
                    icon: "lock"
                    size: 16
                    color: Theme.textDim
                }
            }

            RowLayout {
                visible: page.askFor === modelData.ssid
                Layout.fillWidth: true
                FTextField {
                    id: pw
                    Layout.fillWidth: true
                    password: true
                    icon: "key"
                    placeholder: "Password (blank = saved)"
                    onAccepted: {
                        Network.connect(modelData.ssid, text);
                        page.askFor = "";
                        text = "";
                    }
                    onVisibleChanged: if (visible) focusInput()
                }
                FButton {
                    text: "Join"
                    onClicked: pw.accepted()
                }
            }
        }
    }
}
