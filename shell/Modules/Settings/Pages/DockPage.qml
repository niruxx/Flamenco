import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: "Dock"
    subtitle: "Left-click focuses an app (again to cycle its windows), middle-click opens a new window, right-click pins or unpins."
    readonly property var d: Settings.data.dock
    // installed apps that aren't pinned yet, for the picker
    readonly property var pinnable: Apps.all.filter(e => !d.pinned.includes(e.id)).map(e => ({ value: e.id, label: e.name }))

    Group {
        SwitchRow { title: "Show dock"; icon: "dock_to_bottom"; target: page.d; key: "enabled" }
        SwitchRow { title: "Auto-hide"; subtitle: "Hidden until the pointer touches the bottom edge of the screen"; icon: "visibility_off"; target: page.d; key: "autoHide" }
        SliderRow { visible: page.d.autoHide; title: "Reveal edge"; subtitle: "How close to the bottom edge the pointer has to be"; icon: "vertical_align_bottom"; target: page.d; key: "revealSize"; from: 2; to: 24; stepSize: 1; suffix: "px" }
        SwitchRow { title: "Show running apps"; subtitle: "Apps with open windows appear even when not pinned"; icon: "apps"; target: page.d; key: "showRunning" }
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
                required property int index
                readonly property var entry: Apps.lookup(modelData)
                title: entry?.name ?? modelData
                subtitle: entry ? modelData : modelData + " · not installed, hidden from the dock"
                icon: "drag_indicator"

                Row {
                    spacing: 4
                    AppIcon { implicitSize: 28; name: pr.entry?.icon ?? pr.modelData; anchors.verticalCenter: parent.verticalCenter }
                    FIconButton { icon: "arrow_upward"; size: 30; disabled: pr.index === 0; onClicked: Settings.listMove(page.d, "pinned", pr.index, pr.index - 1) }
                    FIconButton { icon: "arrow_downward"; size: 30; disabled: pr.index === page.d.pinned.length - 1; onClicked: Settings.listMove(page.d, "pinned", pr.index, pr.index + 1) }
                    FIconButton { icon: "close"; size: 30; iconColor: Theme.error; onClicked: Settings.listRemove(page.d, "pinned", pr.modelData) }
                }
            }
        }

        SettingRow {
            title: "Pin an app"
            icon: "push_pin"
            FDropdown {
                implicitWidth: 280
                placeholder: "Choose an app…"
                options: page.pinnable
                current: ""
                onSelected: v => Settings.listAdd(page.d, "pinned", v)
            }
        }
    }
}
