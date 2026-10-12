import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: "Dock"
    subtitle: "Right-click an icon in the dock to pin or unpin it."
    readonly property var d: Settings.data.dock

    Group {
        SwitchRow { title: "Show dock"; icon: "dock_to_bottom"; target: page.d; key: "enabled" }
        SwitchRow { title: "Auto-hide"; subtitle: "Reveal by touching the bottom edge"; icon: "visibility_off"; target: page.d; key: "autoHide" }
        SwitchRow { title: "Magnification"; icon: "zoom_in"; target: page.d; key: "magnify" }
        SliderRow { title: "Icon size"; icon: "photo_size_select_large"; target: page.d; key: "iconSize"; from: 32; to: 72; stepSize: 2; suffix: "px" }
    }

    Group {
        title: "Pinned apps"
        Repeater {
            model: page.d.pinned
            SettingRow {
                id: pr
                required property string modelData
                title: Apps.lookup(modelData)?.name ?? modelData
                subtitle: modelData
                AppIcon { implicitSize: 28; name: Apps.iconFor(pr.modelData) }
                FIconButton { x: 40; icon: "close"; size: 30; iconColor: Theme.error; onClicked: Settings.listRemove(page.d, "pinned", pr.modelData) }
            }
        }
    }
}
