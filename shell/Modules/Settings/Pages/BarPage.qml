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
        for (const k in page.b.customs || {})
            out[k] = (page.b.customs[k].name || "Custom") + " (custom)";
        for (const k in ThirdParty.barWidgets)
            out[k] = ThirdParty.barWidgets[k].label;
        return out;
    }
    readonly property var builtinWidgets: ({
            launcher: "Start button (launcher)", workspaces: "Workspaces", window: "Active window", taskbar: "Taskbar (running apps)", clock: "Clock", media: "Media",
            tray: "System tray", sysstats: "CPU / RAM", keyboard: "Keyboard layout", network: "Network", bluetooth: "Bluetooth",
            audio: "Volume", mic: "Microphone (while in use)", privacy: "Privacy (camera, screen sharing)", recording: "Screen recording (while recording)", updates: "Package updates (when there are some)", notepad: "Notepad", visualizer: "Audio visualizer (cava, while playing)", brightness: "Brightness", battery: "Battery", notifications: "Notifications", weather: "Weather", quicksettings: "Quick settings", assistant: "AI assistant", power: "Power", clipboard: "Clipboard history", separator: "Separator (a thin line)",
            lockkeys: "Caps Lock / Num Lock", netspeed: "Network speed", disk: "Disk usage", gpu: "Graphics card (usage, temperature)", vpn: "VPN",
            lyrics: "Lyrics (the line being sung)", spacer: "Spacer (room between widgets)", island: "Dynamic island"
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

    // ── placing one widget: which section it's in (left / center / right), or off ──
    function where(id) {
        for (const k of ["left", "center", "right"])
            if (list(k).includes(id))
                return k;
        return "off";
    }
    function place(id, to) {
        for (const k of ["left", "center", "right"]) {
            const l = list(k);
            if (l.includes(id))
                setList(k, l.filter(x => x !== id));
        }
        if (to === "off")
            return;
        const l = list(to);
        // where in the section reads naturally: the start button first on the left; the tray
        // and the window title lead the right side; the clock goes last (before power)
        let at = l.length;
        if (to === "left" && id === "launcher")
            at = 0;
        else if (to === "right" && (id === "tray" || id === "window"))
            at = 0;
        else if (to === "right" && id === "clock" && l.includes("power"))
            at = l.indexOf("power");
        l.splice(at, 0, id);
        setList(to, l);
    }
    // the edge (or freeroam), and in a corner of it
    readonly property string edge: b.position === "free" ? "free" : Theme.barPos
    function setEdge(v) {
        b.position = (v === "top" || v === "bottom") && Theme.barCorner ? v + "-" + Theme.barCorner : v;
    }
    readonly property bool vert: Theme.barVertical
    readonly property var places: [{ value: "left", label: "Left", icon: "align_horizontal_left" }, { value: "center", label: "Center", icon: "align_horizontal_center" }, { value: "right", label: "Right", icon: "align_horizontal_right" }, { value: "off", label: "Off", icon: "block" }]

    BarStyleSection {}

    property bool placeAll: false
    readonly property var mainPlaces: [
        { id: "tray", title: "App indicators (system tray)", icon: "apps" },
        { id: "launcher", title: "Start button", icon: "rocket_launch" },
        { id: "window", title: "Active window", icon: "select_window" },
        { id: "clock", title: "Clock", icon: "schedule" }
    ]
    Group {
        title: "Placement"
        Repeater {
            // the main ones, or every widget (the order inside a section is in the lists further down)
            model: page.placeAll ? page.mainPlaces.concat(Object.keys(page.builtinWidgets).filter(k => k !== "separator" && !page.mainPlaces.some(m => m.id === k))
                    .map(k => ({ id: k, title: page.builtinWidgets[k], icon: "widgets" }))) : page.mainPlaces
            SettingRow {
                id: prow
                required property var modelData
                readonly property string at: page.where(modelData.id)
                title: modelData.title
                subtitle: Theme.barVertical ? "Left, center and right are top, middle and bottom on a side bar" : ""
                icon: modelData.icon
                FSegmented {
                    implicitWidth: 340
                    options: page.places
                    current: prow.at
                    onSelected: v => page.place(prow.modelData.id, v)
                }
            }
        }
        SettingRow {
            title: page.placeAll ? "Fewer" : "Every widget"
            subtitle: page.placeAll ? "Back to the main four" : "Place any of the bar's widgets on the left, center or right, or leave it out"
            icon: page.placeAll ? "expand_less" : "expand_more"
            FButton {
                text: page.placeAll ? "Show fewer" : "Show all"
                variant: "tonal"
                onClicked: page.placeAll = !page.placeAll
            }
        }
    }

    Group {
        title: "Layout"
        SettingRow {
            title: "Position"
            subtitle: page.edge === "free" ? "Freeroam: a floating bar you move anywhere by dragging its grip (⋮⋮ at its left end). It doesn't keep space free, so windows can go under it" : "Left and right give a vertical bar; Freeroam floats wherever you drag it"
            icon: "screenshot_frame"
            FSegmented {
                implicitWidth: 5 * 84
                options: [{ value: "top", label: "Top", icon: "border_top" }, { value: "bottom", label: "Bottom", icon: "border_bottom" }, { value: "left", label: "Left", icon: "border_left" }, { value: "right", label: "Right", icon: "border_right" }, { value: "free", label: "Freeroam", icon: "open_with" }]
                current: page.edge
                onSelected: v => page.setEdge(v)
            }
        }
        SettingRow {
            visible: page.edge === "top" || page.edge === "bottom"
            title: "Corner"
            subtitle: Theme.barCorner ? "Just around its widgets, in the " + page.edge + "-" + Theme.barCorner + " corner. Windows still keep clear of the edge" : "Along the whole edge, or tucked into one of its corners"
            icon: "picture_in_picture"
            FSegmented {
                implicitWidth: 3 * 110
                options: [{ value: "", label: "Whole edge" }, { value: "left", label: "Left corner" }, { value: "right", label: "Right corner" }]
                current: Theme.barCorner
                onSelected: v => page.b.position = v ? page.edge + "-" + v : page.edge
            }
        }
        ChoiceRow {
            visible: !Theme.barCorner && page.edge !== "free" && page.b.style !== "capsule"
            title: "Length"
            subtitle: (page.b.length || "full") === "fit" ? "Just as long as its widgets" : "Edge to edge"
            icon: page.vert ? "height" : "width"
            target: page.b
            key: "length"
            segWidth: 120
            options: [{ value: "full", label: "Full" }, { value: "fit", label: "Fit widgets" }]
        }
        ChoiceRow {
            visible: Theme.barFit && !Theme.barCorner && page.edge !== "free"
            title: "Where on the edge"
            icon: page.vert ? "vertical_align_center" : "align_horizontal_center"
            target: page.b
            key: "align"
            segWidth: 96
            options: [{ value: "start", label: page.vert ? "Top" : "Left" }, { value: "center", label: page.vert ? "Middle" : "Center" }, { value: "end", label: page.vert ? "Bottom" : "Right" }]
        }
        ChoiceRow {
            visible: !Theme.barFit
            title: "Widgets"
            subtitle: (page.b.arrange || "spread") === "spread" ? "Each section at its own spot: " + (page.vert ? "top, middle and bottom" : "left, center and right")
                : "All sections side by side, " + ({ start: page.vert ? "at the top" : "on the left", center: "in the middle", end: page.vert ? "at the bottom" : "on the right" })[page.b.arrange]
            icon: "view_column"
            target: page.b
            key: "arrange"
            segWidth: 86
            options: [{ value: "spread", label: "Spread" }, { value: "start", label: page.vert ? "Top" : "Left" }, { value: "center", label: page.vert ? "Middle" : "Center" }, { value: "end", label: page.vert ? "Bottom" : "Right" }]
        }
        SliderRow { title: "Icon size"; subtitle: "The bar's icons (they never outgrow its thickness)"; icon: "format_size"; target: page.b; key: "iconScale"; from: 0.8; to: 1.4; stepSize: 0.05; factor: 100; suffix: "%" }
        ChoiceRow { title: "Workspace indicator"; subtitle: page.b.workspaceStyle === "apps" ? "Each workspace shows its apps' icons; the active one is filled" : ""; icon: "view_week"; target: page.b; key: "workspaceStyle"; options: [{ value: "pills", label: "Pills" }, { value: "numbers", label: "Numbers" }, { value: "dots", label: "Dots" }, { value: "apps", label: "App icons" }] }
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
        title: "Hide"
        ChoiceRow {
            title: "Hide the bar"
            subtitle: page.b.hide === "auto" ? "Out of the way until you move the pointer to the screen's edge"
                : page.b.hide === "windows" ? "Hidden while windows are open on the workspace; shown on an empty one, or at the edge"
                : "Always shown. A shortcut can still hide it (Show / hide the bar, in Keyboard → Flamenco functions)"
            icon: "visibility_off"
            target: page.b
            key: "hide"
            segWidth: 120
            options: [{ value: "never", label: "Never" }, { value: "auto", label: "Auto-hide" }, { value: "windows", label: "With windows" }]
        }
        SliderRow { visible: page.b.hide !== "never"; title: "Hide after"; subtitle: "Once the pointer leaves the bar"; icon: "timer"; target: page.b; key: "hideDelay"; from: 0; to: 3000; stepSize: 100; suffix: " ms" }
        SliderRow { visible: page.b.hide !== "never"; title: "Edge to reveal it"; subtitle: "How close to the edge the pointer has to be"; icon: "border_outer"; target: page.b; key: "revealSize"; from: 1; to: 12; stepSize: 1; suffix: " px" }
        SwitchRow { title: "Hide during the overview"; subtitle: "Out of the way while niri's overview is open"; icon: "overview_key"; target: page.b; key: "hideOnOverview" }
        SwitchRow { visible: page.b.hide !== "never"; title: "Show when switching workspaces"; subtitle: "For a moment, so you see where you are"; icon: "view_carousel"; target: page.b; key: "showOnSwitch" }
        SwitchRow { visible: page.b.hide !== "never"; title: "Keep its space"; subtitle: "Windows stay clear of the bar's spot while it's hidden, so it never covers them"; icon: "space_bar"; target: page.b; key: "hideKeepSpace" }
        SettingRow {
            title: Panels.barHidden ? "Hidden by hand" : "Hide it now"
            subtitle: Panels.barHidden ? "Until you show it again or the shell restarts. Also: flamenco bar toggle" : "Until you show it again (the pointer at the edge still brings it out). Also: flamenco bar toggle"
            icon: "toggle_on"
            FButton {
                text: Panels.barHidden ? "Show the bar" : "Hide the bar"
                variant: "tonal"
                onClicked: Panels.barHidden = !Panels.barHidden
            }
        }
    }

    Group {
        title: "Clicks on the empty bar"
        ChoiceRow {
            title: "Scrolling"
            icon: "swap_vert"
            target: page.b
            key: "wheelAction"
            segWidth: 104
            options: [{ value: "none", label: "Nothing" }, { value: "workspaces", label: "Workspaces" }, { value: "volume", label: "Volume" }, { value: "brightness", label: "Brightness" }]
        }
        Repeater {
            model: [{ k: "middle", t: "Middle-click", i: "mouse" }, { k: "right", t: "Right-click", i: "ads_click" }]
            ColumnLayout {
                id: crow
                required property var modelData
                Layout.fillWidth: true
                spacing: 0
                DropdownRow {
                    title: crow.modelData.t
                    icon: crow.modelData.i
                    target: page.b
                    key: crow.modelData.k + "Action"
                    options: [{ value: "none", label: "Nothing" }, { value: "overview", label: "Overview" }, { value: "launcher", label: "Launcher" },
                        { value: "control", label: "Quick settings" }, { value: "settings", label: "Bar settings" }, { value: "command", label: "A command" }]
                }
                TextRow {
                    visible: page.b[crow.modelData.k + "Action"] === "command"
                    title: "Command"
                    icon: "terminal"
                    target: page.b
                    key: crow.modelData.k + "Command"
                    placeholder: "e.g. kitty"
                }
            }
        }
    }

    Group {
        title: "Widget options"
        SwitchRow { title: "Caps Lock / Num Lock always shown"; subtitle: "Off: only while one is on"; icon: "keyboard_capslock"; target: page.b; key: "lockKeysAlways" }
        TextRow { title: "Disk"; subtitle: "Where the disk widget's disk is mounted"; icon: "hard_drive"; target: page.b; key: "diskMount"; placeholder: "/" }
        SliderRow { title: "Lyrics width"; subtitle: "The widest the lyric line gets"; icon: "lyrics"; target: page.b; key: "lyricsWidth"; from: 160; to: 600; stepSize: 20; suffix: " px" }
    }

    CustomWidgetsSection {}

    BatterySection {}

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
            subtitle: Audio.micInUse ? "In use now by " + Audio.micUsers : "Nothing is recording right now" + (Audio.micMuted ? " (the mic is muted)" : "")
            icon: "mic"
            target: page.b
            key: "micIndicator"
            segWidth: 130
            options: [{ value: "inuse", label: "While in use" }, { value: "inuse-muted", label: "In use or muted" }, { value: "always", label: "Always" }]
        }
        ChoiceRow {
            title: "Look"
            subtitle: ({ icon: "The mic, highlighted while recording", dot: "A small dot: amber while recording, a red ring while muted", pill: "The mic and the app listening", ring: "The mic with a ring that breathes while recording", text: "MIC or MUTED" })[page.b.micStyle || "icon"]
            icon: "interests"
            target: page.b
            key: "micStyle"
            segWidth: 72
            options: [{ value: "icon", label: "Icon" }, { value: "dot", label: "Dot" }, { value: "pill", label: "Pill" }, { value: "ring", label: "Ring" }, { value: "text", label: "Text" }]
        }
    }

    Group {
        title: "Package updates"
        SwitchRow { title: "Check for updates"; subtitle: "Looks for system, AUR and Flatpak updates now and then. Off: no checks at all"; icon: "system_update"; target: Settings.data.updates; key: "enabled" }
        SwitchRow { visible: Settings.data.updates.enabled; title: "Show in the bar"; subtitle: "An icon with the count, only while there are updates"; icon: "toolbar"; target: Settings.data.updates; key: "showInBar" }
        SliderRow { visible: Settings.data.updates.enabled; title: "Check every"; icon: "schedule"; target: Settings.data.updates; key: "interval"; from: 15; to: 720; stepSize: 15; suffix: " min" }
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
                    title: page.allWidgets[modelData] ?? (modelData.startsWith("separator") ? page.allWidgets.separator : modelData.startsWith("spacer") ? page.allWidgets.spacer : modelData)
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
                    model: Object.keys(page.allWidgets).filter(k => k === "separator" || k === "spacer" || !page.used.includes(k))
                    FButton {
                        required property string modelData
                        text: page.allWidgets[modelData]
                        icon: "add"
                        variant: "tonal"
                        implicitHeight: 30
                        onClicked: {
                            let id = modelData;
                            let n = 1;
                            while ((modelData === "separator" || modelData === "spacer") && page.used.includes(id))
                                id = modelData + ":" + (++n);
                            page.setList(grp.modelData.key, page.list(grp.modelData.key).concat([id]));
                        }
                    }
                }
            }
        }
    }
}
