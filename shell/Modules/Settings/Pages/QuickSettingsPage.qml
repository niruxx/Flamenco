import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: I18n.tr("Quick settings")
    subtitle: I18n.tr("Where the quick settings panel opens, how wide it is, and what's in it.")
    readonly property var q: Settings.data.control
    readonly property var all: [
        { id: "wifi", label: I18n.tr("Wi-Fi"), icon: "wifi" }, { id: "bluetooth", label: I18n.tr("Bluetooth"), icon: "bluetooth" },
        { id: "dnd", label: I18n.tr("Do not disturb"), icon: "do_not_disturb_on" }, { id: "night", label: I18n.tr("Night light"), icon: "nightlight" },
        { id: "caffeine", label: I18n.tr("Caffeine"), icon: "coffee" }, { id: "power", label: I18n.tr("Power profile"), icon: "bolt" },
        { id: "vpn", label: I18n.tr("VPN"), icon: "vpn_key" }, { id: "dark", label: I18n.tr("Dark mode"), icon: "dark_mode" },
        { id: "record", label: I18n.tr("Record screen"), icon: "screen_record" }, { id: "widgets", label: I18n.tr("Desktop widgets"), icon: "widgets" },
        { id: "wallpaper", label: I18n.tr("Wallpaper"), icon: "wallpaper" }
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
        title: I18n.tr("Look")
        ChoiceRow {
            title: I18n.tr("Style")
            subtitle: page.q.style === "pills" ? I18n.tr("Soft tonal pills, large sliders, and a focused two-column layout") : page.q.style === "classic" ? I18n.tr("Icon beside the text, slim sliders") : page.q.style === "cards" ? I18n.tr("Icon on top, tinted when on, big sliders (like the dashboard)") : I18n.tr("Pill tiles in two columns, half or full width, that you arrange yourself")
            icon: "view_module"
            target: page.q
            key: "style"
            segWidth: 120
            options: [{ value: "pills", label: I18n.tr("Pills"), icon: "view_agenda" }, { value: "grid", label: I18n.tr("Grid"), icon: "dashboard_customize" }, { value: "cards", label: I18n.tr("Cards"), icon: "grid_view" }, { value: "classic", label: I18n.tr("Classic"), icon: "view_list" }]
        }
        SettingRow {
            visible: (page.q.style || "grid") === "grid"
            title: I18n.tr("Arranging the grid")
            subtitle: I18n.tr("Press and hold any tile in quick settings: remove (−), make it half or full width, drag it, add widgets, then ✓. The tile choices below are for the Cards and Classic styles")
            icon: "touch_app"
            FButton {
                text: I18n.tr("Reset the grid")
                variant: "text"
                disabled: !(page.q.grid || []).length
                onClicked: page.q.grid = []
            }
        }
    }

    Group {
        title: I18n.tr("Panel position")
        DropdownRow {
            title: I18n.tr("Placement")
            icon: "align_horizontal_center"
            target: page.q
            key: "placement"
            options: [{ value: "bar", label: I18n.tr("By the bar button") }, { value: "center", label: I18n.tr("Screen center") }, { value: "top", label: I18n.tr("Top center") }, { value: "bottom", label: I18n.tr("Bottom center") }, { value: "top-left", label: I18n.tr("Top left") }, { value: "top-right", label: I18n.tr("Top right") }, { value: "bottom-left", label: I18n.tr("Bottom left") }, { value: "bottom-right", label: I18n.tr("Bottom right") }]
        }
        SliderRow { title: I18n.tr("Button spacing"); subtitle: I18n.tr("More space between controls and larger button targets"); icon: "space_bar"; target: page.q; key: "panelSpacing"; from: 1; to: 1.6; stepSize: 0.05; factor: 100; suffix: "%" }

    }

    Group {
        title: I18n.tr("Placement")
        ChoiceRow {
            title: I18n.tr("Bar alignment")
            subtitle: page.q.placement !== "bar" ? I18n.tr("Used when panel placement is By the bar") : page.q.align === "auto" ? I18n.tr("On the side of the bar where its button is") : ""
            icon: "align_horizontal_right"
            target: page.q
            key: "align"
            segWidth: 120
            options: [{ value: "auto", label: I18n.tr("By its button") }, { value: "left", label: I18n.tr("Left") }, { value: "center", label: I18n.tr("Center") }, { value: "right", label: I18n.tr("Right") }]
        }
        SliderRow { title: I18n.tr("Width"); icon: "width"; target: page.q; key: "width"; from: 340; to: 640; stepSize: 10; suffix: " px" }
        ChoiceRow {
            title: I18n.tr("Tile columns")
            icon: "grid_view"
            target: page.q
            key: "columns"
            options: [{ value: 1, label: "1" }, { value: 2, label: "2" }, { value: 3, label: "3" }]
        }
    }

    Group {
        title: I18n.tr("Sections")
        Repeater {
            model: [{ k: "header", label: I18n.tr("Your name, uptime, and settings / lock / power buttons"), icon: "account_circle" },
                { k: "sliders", label: I18n.tr("Volume, microphone and brightness sliders"), icon: "tune" },
                { k: "tiles", label: I18n.tr("Tiles"), icon: "grid_view" },
                { k: "media", label: I18n.tr("What's playing (while something is)"), icon: "music_note" }]
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
        title: I18n.tr("Tiles")
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
            title: I18n.tr("Back to the default tiles")
            icon: "restart_alt"
            FButton {
                text: I18n.tr("Reset")
                variant: "text"
                onClicked: page.q.tiles = []
            }
        }
    }
}
