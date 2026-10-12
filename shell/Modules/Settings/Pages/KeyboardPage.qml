import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: "Keyboard"
    subtitle: "Layouts and shortcuts. Everything here is written to your niri config (~/.config/niri/config.kdl) and applies immediately."

    readonly property var k: Settings.data.keyboard
    property int editing: -2          // -2: none · -1: new shortcut · n: editing shortcut n
    property bool confirmReset: false

    Component.onCompleted: Keyboard.load()

    // ── layout helpers ──
    readonly property var layouts: k.layout ? k.layout.split(",") : []
    readonly property var variants: {
        const v = k.variant ? k.variant.split(",") : [];
        return layouts.map((_, i) => v[i] ?? "");
    }
    function setLayouts(ls, vs) {
        Keyboard.setInput({ layout: ls.join(","), variant: vs.some(v => v) ? vs.join(",") : "" });
    }
    function layoutLabel(code) {
        return Keyboard.catalog.layouts.find(l => l.value === code)?.label ?? code;
    }

    // options split into the groups the UI edits, plus anything else
    readonly property var opts: k.options ? k.options.split(",").filter(o => o) : []
    readonly property string optSwitch: opts.find(o => o.startsWith("grp:")) ?? ""
    readonly property string optCaps: opts.find(o => o.startsWith("caps:") || o === "ctrl:nocaps" || o === "ctrl:swapcaps") ?? ""
    readonly property string optCompose: opts.find(o => o.startsWith("compose:")) ?? ""
    readonly property var optOther: opts.filter(o => o !== optSwitch && o !== optCaps && o !== optCompose)
    // the first launcher shortcut's key, for the quick picker
    readonly property string launcherKey: k.shortcuts.find(sc => sc.type === "flamenco" && sc.value === "launcher")?.key ?? ""
    function setLauncherKey(key) {
        const i = k.shortcuts.findIndex(sc => sc.type === "flamenco" && sc.value === "launcher");
        // whatever else used this key is replaced by the launcher
        let list = k.shortcuts.filter((sc, j) => j === i || Keyboard.norm(sc.key) !== Keyboard.norm(key));
        const at = list.findIndex(sc => sc.type === "flamenco" && sc.value === "launcher");
        if (at >= 0)
            list[at] = Object.assign({}, list[at], { key: key });
        else
            list.unshift({ key: key, type: "flamenco", value: "launcher", title: "Launcher" });
        Keyboard.setShortcuts(list);
    }

    // close-window key: a managed niri shortcut; any key other than Super+Q also
    // disables Super+Q (niri's default) so it's a true replacement
    readonly property string closeKey: k.shortcuts.find(sc => sc.type === "niri" && sc.value === "close-window")?.key ?? "Mod+Q"
    function setCloseKey(key) {
        let list = k.shortcuts.filter(sc => !(sc.type === "niri" && sc.value === "close-window")
                                           && !(sc.type === "none" && Keyboard.norm(sc.key) === Keyboard.norm("Mod+Q"))
                                           && Keyboard.norm(sc.key) !== Keyboard.norm(key));
        if (Keyboard.norm(key) !== Keyboard.norm("Mod+Q"))
            list = list.concat([{ key: key, type: "niri", value: "close-window", title: "Close window" }, { key: "Mod+Q", type: "none", value: "" }]);
        Keyboard.setShortcuts(list);
    }

    function setOptions(sw, caps, compose, other) {
        Keyboard.setInput({ options: [sw, caps, compose].concat(other).filter(o => o).join(",") });
    }

    // ── layout ──
    Group {
        title: "Layout"

        Repeater {
            model: page.layouts
            SettingRow {
                id: lrow
                required property string modelData
                required property int index
                title: page.layoutLabel(modelData)
                subtitle: index === 0 ? "Default layout" : ""
                icon: "language"
                Row {
                    spacing: 4
                    FDropdown {
                        implicitWidth: 220
                        placeholder: "Variant"
                        options: [{ value: "", label: "Default variant" }].concat(Keyboard.catalog.variants[lrow.modelData] ?? [])
                        current: page.variants[lrow.index]
                        onSelected: v => {
                            const vs = page.variants.slice();
                            vs[lrow.index] = v;
                            page.setLayouts(page.layouts, vs);
                        }
                    }
                    FIconButton {
                        icon: "arrow_upward"
                        size: 32
                        disabled: lrow.index === 0
                        onClicked: {
                            const ls = page.layouts.slice(), vs = page.variants.slice();
                            [ls[lrow.index - 1], ls[lrow.index]] = [ls[lrow.index], ls[lrow.index - 1]];
                            [vs[lrow.index - 1], vs[lrow.index]] = [vs[lrow.index], vs[lrow.index - 1]];
                            page.setLayouts(ls, vs);
                        }
                    }
                    FIconButton {
                        icon: "close"
                        size: 32
                        iconColor: Theme.error
                        onClicked: page.setLayouts(page.layouts.filter((_, i) => i !== lrow.index), page.variants.filter((_, i) => i !== lrow.index))
                    }
                }
            }
        }

        SettingRow {
            title: page.layouts.length ? "Add a layout" : "Layouts"
            subtitle: page.layouts.length ? "" : "None set: niri uses the system keymap (localectl)"
            icon: "add"
            FDropdown {
                implicitWidth: 300
                placeholder: "Choose a layout…"
                options: Keyboard.catalog.layouts.filter(l => !page.layouts.includes(l.value))
                current: ""
                onSelected: v => page.setLayouts(page.layouts.concat([v]), page.variants.concat([""]))
            }
        }

        SettingRow {
            visible: page.layouts.length > 1
            title: "Switch layouts with"
            subtitle: "Or click the keyboard widget in the bar, or bind niri's switch-layout"
            icon: "swap_horiz"
            FDropdown {
                implicitWidth: 300
                options: [
                    { value: "", label: "Nothing" },
                    { value: "grp:alt_shift_toggle", label: "Alt + Shift" },
                    { value: "grp:ctrl_shift_toggle", label: "Ctrl + Shift" },
                    { value: "grp:win_space_toggle", label: "Super + Space (clashes with the launcher)" },
                    { value: "grp:alt_space_toggle", label: "Alt + Space" },
                    { value: "grp:caps_toggle", label: "Caps Lock" },
                    { value: "grp:shifts_toggle", label: "Both Shift keys" }
                ]
                current: page.optSwitch
                onSelected: v => page.setOptions(v, page.optCaps, page.optCompose, page.optOther)
            }
        }
    }

    Group {
        title: "Keys"
        SettingRow {
            title: "Caps Lock"
            icon: "keyboard_capslock"
            FDropdown {
                implicitWidth: 280
                options: [
                    { value: "", label: "Caps Lock (default)" },
                    { value: "caps:escape", label: "Escape" },
                    { value: "ctrl:nocaps", label: "Ctrl" },
                    { value: "caps:swapescape", label: "Swap with Escape" },
                    { value: "ctrl:swapcaps", label: "Swap with Ctrl" },
                    { value: "caps:backspace", label: "Backspace" },
                    { value: "caps:none", label: "Disabled" }
                ]
                current: page.optCaps
                onSelected: v => page.setOptions(page.optSwitch, v, page.optCompose, page.optOther)
            }
        }
        SettingRow {
            title: "Compose key"
            subtitle: "Type accents and symbols as sequences, e.g. Compose ' e → é"
            icon: "keyboard_option_key"
            FDropdown {
                implicitWidth: 280
                options: [
                    { value: "", label: "None" },
                    { value: "compose:ralt", label: "Right Alt" },
                    { value: "compose:rctrl", label: "Right Ctrl" },
                    { value: "compose:menu", label: "Menu" },
                    { value: "compose:caps", label: "Caps Lock" },
                    { value: "compose:rwin", label: "Right Super" }
                ]
                current: page.optCompose
                onSelected: v => page.setOptions(page.optSwitch, page.optCaps, v, page.optOther)
            }
        }
        SettingRow {
            title: "Other XKB options"
            subtitle: "Comma-separated, see `man xkeyboard-config`"
            icon: "tune"
            FTextField {
                implicitWidth: 280
                placeholder: "e.g. terminate:ctrl_alt_bksp"
                text: page.optOther.join(",")
                onAccepted: page.setOptions(page.optSwitch, page.optCaps, page.optCompose, text.split(",").map(s => s.trim()).filter(s => s))
                onEditingFinished: page.setOptions(page.optSwitch, page.optCaps, page.optCompose, text.split(",").map(s => s.trim()).filter(s => s))
            }
        }
        SettingRow {
            title: "Repeat delay"
            subtitle: "How long to hold a key before it repeats"
            icon: "timer"
            FSlider {
                width: 260
                from: 150
                to: 1000
                stepSize: 25
                value: page.k.repeatDelay
                showValue: true
                valueText: Math.round(value) + " ms"
                onMoved: v => Keyboard.setInput({ repeatDelay: Math.round(v) })
            }
        }
        SettingRow {
            title: "Repeat rate"
            icon: "speed"
            FSlider {
                width: 260
                from: 10
                to: 80
                stepSize: 1
                value: page.k.repeatRate
                showValue: true
                valueText: Math.round(value) + " /s"
                onMoved: v => Keyboard.setInput({ repeatRate: Math.round(v) })
            }
        }
        SettingRow {
            title: "Try it"
            icon: "edit"
            FTextField {
                implicitWidth: 280
                placeholder: "Hold a key here to test repeat"
            }
        }
        SettingRow {
            title: "Num Lock on at startup"
            icon: "pin"
            FSwitch {
                checked: page.k.numlock
                onToggled: c => Keyboard.setInput({ numlock: c })
            }
        }
        SettingRow {
            title: "Remember layout"
            subtitle: "Per window: each window keeps the layout you last used in it"
            icon: "web_asset"
            FSegmented {
                implicitWidth: 260
                options: [{ value: "global", label: "Everywhere" }, { value: "window", label: "Per window" }]
                current: page.k.trackLayout
                onSelected: v => Keyboard.setInput({ trackLayout: v })
            }
        }
    }

    // ── shortcuts ──
    Group {
        title: "Shortcuts"

        SettingRow {
            title: "Open the launcher with"
            subtitle: Keyboard.norm(page.launcherKey) === "ctrl+space" ? "niri can't tell left and right Ctrl apart, so either works. Apps no longer receive Ctrl+Space (e.g. VS Code suggestions, input-method switching)." : "Or set any key in the launcher's row below"
            icon: "apps"
            FSegmented {
                implicitWidth: 420
                options: [
                    { value: "Mod+Space", label: "Super+Space" },
                    { value: "Ctrl+Space", label: "Ctrl+Space" },
                    { value: "Alt+Space", label: "Alt+Space" },
                    { value: "Mod+D", label: "Super+D" }
                ]
                current: ["Mod+Space", "Ctrl+Space", "Alt+Space", "Mod+D"].find(o => Keyboard.norm(o) === Keyboard.norm(page.launcherKey)) ?? ""
                onSelected: v => page.setLauncherKey(v)
            }
        }

        SettingRow {
            title: "Close windows with"
            subtitle: Keyboard.norm(page.closeKey) === "ctrl+q" ? "Replaces Super+Q. Many apps use Ctrl+Q to quit (Firefox, file managers, editors); with this they no longer get it." : Keyboard.norm(page.closeKey) === "mod+q" ? "niri's default" : "Replaces Super+Q"
            icon: "close"
            FSegmented {
                implicitWidth: 420
                options: [
                    { value: "Mod+Q", label: "Super+Q" },
                    { value: "Ctrl+Q", label: "Ctrl+Q" },
                    { value: "Alt+F4", label: "Alt+F4" },
                    { value: "Mod+Shift+Q", label: "Super+Shift+Q" }
                ]
                current: ["Mod+Q", "Ctrl+Q", "Alt+F4", "Mod+Shift+Q"].find(o => Keyboard.norm(o) === Keyboard.norm(page.closeKey)) ?? ""
                onSelected: v => page.setCloseKey(v)
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 12
            spacing: 8
            FButton {
                text: "Add shortcut"
                icon: "add"
                disabled: page.editing !== -2
                onClicked: page.editing = -1
            }
            FButton {
                text: page.confirmReset ? "Click again to reset" : "Reset all to defaults"
                icon: "restart_alt"
                variant: page.confirmReset ? "filled" : "outlined"
                onClicked: {
                    if (!page.confirmReset) {
                        page.confirmReset = true;
                        resetTimer.restart();
                        return;
                    }
                    page.confirmReset = false;
                    page.editing = -2;
                    Keyboard.resetShortcuts();
                }
                Timer {
                    id: resetTimer
                    interval: 3000
                    onTriggered: page.confirmReset = false
                }
            }
            FText {
                Layout.fillWidth: true
                text: Keyboard.busy ? "Saving…" : Keyboard.status
                dim: true
                elide: Text.ElideRight
                font.pixelSize: Theme.fsSm
            }
        }

        ShortcutEditor {
            visible: page.editing === -1
            initial: ({ key: "", type: "flamenco", value: "launcher", title: "", locked: false })
            taken: page.k.shortcuts.map(s => s.key)
            onCancel: page.editing = -2
            onSave: sc => {
                Keyboard.setShortcuts(page.k.shortcuts.concat([sc]));
                page.editing = -2;
            }
        }

        Repeater {
            model: page.k.shortcuts

            ColumnLayout {
                id: srow
                required property var modelData
                required property int index
                readonly property var def: Keyboard.defaults.find(d => Keyboard.norm(d.key) === Keyboard.norm(modelData.key)) ?? null
                readonly property bool isDefault: def !== null && def.type === modelData.type && String(def.value) === String(modelData.value)
                readonly property string conflict: Keyboard.conflictFor(modelData.key)
                Layout.fillWidth: true
                spacing: 0

                SettingRow {
                    visible: page.editing !== srow.index
                    title: srow.modelData.title || Keyboard.describe(srow.modelData)
                    subtitle: (srow.modelData.title ? Keyboard.describe(srow.modelData) : "") + (srow.conflict ? (srow.modelData.title ? " · " : "") + "replaces: " + srow.conflict : "")
                    icon: srow.modelData.type === "none" ? "block" : srow.modelData.type === "app" ? "apps" : srow.modelData.type === "command" ? "terminal" : srow.modelData.type === "niri" ? "view_column" : "local_fire_department"

                    Row {
                        spacing: 6
                        FKeycaps {
                            anchors.verticalCenter: parent.verticalCenter
                            combo: srow.modelData.key
                            accent: true
                        }
                        Item { width: 6; height: 1 }
                        FIconButton {
                            visible: srow.def !== null && !srow.isDefault
                            icon: "settings_backup_restore"
                            size: 32
                            onClicked: {
                                const list = page.k.shortcuts.slice();
                                list[srow.index] = Object.assign({}, srow.def);
                                Keyboard.setShortcuts(list);
                            }
                        }
                        FIconButton {
                            icon: "edit"
                            size: 32
                            disabled: page.editing !== -2
                            onClicked: page.editing = srow.index
                        }
                        FIconButton {
                            icon: "delete"
                            size: 32
                            iconColor: Theme.error
                            onClicked: Keyboard.setShortcuts(page.k.shortcuts.filter((_, i) => i !== srow.index))
                        }
                    }
                }

                ShortcutEditor {
                    visible: page.editing === srow.index
                    initial: srow.modelData
                    taken: page.k.shortcuts.filter((_, i) => i !== srow.index).map(s => s.key)
                    onCancel: page.editing = -2
                    onSave: sc => {
                        const list = page.k.shortcuts.slice();
                        list[srow.index] = sc;
                        Keyboard.setShortcuts(list);
                        page.editing = -2;
                    }
                }
            }
        }

        SettingRow {
            title: Keyboard.others.length + " other niri bindings"
            subtitle: "Window, workspace and media keys in your config. Press Mod+Shift+/ in niri to see them all."
            icon: "info"
        }
    }
}
