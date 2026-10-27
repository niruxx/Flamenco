import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: I18n.tr("Windows & Layout")
    subtitle: I18n.tr("Gaps, borders, corners and how windows open and take focus. Saved into the compositor config, so it applies right away.")
    readonly property var w: Settings.data.windows

    Component.onCompleted: Compositor.load()

    Group {
        title: I18n.tr("Window mode")
        SettingRow {
            title: I18n.tr("How windows open")
            subtitle: page.w.floating ? I18n.tr("Floating: windows open on top of each other where you like, like a classic desktop. Super+V tiles one")
                : "Tiling: windows open side by side and never overlap. Super+V floats one"
            icon: page.w.floating ? "stack" : "view_column"
            FSegmented {
                implicitWidth: 260
                options: [{ value: false, label: I18n.tr("Tiling"), icon: "view_column" }, { value: true, label: I18n.tr("Floating"), icon: "stack" }]
                current: page.w.floating
                onSelected: v => Compositor.setFloating(v)
            }
        }
        SettingRow {
            title: I18n.tr("Windows already open")
            subtitle: I18n.tr("Switching moves them too. A shortcut switches back and forth: Switch tiling / floating windows (Keyboard → Flamenco functions)")
            icon: "info"
        }
    }

    Group {
        title: I18n.tr("Layout")
        SliderRow { title: I18n.tr("Gaps"); subtitle: I18n.tr("Space around and between windows"); icon: "padding"; target: page.w; key: "gaps"; from: 0; to: 48; stepSize: 1; suffix: " px"; onEdited: Compositor.queue() }
        SliderRow { title: I18n.tr("Screen edge margin"); subtitle: I18n.tr("Extra space kept free along the left and right edges"); icon: "border_outer"; visible: !Niri.hyprland; target: page.w; key: "struts"; from: 0; to: 120; stepSize: 1; suffix: " px"; onEdited: Compositor.queue() }
        SliderRow { title: I18n.tr("New window width"); subtitle: I18n.tr("Share of the screen a new column takes"); icon: "width"; visible: !Niri.hyprland; target: page.w; key: "defaultWidth"; from: 0.25; to: 1; stepSize: 0.05; factor: 100; suffix: "%"; onEdited: Compositor.queue() }
        ChoiceRow {
            title: I18n.tr("Center the focused column")
            icon: "format_align_center"
            visible: !Niri.hyprland
            target: page.w
            key: "centerColumn"
            segWidth: 110
            options: [{ value: "never", label: I18n.tr("Never") }, { value: "on-overflow", label: I18n.tr("If it overflows") }, { value: "always", label: I18n.tr("Always") }]
            onEdited: Compositor.queue()
        }
        SwitchRow { title: I18n.tr("Ask apps to skip their own title bars"); subtitle: page.w.floating && (page.w.floatingFrames ?? true) ? I18n.tr("In tiling mode. While windows float, apps keep their frames (below)") : I18n.tr("Most GTK and Qt apps then draw a plain window instead"); icon: "web_asset_off"; target: page.w; key: "preferNoCsd"; onEdited: Compositor.queue() }
        SwitchRow {
            title: I18n.tr("Window frames when floating")
            subtitle: I18n.tr("Apps draw their own frames while windows float, so you can resize them by their edges, with the resize cursor. Takes effect for apps opened afterwards")
            icon: "open_in_full"
            target: page.w
            key: "floatingFrames"
            onEdited: Compositor.queue()
        }
        SettingRow {
            title: I18n.tr("Resizing and moving")
            subtitle: I18n.tr("Super + right-drag resizes any window, Super + left-drag moves it. Without the edges (or on a touchpad): Resize… in a window's menu (right-click its title in the bar, or its dock icon), or give \"Resize the window\" a shortcut in Keyboard → Flamenco functions")
            icon: "drag_pan"
        }
    }

    WindowRulesSection {}

    Group {
        title: I18n.tr("Look")
        SliderRow { title: I18n.tr("Corner radius"); subtitle: I18n.tr("Rounds every window's corners"); icon: "rounded_corner"; target: page.w; key: "cornerRadius"; from: 0; to: 24; stepSize: 1; suffix: " px"; onEdited: Compositor.queue() }
        SwitchRow { title: I18n.tr("Focus ring"); subtitle: I18n.tr("An outline around the focused window"); icon: "center_focus_strong"; target: page.w; key: "focusRing"; onEdited: Compositor.queue() }
        SliderRow { title: I18n.tr("Focus ring width"); icon: "line_weight"; visible: page.w.focusRing; target: page.w; key: "focusRingWidth"; from: 1; to: 8; stepSize: 1; suffix: " px"; onEdited: Compositor.queue() }
        SwitchRow { title: I18n.tr("Border"); subtitle: I18n.tr("A border on every window, brighter on the focused one"); icon: "border_style"; target: page.w; key: "border"; onEdited: Compositor.queue() }
        SliderRow { title: I18n.tr("Border width"); icon: "line_weight"; visible: page.w.border; target: page.w; key: "borderWidth"; from: 1; to: 8; stepSize: 1; suffix: " px"; onEdited: Compositor.queue() }
        SwitchRow { title: I18n.tr("Colors follow the theme"); subtitle: I18n.tr("Accent for the focused window, the border color for the rest"); icon: "format_color_fill"; target: page.w; key: "syncColors"; onEdited: Compositor.queue() }
        ColorRow { title: I18n.tr("Focused color"); icon: "colorize"; visible: !page.w.syncColors; target: page.w; key: "activeColor" }
        ColorRow { title: I18n.tr("Unfocused color"); icon: "colorize"; visible: !page.w.syncColors; target: page.w; key: "inactiveColor" }
        SettingRow {
            visible: page.w.border
            title: I18n.tr("Border colors of its own")
            subtitle: page.w.borderActiveColor ? I18n.tr("Different from the focus ring") : I18n.tr("Off: the border uses the focus ring's colors")
            icon: "border_color"
            FSwitch {
                checked: page.w.borderActiveColor !== ""
                onToggled: c => {
                    page.w.borderActiveColor = c ? (page.w.syncColors ? Compositor.hex(Theme.palette.accent2) : page.w.activeColor) : "";
                    page.w.borderInactiveColor = c ? (page.w.syncColors ? Compositor.hex(Theme.palette.border) : page.w.inactiveColor) : "";
                    Compositor.queue();
                }
            }
        }
        ColorRow { title: I18n.tr("Border, focused"); icon: "colorize"; visible: page.w.border && page.w.borderActiveColor !== ""; target: page.w; key: "borderActiveColor" }
        ColorRow { title: I18n.tr("Border, unfocused"); icon: "colorize"; visible: page.w.border && page.w.borderActiveColor !== ""; target: page.w; key: "borderInactiveColor" }
        SwitchRow { title: I18n.tr("Gradient on the focused window"); subtitle: I18n.tr("Blends the focused color into a second one"); icon: "gradient"; visible: page.w.focusRing || page.w.border; target: page.w; key: "gradient"; onEdited: Compositor.queue() }
        ColorRow { title: I18n.tr("Gradient to"); subtitle: page.w.gradientTo ? "" : I18n.tr("Following the palette's second accent"); icon: "colorize"; visible: page.w.gradient && (page.w.focusRing || page.w.border); target: page.w; key: "gradientTo" }
        SliderRow { title: I18n.tr("Gradient angle"); icon: "rotate_right"; visible: page.w.gradient && (page.w.focusRing || page.w.border); target: page.w; key: "gradientAngle"; from: 0; to: 360; stepSize: 15; suffix: "°"; onEdited: Compositor.queue() }
        SwitchRow { title: I18n.tr("Shadows"); icon: "shadow"; target: page.w; key: "shadows"; onEdited: Compositor.queue() }
    }

    Group {
        title: I18n.tr("Focus & pointer")
        SwitchRow { title: I18n.tr("Focus follows the mouse"); subtitle: I18n.tr("Hovering a window focuses it"); icon: "ads_click"; target: page.w; key: "focusFollowsMouse"; onEdited: Compositor.queue() }
        SwitchRow { title: I18n.tr("Move the pointer with focus"); subtitle: I18n.tr("The pointer jumps to a window focused from the keyboard"); icon: "jump_to_element"; target: page.w; key: "warpMouse"; onEdited: Compositor.queue() }
        SwitchRow { title: I18n.tr("Hide the pointer while typing"); icon: "keyboard"; target: page.w; key: "hideCursorTyping"; onEdited: Compositor.queue() }
        SliderRow { title: I18n.tr("Hide the pointer when idle"); subtitle: I18n.tr("Off at 0"); icon: "timer"; target: page.w; key: "hideCursorAfter"; from: 0; to: 30; stepSize: 1; suffix: " s"; onEdited: Compositor.queue() }
        SettingRow { title: I18n.tr("Hot corners"); subtitle: I18n.tr("Set in Screen edges, including the corners that open niri's overview"); icon: "north_west"; visible: !Niri.hyprland }
        SwitchRow { title: I18n.tr("Skip the shortcut help at login"); subtitle: I18n.tr("niri shows its key cheat sheet when it starts"); icon: "help"; visible: !Niri.hyprland; target: page.w; key: "skipHotkeyOverlay"; onEdited: Compositor.queue() }
    }

    FText {
        Layout.fillWidth: true
        visible: Compositor.status !== ""
        text: Compositor.status
        dim: !Compositor.failed
        color: Compositor.failed ? Theme.error : Theme.textDim
        wrapMode: Text.Wrap
    }

    component ColorRow: SettingRow {
        id: cr
        property var target
        property string key
        RowLayout {
            spacing: 10
            // one click on a palette color
            Row {
                spacing: 4
                Repeater {
                    model: ["accent", "accent2", "accent3", "success", "warning", "error", "text", "border"]
                    Rectangle {
                        required property string modelData
                        width: 18; height: 18; radius: 9
                        color: Theme.palette[modelData]
                        border.width: Compositor.hex(Theme.palette[modelData]) === cr.target[cr.key] ? 2 : 1
                        border.color: Compositor.hex(Theme.palette[modelData]) === cr.target[cr.key] ? Theme.text : Theme.border
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: cr.commit(Compositor.hex(Theme.palette[parent.modelData]))
                        }
                    }
                }
            }
            Rectangle {
                width: 28; height: 28; radius: 14
                color: /^#[0-9a-fA-F]{6}$/.test(cr.target[cr.key]) ? cr.target[cr.key] : "transparent"
                border.width: 1
                border.color: Theme.border
            }
            FTextField {
                implicitWidth: 140
                text: cr.target[cr.key]
                placeholder: "#rrggbb"
                onEditingFinished: cr.commit(text)
                onAccepted: cr.commit(text)
            }
        }
        function commit(v) {
            v = v.trim();
            if (!/^#?[0-9a-fA-F]{6}$/.test(v))
                return;
            v = v.startsWith("#") ? v : "#" + v;
            if (cr.target[cr.key] === v)
                return;
            cr.target[cr.key] = v;
            Compositor.queue();
        }
    }
}
