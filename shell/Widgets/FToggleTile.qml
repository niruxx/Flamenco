import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

// A toggle tile on the dashboard's Home: icon on top, title and state below.
// On: filled with its tint. Right-click (or ⋯) for more, where there's more.
Rectangle {
    id: root

    property string icon
    property string title
    property string subtitle
    property bool active: false
    property color tint: Theme.accent
    property bool hasMore: false
    signal clicked
    signal moreClicked

    readonly property color fg: active ? Theme.onAccent : Theme.text
    implicitHeight: 76
    radius: Theme.rLg
    color: active ? tint : Theme.alpha(Theme.text, area.containsMouse ? 0.09 : 0.05)
    border.width: active ? 0 : 1
    border.color: Theme.alpha(Theme.text, 0.08)
    scale: area.pressed ? 0.96 : 1

    Behavior on color { CAnim {} }
    Behavior on scale { Anim { duration: Theme.durShort; easing.bezierCurve: Theme.curves.springFast } }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 2

        FIcon {
            icon: root.icon
            size: 20
            fill: root.active ? 1 : 0
            color: root.active ? root.fg : root.tint
        }
        Item { Layout.fillHeight: true }
        FText {
            Layout.fillWidth: true
            text: root.title
            font.weight: Font.Bold
            font.pixelSize: Theme.fsSm
            color: root.fg
            elide: Text.ElideRight
        }
        FText {
            Layout.fillWidth: true
            text: root.subtitle
            font.pixelSize: Theme.fsXs
            color: root.active ? Theme.alpha(Theme.onAccent, 0.8) : Theme.textDim
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => mouse.button === Qt.RightButton && root.hasMore ? root.moreClicked() : root.clicked()
    }

    FIconButton {
        visible: root.hasMore && area.containsMouse
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 4
        size: 26
        icon: "more_horiz"
        iconColor: root.fg
        onClicked: root.moreClicked()
    }
}
