import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: "Quick settings"
    subtitle: "Where the quick settings panel opens, how wide it is, and what's in it."
    readonly property var q: Settings.data.control
    readonly property var all: [
        { id: "wifi", label: "Wi-Fi", icon: "wifi" }, { id: "bluetooth", label: "Bluetooth", icon: "bluetooth" },
        { id: "dnd", label: "Do not disturb", icon: "do_not_disturb_on" }, { id: "night", label: "Night light", icon: "nightlight" },
        { id: "caffeine", label: "Caffeine", icon: "coffee" }, { id: "power", label: "Power profile", icon: "bolt" },
        { id: "vpn", label: "VPN", icon: "vpn_key" }, { id: "dark", label: "Dark mode", icon: "dark_mode" },
        { id: "record", label: "Record screen", icon: "screen_record" }, { id: "widgets", label: "Desktop widgets", icon: "widgets" },
        { id: "wallpaper", label: "Wallpaper", icon: "wallpaper" }
    ]
    // shown tiles in order ([] means all, default order)
    readonly property var shown: q.tiles && q.tiles.length ? q.tiles.filter(t => all.some(a => a.id === t)) : all.map(a => a.id)
    readonly property var rows: shown.concat(all.map(a => a.id).filter(t => !shown.includes(t)))
    function setSection(k, v) {
        const s = Object.assign({ header: true, sliders: true, tiles: true, media: true }, q.sections || {});
        s[k] = v;
        q.sections = s;
    }

    Group {
        title: "Look"
        ChoiceRow {
            title: "Style"
            subtitle: page.q.style === "classic" ? "Icon beside the text, slim sliders" : page.q.style === "cards" ? "Icon on top, tinted when on, big sliders (like the dashboard)" : "Pill tiles in two columns, half or full width, that you arrange yourself"
            icon: "view_module"
            target: page.q
            key: "style"
            segWidth: 120
            options: [{ value: "grid", label: "Grid", icon: "dashboard_customize" }, { value: "cards", label: "Cards", icon: "grid_view" }, { value: "classic", label: "Classic", icon: "view_list" }]
        }
        SettingRow {
            visible: (page.q.style || "grid") === "grid"
            title: "Arranging the grid"
            subtitle: "Press and hold any tile in quick settings: remove (−), make it half or full width, drag it, add widgets, then ✓. The tile choices below are for the Cards and Classic styles"
            icon: "touch_app"
            FButton {
                text: "Reset the grid"
                variant: "text"
                disabled: !(page.q.grid || []).length
                onClicked: page.q.grid = []
            }
        }
    }

    Group {
        title: "Placement"
        ChoiceRow {
            title: "Opens"
            subtitle: page.q.align === "auto" ? "On the side of the bar where its button is" : ""
            icon: "align_horizontal_right"
            target: page.q
            key: "align"
            segWidth: 120
            options: [{ value: "auto", label: "By its button" }, { value: "left", label: "Left" }, { value: "center", label: "Center" }, { value: "right", label: "Right" }]
        }
        SliderRow { title: "Width"; icon: "width"; target: page.q; key: "width"; from: 340; to: 640; stepSize: 10; suffix: " px" }
        ChoiceRow {
            title: "Tile columns"
            icon: "grid_view"
            target: page.q
            key: "columns"
            options: [{ value: 1, label: "1" }, { value: 2, label: "2" }, { value: 3, label: "3" }]
        }
    }

    Group {
        title: "Sections"
        Repeater {
            model: [{ k: "header", label: "Your name, uptime, and settings / lock / power buttons", icon: "account_circle" },
                { k: "sliders", label: "Volume, microphone and brightness sliders", icon: "tune" },
                { k: "tiles", label: "Tiles", icon: "grid_view" },
                { k: "media", label: "What's playing (while something is)", icon: "music_note" }]
            SettingRow {
                required property var modelData
                title: modelData.label
                icon: modelData.icon
                FSwitch {
                    checked: (page.q.sections || {})[modelData.k] !== false
                    onToggled: c => page.setSection(modelData.k, c)
                }
            }
        }
    }

    Group {
        title: "Tiles"
        visible: (page.q.sections || {}).tiles !== false
        Repeater {
            model: page.rows
            SettingRow {
                id: tr
                required property string modelData
                required property int index
                readonly property var info: page.all.find(a => a.id === modelData)
                readonly property bool on: page.shown.includes(modelData)
                readonly property int pos: page.shown.indexOf(modelData)
                title: info.label
                icon: info.icon
                opacity: on ? 1 : 0.6
                Row {
                    spacing: 4
                    FIconButton { visible: tr.on; icon: "arrow_upward"; size: 30; disabled: tr.pos === 0; onClicked: { const l = page.shown.slice(); l.splice(tr.pos - 1, 0, l.splice(tr.pos, 1)[0]); page.q.tiles = l; } }
                    FIconButton { visible: tr.on; icon: "arrow_downward"; size: 30; disabled: tr.pos === page.shown.length - 1; onClicked: { const l = page.shown.slice(); l.splice(tr.pos + 1, 0, l.splice(tr.pos, 1)[0]); page.q.tiles = l; } }
                    FSwitch {
                        anchors.verticalCenter: parent.verticalCenter
                        checked: tr.on
                        onToggled: c => {
                            const l = c ? page.shown.concat([tr.modelData]) : page.shown.filter(t => t !== tr.modelData);
                            // none left: hide the section ([] would mean "all tiles")
                            if (l.length === 0)
                                page.setSection("tiles", false);
                            else
                                page.q.tiles = l;
                        }
                    }
                }
            }
        }
        SettingRow {
            title: "Back to the default tiles"
            icon: "restart_alt"
            FButton {
                text: "Reset"
                variant: "text"
                onClicked: page.q.tiles = []
            }
        }
    }
}
