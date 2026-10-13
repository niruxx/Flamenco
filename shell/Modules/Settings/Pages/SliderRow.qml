import QtQuick
import qs.Commons
import qs.Widgets

SettingRow {
    id: root
    property var target
    property string key
    property real from: 0
    property real to: 1
    property real stepSize: 0
    property string suffix: ""
    property int decimals: 0
    property real factor: 1
    signal edited
    FSlider {
        width: 260
        from: root.from
        to: root.to
        stepSize: root.stepSize
        value: root.target[root.key]
        showValue: true
        valueText: (value * root.factor).toFixed(root.decimals) + root.suffix
        onMoved: v => {
            root.target[root.key] = v;
            root.edited();
        }
    }
}
