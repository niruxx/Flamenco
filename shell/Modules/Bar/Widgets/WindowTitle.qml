import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

RowLayout {
    id: root
    readonly property var win: Niri.focusedWindow
    spacing: 8
    property bool barVisible: win !== null

    AppIcon {
        implicitSize: 18
        name: Apps.iconFor(root.win?.app_id ?? "")
    }

    FText {
        Layout.maximumWidth: 280
        text: root.win?.title ?? ""
        elide: Text.ElideRight
        font.pixelSize: Theme.fsSm
        font.weight: Font.Medium
    }
}
