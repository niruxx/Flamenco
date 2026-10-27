import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

// Settings → Notifications → App rules: per app (and words in the text), whether
// its notifications pop up (never, or even in Do Not Disturb), make a sound, how
// urgent they are, how long they stay, and whether they're kept in history.
Group {
    id: root
    title: "App rules"
    readonly property var rules: Settings.data.notifications.rules || []

    function add(app) {
        Settings.data.notifications.rules = rules.concat([{ app: app, contains: "", popup: "default", sound: true, urgency: "default", timeout: 0, history: true }]);
    }

    SettingRow {
        title: rules.length ? rules.length + (rules.length === 1 ? " rule" : " rules") : "No rules yet"
        subtitle: Mako.found && Settings.data.notifications.backend === "mako" ? "Mako shows notifications now, so these don't apply (they're for Flamenco's own)"
            : "Quiet a chatty app, let an important one through Do Not Disturb, keep some out of history. The first rule that matches counts"
        icon: "rule"
        Row {
            spacing: 6
            FDropdown {
                implicitWidth: 200
                placeholder: "Add for an app…"
                options: Notifs.apps
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
        // by count, not by the list, so a card being edited isn't rebuilt by each change
        Repeater {
            model: root.rules.length
            NotificationRuleCard {
                rule: root.rules[index] ?? ({})
                Component.onCompleted: open = !rule.app
            }
        }
    }
}
