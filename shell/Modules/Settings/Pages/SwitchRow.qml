import QtQuick
import qs.Widgets

SettingRow {
    id: root
    property var target
    property string key
    FSwitch {
        checked: root.target[root.key]
        onToggled: c => root.target[root.key] = c
    }
}
