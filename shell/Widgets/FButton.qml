import QtQuick
import QtQuick.Layouts
import qs.Commons

// variant: filled | tonal | outlined | text
Rectangle {
    id: root

    activeFocusOnTab: true
    enabled: !disabled
    Accessible.role: Accessible.Button
    Accessible.name: text
    Accessible.onPressAction: if (enabled) clicked()
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (!event.isAutoRepeat)
                root.clicked();
            event.accepted = true;
        }
    }

    FocusRing {}

    property string text
    property string icon
    property string variant: "filled"
    property bool disabled: false
    readonly property color fg: variant === "filled" ? Theme.onAccent : variant === "tonal" ? Theme.onAccentContainer : Theme.accent

    signal clicked

    implicitHeight: Theme.controlHeight
    implicitWidth: row.implicitWidth + Theme.sp5 * 2
    radius: sl.pressed ? Theme.rSm : height / 2
    color: variant === "filled" ? Theme.accent : variant === "tonal" ? Theme.accentContainer : "transparent"
    border.width: variant === "outlined" ? 1 : 0
    border.color: Theme.border
    opacity: disabled ? 0.45 : 1

    Behavior on radius { Anim { motionRole: "feedback" } }
    Finish { strength: 0.24; visible: Theme.materialGlass && root.variant !== "text" }

    Behavior on color { CAnim {} }

    RowLayout {
        id: row
        anchors.centerIn: parent
        width: Math.max(0, Math.min(implicitWidth, root.width - Theme.sp4 * 2))
        spacing: Theme.sp2

        FIcon {
            visible: root.icon !== ""
            icon: root.icon
            size: Math.round(18 * Theme.scale)
            color: root.fg
        }
        FText {
            Layout.fillWidth: true
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
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
