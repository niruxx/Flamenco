import QtQuick
import qs.Commons
import qs.Widgets

// An opacity slider for one part of the UI (Appearance → Transparency). With
// `follows` set, -1 means "the same as the panels": the slider shows the panels'
// value, and a reset button appears once it has its own.
SettingRow {
    id: root
    property var target
    property string key
    property bool follows: false
    property real from: 0.3
    readonly property real raw: target[key] ?? -1
    readonly property bool own: !follows || raw >= 0
    readonly property real shown: own ? raw : Settings.data.appearance.panelOpacity
    signal edited

    Row {
        spacing: 6
        FSlider {
            anchors.verticalCenter: parent.verticalCenter
            width: 240
            from: root.from
            to: 1
            stepSize: 0.01
            value: root.shown
            showValue: true
            valueText: root.own ? Math.round(value * 100) + "%" : "= panels"
            onMoved: v => {
                root.target[root.key] = v;
                root.edited();
            }
        }
        FIconButton {
            visible: root.follows && root.own
            anchors.verticalCenter: parent.verticalCenter
            icon: "link"
            size: 30
            iconSize: 16
            onClicked: {
                root.target[root.key] = -1;
                root.edited();
            }
        }
    }
}
