import QtQuick
import qs.Widgets

SettingRow {
    id: root
    property var target
    property string key
    property string placeholder
    FTextField {
        implicitWidth: 280
        text: root.target[root.key]
        placeholder: root.placeholder
        onAccepted: root.target[root.key] = text
        onEditingFinished: root.target[root.key] = text
    }
}
