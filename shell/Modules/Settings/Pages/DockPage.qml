import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: I18n.tr("Dock")
    subtitle: I18n.tr("Left-click focuses an app (again to cycle its windows), middle-click opens a new window, right-click opens a menu (move to a workspace, pin, close, force quit…). Changes show right away.")
    readonly property var d: Settings.data.dock
    // installed apps that aren't pinned yet, for the picker
    readonly property var pinnable: Apps.all.filter(e => !d.pinned.includes(e.id)).map(e => ({ value: e.id, label: e.name }))

    Group {
        SwitchRow { title: I18n.tr("Show dock"); icon: "dock_to_bottom"; target: page.d; key: "enabled" }
        ChoiceRow {
            title: I18n.tr("Style")
            subtitle: (page.d.style || "classic") === "panel" ? I18n.tr("Your apps with pills for the start button, overview, clock and weather")
                : page.d.style === "unity" ? "Ubuntu Unity's launcher: along the whole edge, the Dash button first, apps on tiles lit in their colors, pips for open windows"
                : "Just your apps"
            icon: "view_day"
            target: page.d
            key: "style"
            segWidth: 120
            options: [{ value: "classic", label: I18n.tr("Classic") }, { value: "panel", label: I18n.tr("Panel") }, { value: "unity", label: I18n.tr("Unity") }]
        }
        Repeater {
            model: (page.d.style || "classic") === "panel" ? [
                { k: "launcher", t: I18n.tr("Start button"), i: "apps" }, { k: "overview", t: I18n.tr("Overview button"), i: "overview_key" },
                { k: "clock", t: I18n.tr("Clock"), i: "schedule" }, { k: "weather", t: I18n.tr("Weather"), i: "partly_cloudy_day" }]
                : page.d.style === "unity" ? [{ k: "launcher", t: I18n.tr("Dash button"), i: "apps" }] : []
            SettingRow {
                id: prow
                required property var modelData
                title: modelData.t
                icon: modelData.i
                FSwitch {
                    checked: (page.d.parts || {})[prow.modelData.k] !== false
                    onToggled: c => {
                        const p = Object.assign({}, page.d.parts || {});
                        p[prow.modelData.k] = c;
                        page.d.parts = p;
                    }
                }
            }
        }
        ChoiceRow {
            title: I18n.tr("Position")
            icon: "picture_in_picture"
            target: page.d
            key: "position"
            options: [{ value: "bottom", label: I18n.tr("Bottom") }, { value: "left", label: I18n.tr("Left") }, { value: "right", label: I18n.tr("Right") }]
        }
        DropdownRow {
            visible: Quickshell.screens.length > 1
            title: I18n.tr("Show on")
            icon: "monitor"
            target: page.d
            key: "screen"
            options: [{ value: "", label: I18n.tr("Every screen") }].concat(Quickshell.screens.map(s => ({ value: s.name, label: s.name + (s.model ? " · " + s.model : "") })))
        }
        SwitchRow { title: I18n.tr("Show running apps"); subtitle: I18n.tr("Apps with open windows appear even when not pinned"); icon: "apps"; target: page.d; key: "showRunning" }
        SwitchRow { visible: page.d.showRunning && page.d.style !== "unity"; title: I18n.tr("Separate pinned apps"); subtitle: I18n.tr("A line between pinned apps and the other running ones"); icon: "more_vert"; target: page.d; key: "separator" }
        SwitchRow { title: I18n.tr("App names on hover"); icon: "label"; target: page.d; key: "labels" }
        ChoiceRow {
            visible: page.d.style !== "unity"
            title: I18n.tr("Running indicator")
            icon: "more_horiz"
            target: page.d
            key: "indicator"
            options: [{ value: "line", label: I18n.tr("Line") }, { value: "dot", label: I18n.tr("Dot") }, { value: "count", label: I18n.tr("Count") }, { value: "none", label: I18n.tr("None") }]
        }
        SwitchRow { title: I18n.tr("Only this screen's apps"); subtitle: I18n.tr("Running apps (and window counts) from the dock's own screen; pinned apps always show"); icon: "monitor"; target: page.d; key: "thisScreen" }
    }

    Group {
        title: I18n.tr("Hiding")
        SwitchRow { title: I18n.tr("Auto-hide"); subtitle: I18n.tr("Hidden until the pointer touches the screen edge"); icon: "visibility_off"; target: page.d; key: "autoHide" }
        SliderRow { visible: page.d.autoHide; title: I18n.tr("Reveal edge"); subtitle: I18n.tr("How close to the edge the pointer has to be"); icon: "vertical_align_bottom"; target: page.d; key: "revealSize"; from: 2; to: 24; stepSize: 1; suffix: " px" }
        SliderRow { visible: page.d.autoHide; title: I18n.tr("Hide after"); subtitle: I18n.tr("How long it stays once the pointer leaves"); icon: "timer"; target: page.d; key: "hideDelay"; from: 0; to: 2000; stepSize: 50; suffix: " ms" }
    }

    Group {
        title: I18n.tr("Size")
        SliderRow { title: I18n.tr("Icon size"); icon: "photo_size_select_large"; target: page.d; key: "iconSize"; from: 24; to: 96; stepSize: 2; suffix: " px" }
        SliderRow { title: I18n.tr("Icon spacing"); icon: "space_bar"; target: page.d; key: "spacing"; from: 0; to: 24; stepSize: 1; suffix: " px" }
        SwitchRow { visible: page.d.style !== "unity"; title: I18n.tr("Magnification"); subtitle: I18n.tr("Icons grow under the pointer"); icon: "zoom_in"; target: page.d; key: "magnify" }
        SliderRow { visible: page.d.magnify && page.d.style !== "unity"; title: I18n.tr("Magnification amount"); icon: "zoom_out_map"; target: page.d; key: "zoom"; from: 0.1; to: 1.5; stepSize: 0.05; factor: 100; suffix: "%" }
    }

    Group {
        title: I18n.tr("Look")
        SliderRow { visible: page.d.style !== "unity"; title: I18n.tr("Distance from the edge"); subtitle: I18n.tr("0 sits flush against the screen edge"); icon: "border_bottom"; target: page.d; key: "margin"; from: 0; to: 48; stepSize: 1; suffix: " px" }
        SliderRow { title: I18n.tr("Tint icons"); subtitle: page.d.tint > 0 ? I18n.tr("Toward the accent color, so they match the theme") : I18n.tr("As the icon theme draws them"); icon: "colors"; target: page.d; key: "tint"; from: 0; to: 1; stepSize: 0.05; factor: 100; suffix: "%" }
        SliderRow { title: I18n.tr("Background opacity"); subtitle: I18n.tr("0% leaves only the icons"); icon: "opacity"; target: page.d; key: "opacity"; from: 0; to: 1; stepSize: 0.05; factor: 100; suffix: "%" }
        SliderRow { visible: page.d.style !== "unity"; title: I18n.tr("Corner roundness"); icon: "rounded_corner"; target: page.d; key: "roundness"; from: 0; to: 2; stepSize: 0.05; factor: 100; suffix: "%" }
        SwitchRow { visible: page.d.style !== "unity"; title: I18n.tr("Border"); icon: "border_style"; target: page.d; key: "border" }
    }

    Group {
        title: I18n.tr("Pinned apps")

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
            title: I18n.tr("Pin an app")
            icon: "push_pin"
            FDropdown {
                implicitWidth: 280
                placeholder: I18n.tr("Choose an app…")
                options: page.pinnable
                current: ""
                onSelected: v => Settings.listAdd(page.d, "pinned", v)
            }
        }
    }
}
