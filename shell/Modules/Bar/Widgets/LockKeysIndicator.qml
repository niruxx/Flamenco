import QtQuick
import qs.Commons
import qs.Services
import qs.Widgets

// Caps Lock and Num Lock: a letter "A" and a "1" that light up while on (Settings →
// Bar → Lock keys: only while on, or always).
BarChip {
    id: root
    property string screenName
    property int barLevel: 0
    readonly property bool always: Settings.data.bar.lockKeysAlways ?? false
    property bool barVisible: always || LockKeys.caps || LockKeys.num
    Component.onCompleted: LockKeys.users++
    Component.onDestruction: LockKeys.users--

    BarFlow {
        spacing: 4
        Repeater {
            model: [{ on: LockKeys.caps, t: "A", show: root.always || LockKeys.caps }, { on: LockKeys.num, t: "1", show: root.always || LockKeys.num }]
            Rectangle {
                required property var modelData
                visible: modelData.show
                width: Math.round(Theme.barItem * 0.62)
                height: width
                radius: Theme.rSm
                color: modelData.on ? Theme.accent : "transparent"
                border.width: modelData.on ? 0 : 1
                border.color: Theme.alpha(Theme.text, 0.3)
                FText {
                    anchors.centerIn: parent
                    text: parent.modelData.t
                    font.pixelSize: Theme.fsSm
                    font.weight: Font.Bold
                    color: parent.modelData.on ? Theme.onAccent : Theme.textDim
                }
            }
        }
    }
}
