import QtQuick
import qs.Widgets

SettingRow {
    id: root
    property var target
    property string key
    signal edited
    FSwitch {
        accessibleName: root.title
        checked: root.target[root.key]
        onToggled: c => {
            root.target[root.key] = c;
            root.edited();
        }
    }
}
