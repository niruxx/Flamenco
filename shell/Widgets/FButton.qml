import QtQuick
import QtQuick.Layouts
import qs.Commons

// variant: filled | tonal | outlined | text
Rectangle {
    id: root

    property string text
    property string icon
    property string variant: "filled"
    property bool disabled: false
    readonly property color fg: variant === "filled" ? Theme.onAccent : variant === "tonal" ? Theme.text : Theme.accent

    signal clicked

    implicitHeight: 36
    implicitWidth: row.implicitWidth + 32
    radius: sl.pressed ? Theme.rSm : height / 2
    color: variant === "filled" ? Theme.accent : variant === "tonal" ? Theme.surfaceHighest : "transparent"
    border.width: variant === "outlined" ? 1 : 0
    border.color: Theme.border
    opacity: disabled ? 0.45 : 1

    Behavior on radius { Anim { duration: Theme.durShort } }
    Behavior on color { CAnim {} }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6

        FIcon {
            visible: root.icon !== ""
            icon: root.icon
            size: 18
            color: root.fg
        }
        FText {
            text: root.text
            color: root.fg
            font.weight: Font.DemiBold
        }
    }

    StateLayer {
        id: sl
        disabled: root.disabled
        tint: root.fg
        onClicked: root.clicked()
    }
}
