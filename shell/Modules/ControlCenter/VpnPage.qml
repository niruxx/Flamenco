import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

DetailPage {
    title: I18n.tr("VPN")

    headerExtra: [
        FIconButton {
            icon: "settings"
            onClicked: Panels.openSettings("network")
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

    ColumnLayout {
        visible: Network.vpns.length === 0
        Layout.fillWidth: true
        Layout.topMargin: Theme.sp4
        spacing: Theme.sp2
        FIcon { Layout.alignment: Qt.AlignHCenter; icon: "vpn_lock"; size: 44; color: Theme.textDim }
        FText { Layout.alignment: Qt.AlignHCenter; text: I18n.tr("No VPN connections"); font.weight: Font.Bold }
        FText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: I18n.tr("Import a WireGuard (.conf) or OpenVPN (.ovpn) file in Settings → Network.")
            dim: true
            wrapMode: Text.Wrap
        }
    }

    Repeater {
        model: Network.vpns
        ListRow {
            required property var modelData
            icon: modelData.active ? "vpn_lock" : "vpn_key"
            title: modelData.name
            subtitle: (modelData.type === "wireguard" ? I18n.tr("WireGuard") : I18n.tr("VPN")) + " · " + (Network.vpnBusy === modelData.name ? "working…" : modelData.active ? I18n.tr("Connected") : I18n.tr("Disconnected"))
            selected: modelData.active
            busy: Network.vpnBusy === modelData.name
            onClicked: Network.setVpn(modelData.name, !modelData.active)
            FSwitch {
                anchors.verticalCenter: parent.verticalCenter
                checked: modelData.active
                onToggled: c => Network.setVpn(modelData.name, c)
            }
        }
    }
}
