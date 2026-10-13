import QtQuick
import qs.Widgets

SettingRow {
    id: root
    property var target
    property string key
    property string placeholder
    signal edited
    function commit(v) {
        if (root.target[root.key] === v)
            return;
        root.target[root.key] = v;
        root.edited();
    }
    FTextField {
        implicitWidth: 280
        text: root.target[root.key]
        placeholder: root.placeholder
        onAccepted: root.commit(text)
        onEditingFinished: root.commit(text)
    }
}
