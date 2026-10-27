import QtQuick
import qs.Commons
import qs.Services
import qs.Widgets

// VPN: lit while one is connected. Click turns the last one used on or off,
// right-click lists them (quick settings → VPN). Shown when any VPN is set up.
FIconButton {
    id: root
    property string screenName
    property int barLevel: 0
    property bool barVisible: Network.vpns.length > 0
    readonly property var target: Network.activeVpns[0] ?? Network.vpns.find(v => v.name === (Settings.data.bar.lastVpn || "")) ?? Network.vpns[0] ?? null
    size: Theme.barItem
    iconSize: Theme.barIcon
    icon: Network.vpnActive ? "vpn_lock" : "vpn_key_off"
    active: Network.vpnActive
    onClicked: {
        if (!target)
            return;
        Settings.data.bar.lastVpn = target.name;
        Network.setVpn(target.name, !target.active);
    }
    onRightClicked: Panels.openControl("vpn", root.screenName, root)
}
