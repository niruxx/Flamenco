import QtQuick
import qs.Widgets

SettingRow {
    id: root
    property var target
    property string key
    property var options: []
    property int segWidth: 96
    signal edited
    FSegmented {
        implicitWidth: root.options.length * root.segWidth
        options: root.options
        current: root.target[root.key]
        onSelected: v => {
            root.target[root.key] = v;
            root.edited();
        }
    }
}
