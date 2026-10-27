import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: I18n.tr("Keyboard")
    subtitle: I18n.tr("Layouts and shortcuts. Everything here is written to your niri config (~/.config/niri/config.kdl) and applies immediately.")

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
            list.unshift({ key: key, type: "flamenco", value: "launcher", title: I18n.tr("Launcher") });
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
            list = list.concat([{ key: key, type: "niri", value: "close-window", title: I18n.tr("Close window") }, { key: I18n.tr("Mod+Q"), type: "none", value: "" }]);
        Keyboard.setShortcuts(list);
    }

    function setOptions(sw, caps, compose, other) {
        Keyboard.setInput({ options: [sw, caps, compose].concat(other).filter(o => o).join(",") });
    }

    // ── backlight (only on keyboards that have one) ──
    Group {
        title: I18n.tr("Cheat sheet")
        SettingRow {
            title: I18n.tr("See every shortcut")
            subtitle: I18n.tr("All the key bindings in your compositor config, grouped. Bind the Flamenco function \"Keyboard shortcuts cheat sheet\" below to open it from the keyboard, or run flamenco keys show.")
            icon: "keyboard_keys"
            FButton {
                text: I18n.tr("Show")
                variant: "tonal"
                onClicked: {
                    Panels.settingsOpen = false;
                    Panels.open("keys", "");
                }
            }
        }
    }

    Group {
        visible: Brightness.kbdAvailable
        title: I18n.tr("Backlight")

        SettingRow {
            title: I18n.tr("Keyboard brightness")
            subtitle: Brightness.kbdMax <= 10 ? Brightness.kbdMax + " levels · also on the keyboard's backlight keys" : I18n.tr("Also on the keyboard's backlight keys")
            icon: Brightness.kbdLevel > 0 ? "backlight_high" : "backlight_high_off"
            FSlider {
                width: 260
                showValue: true
                value: Brightness.kbdValue
                stepSize: Brightness.kbdMax > 0 && Brightness.kbdMax <= 10 ? 1 / Brightness.kbdMax : 0
                accent: Theme.accent3
                onMoved: v => Brightness.setKbd(v)
            }
        }
    }

    // ── layout ──
    Group {
        title: I18n.tr("Layout")

        Repeater {
            model: page.layouts
            SettingRow {
                id: lrow
                required property string modelData
                required property int index
                title: page.layoutLabel(modelData)
                subtitle: index === 0 ? I18n.tr("Default layout") : ""
                icon: "language"
                Row {
                    spacing: 4
                    FDropdown {
                        implicitWidth: 220
                        placeholder: I18n.tr("Variant")
                        options: [{ value: "", label: I18n.tr("Default variant") }].concat(Keyboard.catalog.variants[lrow.modelData] ?? [])
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
            title: page.layouts.length ? I18n.tr("Add a layout") : I18n.tr("Layouts")
            subtitle: page.layouts.length ? "" : I18n.tr("None set: niri uses the system keymap (localectl)")
            icon: "add"
            FDropdown {
                implicitWidth: 300
                placeholder: I18n.tr("Choose a layout…")
                options: Keyboard.catalog.layouts.filter(l => !page.layouts.includes(l.value))
                current: ""
                onSelected: v => page.setLayouts(page.layouts.concat([v]), page.variants.concat([""]))
            }
        }

        SettingRow {
            visible: page.layouts.length > 1
            title: I18n.tr("Switch layouts with")
            subtitle: I18n.tr("Or click the keyboard widget in the bar, or bind niri's switch-layout")
            icon: "swap_horiz"
            FDropdown {
                implicitWidth: 300
                options: [
                    { value: "", label: I18n.tr("Nothing") },
                    { value: "grp:alt_shift_toggle", label: I18n.tr("Alt + Shift") },
                    { value: "grp:ctrl_shift_toggle", label: I18n.tr("Ctrl + Shift") },
                    { value: "grp:win_space_toggle", label: I18n.tr("Super + Space (clashes with the launcher)") },
                    { value: "grp:alt_space_toggle", label: I18n.tr("Alt + Space") },
                    { value: "grp:caps_toggle", label: I18n.tr("Caps Lock") },
                    { value: "grp:shifts_toggle", label: I18n.tr("Both Shift keys") }
                ]
                current: page.optSwitch
                onSelected: v => page.setOptions(v, page.optCaps, page.optCompose, page.optOther)
            }
        }
    }

    Group {
        title: I18n.tr("Keys")
        SettingRow {
            title: I18n.tr("Caps Lock")
            icon: "keyboard_capslock"
            FDropdown {
                implicitWidth: 280
                options: [
                    { value: "", label: I18n.tr("Caps Lock (default)") },
                    { value: "caps:escape", label: I18n.tr("Escape") },
                    { value: "ctrl:nocaps", label: I18n.tr("Ctrl") },
                    { value: "caps:swapescape", label: I18n.tr("Swap with Escape") },
                    { value: "ctrl:swapcaps", label: I18n.tr("Swap with Ctrl") },
                    { value: "caps:backspace", label: I18n.tr("Backspace") },
                    { value: "caps:none", label: I18n.tr("Disabled") }
                ]
                current: page.optCaps
                onSelected: v => page.setOptions(page.optSwitch, v, page.optCompose, page.optOther)
            }
        }
        SettingRow {
            title: I18n.tr("Compose key")
            subtitle: I18n.tr("Type accents and symbols as sequences, e.g. Compose ' e → é")
            icon: "keyboard_option_key"
            FDropdown {
                implicitWidth: 280
                options: [
                    { value: "", label: I18n.tr("None") },
                    { value: "compose:ralt", label: I18n.tr("Right Alt") },
                    { value: "compose:rctrl", label: I18n.tr("Right Ctrl") },
                    { value: "compose:menu", label: I18n.tr("Menu") },
                    { value: "compose:caps", label: I18n.tr("Caps Lock") },
                    { value: "compose:rwin", label: I18n.tr("Right Super") }
                ]
                current: page.optCompose
                onSelected: v => page.setOptions(page.optSwitch, page.optCaps, v, page.optOther)
            }
        }
        SettingRow {
            title: I18n.tr("Other XKB options")
            subtitle: I18n.tr("Comma-separated, see `man xkeyboard-config`")
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
            title: I18n.tr("Repeat delay")
            subtitle: I18n.tr("How long to hold a key before it repeats")
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
            title: I18n.tr("Repeat rate")
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
            title: I18n.tr("Try it")
            icon: "edit"
            FTextField {
                implicitWidth: 280
                placeholder: I18n.tr("Hold a key here to test repeat")
            }
        }
        SettingRow {
            title: I18n.tr("Num Lock on at startup")
            icon: "pin"
            FSwitch {
                checked: page.k.numlock
                onToggled: c => Keyboard.setInput({ numlock: c })
            }
        }
        SettingRow {
            title: I18n.tr("Remember layout")
            subtitle: I18n.tr("Per window: each window keeps the layout you last used in it")
            icon: "web_asset"
            FSegmented {
                implicitWidth: 260
                options: [{ value: "global", label: I18n.tr("Everywhere") }, { value: "window", label: I18n.tr("Per window") }]
                current: page.k.trackLayout
                onSelected: v => Keyboard.setInput({ trackLayout: v })
            }
        }
    }

    // ── shortcuts ──
    Group {
        title: I18n.tr("Shortcuts")

        SettingRow {
            title: I18n.tr("Open the launcher with")
            subtitle: Keyboard.norm(page.launcherKey) === "ctrl+space" ? "niri can't tell left and right Ctrl apart, so either works. Apps no longer receive Ctrl+Space (e.g. VS Code suggestions, input-method switching)." : I18n.tr("Or set any key in the launcher's row below")
            icon: "apps"
            FSegmented {
                implicitWidth: 420
                options: [
                    { value: I18n.tr("Mod+Space"), label: I18n.tr("Super+Space") },
                    { value: I18n.tr("Ctrl+Space"), label: I18n.tr("Ctrl+Space") },
                    { value: I18n.tr("Alt+Space"), label: I18n.tr("Alt+Space") },
                    { value: I18n.tr("Mod+D"), label: I18n.tr("Super+D") }
                ]
                current: ["Mod+Space", "Ctrl+Space", "Alt+Space", "Mod+D"].find(o => Keyboard.norm(o) === Keyboard.norm(page.launcherKey)) ?? ""
                onSelected: v => page.setLauncherKey(v)
            }
        }

        SettingRow {
            title: I18n.tr("Close windows with")
            subtitle: Keyboard.norm(page.closeKey) === "ctrl+q" ? I18n.tr("Replaces Super+Q. Many apps use Ctrl+Q to quit (Firefox, file managers, editors); with this they no longer get it.") : Keyboard.norm(page.closeKey) === "mod+q" ? "niri's default" : I18n.tr("Replaces Super+Q")
            icon: "close"
            FSegmented {
                implicitWidth: 420
                options: [
                    { value: I18n.tr("Mod+Q"), label: I18n.tr("Super+Q") },
                    { value: I18n.tr("Ctrl+Q"), label: I18n.tr("Ctrl+Q") },
                    { value: I18n.tr("Alt+F4"), label: I18n.tr("Alt+F4") },
                    { value: I18n.tr("Mod+Shift+Q"), label: I18n.tr("Super+Shift+Q") }
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
                text: I18n.tr("Add shortcut")
                icon: "add"
                disabled: page.editing !== -2
                onClicked: page.editing = -1
            }
            FButton {
                text: page.confirmReset ? I18n.tr("Click again to reset") : I18n.tr("Reset all to defaults")
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
                text: Keyboard.busy ? I18n.tr("Saving…") : Keyboard.status
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
            subtitle: I18n.tr("Window, workspace and media keys in your config. Press Mod+Shift+/ in niri to see them all.")
            icon: "info"
        }
    }
}
