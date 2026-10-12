import QtQuick
import qs.Widgets

SettingRow {
    id: root
    property var target
    property string key
    property var options: []
    property string placeholder: "Select…"
    FDropdown {
        implicitWidth: 280
        options: root.options
        current: root.target[root.key]
        placeholder: root.placeholder
        onSelected: v => root.target[root.key] = v
    }
}
