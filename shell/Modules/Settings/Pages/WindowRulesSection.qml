import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

// Settings → Windows → Window rules: per app (and title), how its windows open:
// floating or tiled, a size, maximized or fullscreen, on a screen or workspace,
// see-through, hidden from screen sharing. Written into the niri (or Hyprland)
// config by `flamenco compositor apply`, for windows opened afterwards.
Group {
    id: root
    title: "Window rules"
    readonly property var rules: Settings.data.windows.rules || []

    function add(app) {
        Settings.data.windows.rules = rules.concat([{ app: app, title: "", floating: "", width: "", height: "", maximized: false, fullscreen: false, output: "", workspace: "", opacity: 1, noScreencast: false }]);
        Compositor.queue();
    }

    SettingRow {
        title: rules.length ? rules.length + (rules.length === 1 ? " rule" : " rules") : "No rules yet"
        subtitle: "How an app's windows open: floating, a size, a screen or workspace, see-through, hidden from screen sharing. For windows opened after a change"
        icon: "rule"
        Row {
            spacing: 6
            FDropdown {
                implicitWidth: 200
                placeholder: "Add for an open app…"
                options: [...new Set(Niri.windows.map(w => w.app_id).filter(Boolean))].map(a => ({ value: a, label: Apps.lookup(a)?.name ?? a }))
                onSelected: v => root.add(v)
            }
            FButton {
                text: "New rule"
                icon: "add"
                variant: "tonal"
                onClicked: root.add("")
            }
        }
    }
    ColumnLayout {
        Layout.fillWidth: true
        Layout.margins: Theme.sp3
        Layout.topMargin: 0
        visible: root.rules.length > 0
        spacing: Theme.sp2
        // by count, not by the list: an edit replaces the list, and the cards (with one
        // open, or a slider held) mustn't be rebuilt for it
        Repeater {
            model: root.rules.length
            WindowRuleCard {
                rule: root.rules[index] ?? ({})
                // a new, empty rule opens for editing
                Component.onCompleted: open = !rule.app && !rule.title
            }
        }
    }
    FText {
        Layout.fillWidth: true
        Layout.margins: Theme.sp3
        Layout.topMargin: 0
        visible: Compositor.failed || Compositor.status !== ""
        text: Compositor.status
        color: Compositor.failed ? Theme.error : Theme.textDim
        font.pixelSize: Theme.fsXs
        wrapMode: Text.Wrap
    }
}
