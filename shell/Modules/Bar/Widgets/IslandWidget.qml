import QtQuick
import Quickshell
import qs.Commons
import qs.Services
import qs.Modules.Extras

// The Dynamic island in the bar (Settings → Desktop widgets → Dynamic island → In
// the bar): the pill sits in the bar; hovering or a notification opens it below
// (or above) in a popup, as big as the floating one.
Item {
    id: root
    property string screenName
    property var window: null
    property int barLevel: 0
    property bool barVisible: (Settings.data.island.enabled ?? false) && Settings.data.island.place === "bar"
    implicitWidth: small.width
    implicitHeight: Theme.barItem

    IslandPill {
        id: small
        inBar: true
        screenName: root.screenName
        anchors.centerIn: parent
        // in the bar it stays small; the popup shows the big one
        visible: !pop.visible
    }
    PopupWindow {
        id: pop
        anchor.item: root
        anchor.edges: Theme.barTop ? Edges.Bottom : Edges.Top
        anchor.gravity: Theme.barTop ? Edges.Bottom : Edges.Top
        anchor.margins.top: Theme.barTop ? 6 : 0
        color: "transparent"
        implicitWidth: big.width
        implicitHeight: big.height
        visible: small.showing === "full" || small.showing === "note" || small.showing === "level" || big.hovered
        IslandPill { id: big; screenName: root.screenName }
    }
}
