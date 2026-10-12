import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

// Add / edit one shortcut. `taken` lists keys used by the other Flamenco shortcuts.
Rectangle {
    id: root

    property var initial: ({ key: "", type: "flamenco", value: "launcher", title: "", locked: false })
    property var taken: []
    signal save(var shortcut)
    signal cancel

    property string key: initial.key ?? ""
    property string type: initial.type ?? "flamenco"
    property string value: String(initial.value ?? "")
    property string title: initial.title ?? ""
    property bool locked: initial.locked ?? false

    // start from `initial` every time the editor opens
    function reset() {
        key = initial.key ?? "";
        type = initial.type ?? "flamenco";
        value = String(initial.value ?? "");
        title = initial.title ?? "";
        locked = initial.locked ?? false;
        typed.text = key;
        niriText.text = type === "niri" ? value : "";
    }
    onVisibleChanged: if (visible) reset()

    readonly property bool duplicate: key !== "" && taken.some(k => Keyboard.norm(k) === Keyboard.norm(key))
    readonly property bool validKey: /^[A-Za-z0-9_]+(\+[A-Za-z0-9_]+)*$/.test(key)
    readonly property string conflict: key ? Keyboard.conflictFor(key) : ""
    readonly property bool valid: validKey && !duplicate && (type === "none" || value.trim() !== "")

    Layout.fillWidth: true
    Layout.margins: 8
    implicitHeight: col.implicitHeight + Theme.sp4 * 2
    radius: Theme.rLg
    color: Theme.surfaceHigh
    border.width: 1
    border.color: Theme.alpha(Theme.accent, 0.5)

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: Theme.sp4
        spacing: Theme.sp3

        FText {
            text: root.initial.key ? "Edit shortcut" : "New shortcut"
            font.pixelSize: Theme.fsLg
            font.weight: Font.Bold
        }

        // key
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            FText { text: "Keys"; dim: true; font.pixelSize: Theme.fsSm }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                FKeyRecorder {
                    Layout.fillWidth: true
                    value: root.key
                    onRecorded: combo => {
                        root.key = combo;
                        typed.text = combo;
                    }
                }
                FTextField {
                    id: typed
                    implicitWidth: 200
                    placeholder: "or type: Mod+Shift+S"
                    text: root.key
                    onEdited: t => root.key = t.trim()
                }
            }
            FText {
                Layout.fillWidth: true
                visible: text !== ""
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fsSm
                color: root.duplicate || (root.key && !root.validKey) ? Theme.error : Theme.warning
                text: root.key && !root.validKey ? "Use niri key names joined by +, e.g. Mod+Shift+S, Ctrl+Alt+T, XF86AudioPlay"
                    : root.duplicate ? "Another Flamenco shortcut already uses " + root.key
                    : root.conflict ? "Replaces your niri binding: " + root.conflict + " (it's commented out, not deleted)" : ""
            }
            FText {
                Layout.fillWidth: true
                text: "Mod is Super (the Windows key). Combinations niri already uses won't reach this window, so type those instead."
                dim: true
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fsXs
            }
        }

        // action
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            FText { text: "Does"; dim: true; font.pixelSize: Theme.fsSm }
            FSegmented {
                Layout.fillWidth: true
                options: [
                    { value: "flamenco", label: "Shell function", icon: "local_fire_department" },
                    { value: "app", label: "Open app", icon: "apps" },
                    { value: "command", label: "Run command", icon: "terminal" },
                    { value: "niri", label: "niri action", icon: "view_column" },
                    { value: "none", label: "Disable key", icon: "block" }
                ]
                current: root.type
                onSelected: v => {
                    if (v === root.type)
                        return;
                    root.type = v;
                    root.value = v === "flamenco" ? "launcher" : v === "niri" ? "toggle-overview" : "";
                    if (v === "none")
                        root.title = "";
                }
            }

            FDropdown {
                visible: root.type === "flamenco"
                Layout.fillWidth: true
                options: Keyboard.functions
                current: root.value
                onSelected: v => root.value = v
            }

            FDropdown {
                visible: root.type === "app"
                Layout.fillWidth: true
                placeholder: "Choose an app…"
                options: Apps.all.map(e => ({ value: e.id, label: e.name }))
                current: root.value
                onSelected: v => root.value = v
            }

            FTextField {
                visible: root.type === "command"
                Layout.fillWidth: true
                icon: "terminal"
                placeholder: "e.g. grim -g \"$(slurp)\" - | wl-copy"
                text: root.type === "command" ? root.value : ""
                onEdited: t => root.value = t
            }

            FText {
                visible: root.type === "none"
                Layout.fillWidth: true
                text: "The key will do nothing. Use this to switch off a niri binding you don't want; your original line is commented out and comes back if you delete this."
                dim: true
                wrapMode: Text.Wrap
            }

            RowLayout {
                visible: root.type === "niri"
                Layout.fillWidth: true
                spacing: 8
                FDropdown {
                    Layout.preferredWidth: 260
                    placeholder: "Common actions"
                    options: Keyboard.niriActions
                    current: root.value
                    onSelected: v => {
                        root.value = v;
                        niriText.text = v;
                    }
                }
                FTextField {
                    id: niriText
                    Layout.fillWidth: true
                    placeholder: "any niri action, e.g. focus-workspace 3"
                    text: root.type === "niri" ? root.value : ""
                    onEdited: t => root.value = t.trim()
                }
            }
        }

        // title + lock
        RowLayout {
            visible: root.type !== "none"
            Layout.fillWidth: true
            spacing: 12
            FTextField {
                Layout.fillWidth: true
                icon: "label"
                placeholder: "Name in niri's hotkey overlay (optional)"
                text: root.title
                onEdited: t => root.title = t
            }
            FText { visible: root.type !== "niri"; text: "Works when locked"; dim: true; font.pixelSize: Theme.fsSm }
            FSwitch {
                visible: root.type !== "niri"
                checked: root.locked
                onToggled: c => root.locked = c
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 8
            FButton {
                text: "Cancel"
                variant: "outlined"
                onClicked: root.cancel()
            }
            FButton {
                text: "Save shortcut"
                icon: "check"
                disabled: !root.valid
                onClicked: root.save({ key: root.key, type: root.type, value: root.value.trim(), title: root.title.trim(), locked: root.type !== "niri" && root.locked })
            }
        }
    }
}
