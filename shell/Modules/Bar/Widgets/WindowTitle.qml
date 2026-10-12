import QtQuick
import qs.Commons
import qs.Services
import qs.Widgets

// Focused window: icon + title (icon only on a vertical bar).
BarFlow {
    id: root
    readonly property var win: Niri.focusedWindow
    property bool barVisible: win !== null
    spacing: 8

    AppIcon {
        implicitSize: 18
        name: Apps.iconFor(root.win?.app_id ?? "")
    }

    FText {
        visible: !Theme.barVertical
        width: Math.min(implicitWidth, 280)
        text: root.win?.title ?? ""
        elide: Text.ElideRight
        font.pixelSize: Theme.fsSm
        font.weight: Font.Medium
    }
}
