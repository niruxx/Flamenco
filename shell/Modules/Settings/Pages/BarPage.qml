import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: "Bar"
    readonly property var b: Settings.data.bar
    // built-in widgets, plus the bar widgets of plugins that are turned on
    // (no Object.fromEntries: Quickshell's JavaScript doesn't have it)
    readonly property var allWidgets: {
        const out = Object.assign({}, builtinWidgets);
        for (const k in Plugins.barWidgets)
            out[k] = Plugins.barWidgets[k].label + " (plugin)";
        for (const k in ThirdParty.barWidgets)
            out[k] = ThirdParty.barWidgets[k].label;
        return out;
    }
    readonly property var builtinWidgets: ({
            launcher: "Start button (launcher)", workspaces: "Workspaces", window: "Active window", taskbar: "Taskbar (running apps)", clock: "Clock", media: "Media",
            tray: "System tray", sysstats: "CPU / RAM", keyboard: "Keyboard layout", network: "Network", bluetooth: "Bluetooth",
            audio: "Volume", mic: "Microphone (while in use)", privacy: "Privacy (camera, screen sharing)", recording: "Screen recording (while recording)", updates: "Package updates (when there are some)", notepad: "Notepad", visualizer: "Audio visualizer (cava, while playing)", brightness: "Brightness", battery: "Battery", notifications: "Notifications", weather: "Weather", quicksettings: "Quick settings", assistant: "AI assistant", power: "Power", separator: "Separator (a thin line)"
        })
    // which layout is being edited: "" = the shared one, else a screen with its own
    property string screenSel: ""
    readonly property var own: (b.perScreen || {})[screenSel] ?? null
    readonly property var lay: own ?? b
    function list(key) {
        return (lay[key] ?? b[key] ?? []).slice();
    }
    function setList(key, l) {
        if (!own) {
            b[key] = l;
            return;
        }
        const all = Object.assign({}, b.perScreen || {});
        all[screenSel] = Object.assign({}, all[screenSel]);
        all[screenSel][key] = l;
        b.perScreen = all;
    }
    function move(key, from, to) {
        const l = list(key);
        l.splice(to, 0, l.splice(from, 1)[0]);
        setList(key, l);
    }
    readonly property var used: list("left").concat(list("center"), list("right"))

    Group {
        title: "Layout"
        ChoiceRow {
            title: "Position"
            subtitle: "Left and right give a vertical bar"
            icon: "screenshot_frame"
            target: page.b
            key: "position"
            segWidth: 84
            options: [{ value: "top", label: "Top", icon: "border_top" }, { value: "bottom", label: "Bottom", icon: "border_bottom" }, { value: "left", label: "Left", icon: "border_left" }, { value: "right", label: "Right", icon: "border_right" }]
        }
        ChoiceRow { title: "Style"; icon: "style"; target: page.b; key: "style"; options: [{ value: "floating", label: "Floating" }, { value: "attached", label: "Attached" }, { value: "islands", label: "Islands" }] }
        SliderRow { title: "Thickness"; icon: "height"; target: page.b; key: "height"; from: 30; to: 56; stepSize: 1; suffix: "px" }
        ChoiceRow { title: "Workspace indicator"; subtitle: page.b.workspaceStyle === "apps" ? "Each workspace shows its apps' icons; the active one is filled" : ""; icon: "view_week"; target: page.b; key: "workspaceStyle"; options: [{ value: "pills", label: "Pills" }, { value: "numbers", label: "Numbers" }, { value: "dots", label: "Dots" }, { value: "apps", label: "App icons" }] }
        ChoiceRow { title: "Battery"; icon: "battery_full"; target: page.b; key: "batteryStyle"; segWidth: 150; options: [{ value: "icon", label: "Icon and percent" }, { value: "battery", label: "Battery shape" }] }
        ChoiceRow { title: "CPU / RAM"; icon: "memory"; target: page.b; key: "statsStyle"; segWidth: 120; options: [{ value: "text", label: "Icons" }, { value: "rings", label: "Ring gauges" }] }
        SwitchRow { title: "Temperature with CPU / RAM"; icon: "thermostat"; target: page.b; key: "statsTemp" }
        SettingRow {
            title: "Clock"
            subtitle: "Its layout, alignment and position are in Clock & Weather"
            icon: "schedule"
            FButton {
                text: "Clock settings"
                variant: "text"
                onClicked: Panels.findSetting("clock", "Bar clock")
            }
        }
    }

    Group {
        title: "Start button"
        SettingRow {
            visible: !page.used.includes("launcher")
            title: "Not in the bar yet"
            subtitle: "Add \"Start button (launcher)\" to a section below"
            icon: "info"
        }
        ChoiceRow {
            title: "Icon"
            icon: "apps"
            target: page.b
            key: "startIcon"
            segWidth: 100
            options: [{ value: "apps", label: "Apps", icon: "apps" }, { value: "distro", label: "Distro", icon: "deployed_code" }, { value: "flamenco", label: "Flamenco", icon: "local_fire_department" }, { value: "custom", label: "Custom", icon: "edit" }]
        }
        TextRow {
            visible: page.b.startIcon === "custom"
            title: "Custom icon"
            subtitle: "A Material Symbols name (e.g. rocket_launch), or the path of a picture"
            icon: "image"
            target: page.b
            key: "startCustom"
            placeholder: "rocket_launch"
        }
        TextRow { title: "Label"; subtitle: "Text beside the icon, e.g. Start. Empty for just the icon."; icon: "label"; target: page.b; key: "startLabel"; placeholder: "Start" }
        ChoiceRow {
            title: "Opens"
            subtitle: Settings.data.overview.enabled ? "Right-click it for the other one" : "The overview is off (Settings → Overview)"
            icon: "ads_click"
            target: page.b
            key: "startAction"
            segWidth: 120
            options: [{ value: "auto", label: "Automatic" }, { value: "overview", label: "Overview" }, { value: "launcher", label: "Launcher" }]
        }
    }

    Group {
        title: "System tray (app indicators)"
        SwitchRow { title: "Hide passive icons"; subtitle: "Apps that mark themselves idle stay out of the bar"; icon: "visibility_off"; target: page.b; key: "trayHidePassive" }
        SliderRow { title: "Icons before overflow"; icon: "more_horiz"; target: page.b; key: "trayMaxVisible"; from: 2; to: 16; stepSize: 1 }
        SwitchRow { title: "Native Qt menus"; subtitle: "Use the app's own Qt menu instead of the themed one"; icon: "menu"; target: page.b; key: "trayNativeMenus" }
    }

    Group {
        title: "Microphone"
        SettingRow {
            visible: !page.used.includes("mic")
            title: "Not in the bar yet"
            subtitle: "Add \"Microphone (while in use)\" to a section below. Click it to mute or unmute."
            icon: "info"
        }
        ChoiceRow {
            title: "Show it"
            subtitle: Audio.micInUse ? "In use now by " + Audio.micUsers : "Nothing is recording right now"
            icon: "mic"
            target: page.b
            key: "micIndicator"
            segWidth: 150
            options: [{ value: "inuse", label: "While in use or muted" }, { value: "always", label: "Always" }]
        }
    }

    Group {
        title: "Taskbar"
        SettingRow {
            visible: !page.used.includes("taskbar")
            title: "Not in the bar yet"
            subtitle: "Add \"Taskbar (running apps)\" to a section below. Right-click an app there for its window menu."
            icon: "info"
        }
        ChoiceRow {
            title: "Show apps from"
            icon: "select_window"
            target: page.b
            key: "taskbarScope"
            segWidth: 112
            options: [{ value: "all", label: "Every screen" }, { value: "screen", label: "This screen" }, { value: "workspace", label: "Workspace" }]
        }
        SwitchRow { title: "Window titles"; subtitle: "Next to the icons, when there's room"; icon: "title"; target: page.b; key: "taskbarTitles" }
    }

    Group {
        visible: Quickshell.screens.length > 1
        title: "Layout for"
        SettingRow {
            title: page.screenSel === "" ? "Every screen" : page.screenSel
            subtitle: page.screenSel === "" ? "The shared layout, on every screen without its own" + (Object.keys(page.b.perScreen || {}).length ? " (" + Object.keys(page.b.perScreen).join(", ") + " have their own)" : "")
                : page.own ? "This screen has its own widgets" : "This screen uses the shared layout"
            icon: "monitor"
            Row {
                spacing: 8
                FDropdown {
                    implicitWidth: 200
                    options: [{ value: "", label: "Every screen" }].concat(Quickshell.screens.map(x => ({ value: x.name, label: x.name + ((page.b.perScreen || {})[x.name] ? " (own)" : "") })))
                    current: page.screenSel
                    onSelected: v => page.screenSel = v
                }
                FButton {
                    visible: page.screenSel !== "" && !page.own
                    text: "Give it its own"
                    variant: "tonal"
                    onClicked: {
                        const all = Object.assign({}, page.b.perScreen || {});
                        all[page.screenSel] = { left: page.b.left.slice(), center: page.b.center.slice(), right: page.b.right.slice() };
                        page.b.perScreen = all;
                    }
                }
                FButton {
                    visible: !!page.own
                    text: "Use the shared one"
                    variant: "text"
                    onClicked: {
                        const all = Object.assign({}, page.b.perScreen || {});
                        delete all[page.screenSel];
                        page.b.perScreen = all;
                    }
                }
            }
        }
    }

    Repeater {
        model: [{ key: "left", label: Theme.barVertical ? "Top" : "Left" }, { key: "center", label: "Center" }, { key: "right", label: Theme.barVertical ? "Bottom" : "Right" }]

        Group {
            id: grp
            required property var modelData
            title: modelData.label + " section" + (page.own ? " · " + page.screenSel : "")
            // a screen using the shared layout isn't edited here: pick "Every screen", or give it its own
            visible: page.screenSel === "" || !!page.own

            Repeater {
                model: page.list(grp.modelData.key)

                SettingRow {
                    required property string modelData
                    required property int index
                    title: page.allWidgets[modelData] ?? (modelData.startsWith("separator") ? page.allWidgets.separator : modelData)
                    icon: "drag_indicator"

                    Row {
                        spacing: 2
                        FIconButton { icon: "arrow_upward"; size: 30; disabled: index === 0; onClicked: page.move(grp.modelData.key, index, index - 1) }
                        FIconButton { icon: "arrow_downward"; size: 30; disabled: index === page.list(grp.modelData.key).length - 1; onClicked: page.move(grp.modelData.key, index, index + 1) }
                        FIconButton { icon: "close"; size: 30; iconColor: Theme.error; onClicked: page.setList(grp.modelData.key, page.list(grp.modelData.key).filter((x, i) => i !== index)) }
                    }
                }
            }

            Flow {
                Layout.fillWidth: true
                Layout.margins: 12
                spacing: 6
                Repeater {
                    // separators can go in as often as you like
                    model: Object.keys(page.allWidgets).filter(k => k === "separator" || !page.used.includes(k))
                    FButton {
                        required property string modelData
                        text: page.allWidgets[modelData]
                        icon: "add"
                        variant: "tonal"
                        implicitHeight: 30
                        onClicked: {
                            let id = modelData;
                            let n = 1;
                            while (modelData === "separator" && page.used.includes(id))
                                id = "separator:" + (++n);
                            page.setList(grp.modelData.key, page.list(grp.modelData.key).concat([id]));
                        }
                    }
                }
            }
        }
    }
}
