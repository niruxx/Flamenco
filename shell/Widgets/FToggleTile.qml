import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

// A toggle tile on the dashboard's Home: icon on top, title and state below.
// On: filled with its tint. Right-click (or ⋯) for more, where there's more.
Rectangle {
    id: root

    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: title
    Accessible.checkable: true
    Accessible.checked: active
    Accessible.onPressAction: if (enabled) clicked()
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (!event.isAutoRepeat)
                root.clicked();
            event.accepted = true;
        }
    }

    FocusRing {}

    property string icon
    property string title
    property string subtitle
    property bool active: false
    property color tint: Theme.accent
    property bool hasMore: false
    signal clicked
    signal moreClicked

    readonly property color fg: active ? Theme.onColor(tint) : Theme.text
    implicitHeight: Math.round(104 * Theme.scale)
    implicitWidth: 120
    radius: area.pressed ? Theme.rMd : Theme.rLg
    color: active ? tint : Theme.controlSurface
    scale: area.pressed && Theme.spatialMotion() ? 0.98 : 1

    Behavior on radius { Anim { motionRole: "feedback" } }
    Finish { strength: 0.4; visible: Theme.materialGlass }

    Behavior on color { CAnim {} }
    Behavior on scale { Anim { motionRole: "feedback"; easing.bezierCurve: Theme.curves.springFast } }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.sp4
        anchors.rightMargin: Theme.sp4
        anchors.topMargin: Theme.sp3
        anchors.bottomMargin: Theme.sp3
        spacing: 3

        FIcon {
            icon: root.icon
            size: Theme.iconSize
            fill: root.active ? 1 : 0
            color: root.active ? root.fg : root.tint
        }
        Item { Layout.fillHeight: true }
        FText {
            Layout.fillWidth: true
            text: root.title
            font.weight: Font.Bold
            font.pixelSize: Theme.fsMd
            color: root.fg
            elide: Text.ElideRight
        }
        FText {
            Layout.fillWidth: true
            visible: text !== ""
            text: root.subtitle
            font.pixelSize: Theme.fsSm
            color: root.active ? Theme.alpha(root.fg, 0.8) : Theme.textDim
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

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.fg
        opacity: area.pressed ? 0.1 : area.containsMouse ? 0.08 : 0
        Behavior on opacity { Anim { motionRole: "feedback" } }
    }

    FIconButton {
        visible: root.hasMore
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 4
        size: 26
        icon: "more_horiz"
        accessibleName: root.title + " · " + I18n.tr("More options")
        iconColor: root.fg
        onClicked: root.moreClicked()
    }
}
