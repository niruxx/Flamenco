import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: "Dock"
    subtitle: "Left-click focuses an app (again to cycle its windows), middle-click opens a new window, right-click opens a menu (move to a workspace, pin, close, force quit…). Changes show right away."
    readonly property var d: Settings.data.dock
    // installed apps that aren't pinned yet, for the picker
    readonly property var pinnable: Apps.all.filter(e => !d.pinned.includes(e.id)).map(e => ({ value: e.id, label: e.name }))

    Group {
        SwitchRow { title: "Show dock"; icon: "dock_to_bottom"; target: page.d; key: "enabled" }
        ChoiceRow {
            title: "Style"
            subtitle: (page.d.style || "classic") === "panel" ? "Your apps with pills for the start button, overview, clock and weather"
                : page.d.style === "unity" ? "Ubuntu Unity's launcher: along the whole edge, the Dash button first, apps on tiles lit in their colors, pips for open windows"
                : "Just your apps"
            icon: "view_day"
            target: page.d
            key: "style"
            segWidth: 120
            options: [{ value: "classic", label: "Classic" }, { value: "panel", label: "Panel" }, { value: "unity", label: "Unity" }]
        }
        Repeater {
            model: (page.d.style || "classic") === "panel" ? [
                { k: "launcher", t: "Start button", i: "apps" }, { k: "overview", t: "Overview button", i: "overview_key" },
                { k: "clock", t: "Clock", i: "schedule" }, { k: "weather", t: "Weather", i: "partly_cloudy_day" }]
                : page.d.style === "unity" ? [{ k: "launcher", t: "Dash button", i: "apps" }] : []
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
            title: "Position"
            icon: "picture_in_picture"
            target: page.d
            key: "position"
            options: [{ value: "bottom", label: "Bottom" }, { value: "left", label: "Left" }, { value: "right", label: "Right" }]
        }
        DropdownRow {
            visible: Quickshell.screens.length > 1
            title: "Show on"
            icon: "monitor"
            target: page.d
            key: "screen"
            options: [{ value: "", label: "Every screen" }].concat(Quickshell.screens.map(s => ({ value: s.name, label: s.name + (s.model ? " · " + s.model : "") })))
        }
        SwitchRow { title: "Show running apps"; subtitle: "Apps with open windows appear even when not pinned"; icon: "apps"; target: page.d; key: "showRunning" }
        SwitchRow { visible: page.d.showRunning && page.d.style !== "unity"; title: "Separate pinned apps"; subtitle: "A line between pinned apps and the other running ones"; icon: "more_vert"; target: page.d; key: "separator" }
        SwitchRow { title: "App names on hover"; icon: "label"; target: page.d; key: "labels" }
        ChoiceRow {
            visible: page.d.style !== "unity"
            title: "Running indicator"
            icon: "more_horiz"
            target: page.d
            key: "indicator"
            options: [{ value: "line", label: "Line" }, { value: "dot", label: "Dots" }, { value: "none", label: "None" }]
        }
    }

    Group {
        title: "Hiding"
        SwitchRow { title: "Auto-hide"; subtitle: "Hidden until the pointer touches the screen edge"; icon: "visibility_off"; target: page.d; key: "autoHide" }
        SliderRow { visible: page.d.autoHide; title: "Reveal edge"; subtitle: "How close to the edge the pointer has to be"; icon: "vertical_align_bottom"; target: page.d; key: "revealSize"; from: 2; to: 24; stepSize: 1; suffix: " px" }
        SliderRow { visible: page.d.autoHide; title: "Hide after"; subtitle: "How long it stays once the pointer leaves"; icon: "timer"; target: page.d; key: "hideDelay"; from: 0; to: 2000; stepSize: 50; suffix: " ms" }
    }

    Group {
        title: "Size"
        SliderRow { title: "Icon size"; icon: "photo_size_select_large"; target: page.d; key: "iconSize"; from: 24; to: 96; stepSize: 2; suffix: " px" }
        SliderRow { title: "Icon spacing"; icon: "space_bar"; target: page.d; key: "spacing"; from: 0; to: 24; stepSize: 1; suffix: " px" }
        SwitchRow { visible: page.d.style !== "unity"; title: "Magnification"; subtitle: "Icons grow under the pointer"; icon: "zoom_in"; target: page.d; key: "magnify" }
        SliderRow { visible: page.d.magnify && page.d.style !== "unity"; title: "Magnification amount"; icon: "zoom_out_map"; target: page.d; key: "zoom"; from: 0.1; to: 1.5; stepSize: 0.05; factor: 100; suffix: "%" }
    }

    Group {
        title: "Look"
        SliderRow { visible: page.d.style !== "unity"; title: "Distance from the edge"; subtitle: "0 sits flush against the screen edge"; icon: "border_bottom"; target: page.d; key: "margin"; from: 0; to: 48; stepSize: 1; suffix: " px" }
        SliderRow { title: "Background opacity"; subtitle: "0% leaves only the icons"; icon: "opacity"; target: page.d; key: "opacity"; from: 0; to: 1; stepSize: 0.05; factor: 100; suffix: "%" }
        SliderRow { visible: page.d.style !== "unity"; title: "Corner roundness"; icon: "rounded_corner"; target: page.d; key: "roundness"; from: 0; to: 2; stepSize: 0.05; factor: 100; suffix: "%" }
        SwitchRow { visible: page.d.style !== "unity"; title: "Border"; icon: "border_style"; target: page.d; key: "border" }
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
