import QtQuick
import QtQuick.Layouts
import qs.Commons

// Quick-settings tile. Morphs shape and color when toggled.
Rectangle {
    id: root

    property string icon
    property string title
    property string subtitle
    property bool active: false
    property bool hasDetails: false

    signal clicked
    signal detailsClicked

    implicitHeight: 64
    implicitWidth: 180
    radius: active ? Theme.rLg : Theme.rMd
    color: active ? Theme.accent : Theme.surfaceHigh
    scale: main.pressed ? 0.97 : 1

    Behavior on radius { Anim { easing.bezierCurve: Theme.curves.spring } }
    Behavior on color { CAnim {} }
    Behavior on scale { Anim { duration: Theme.durShort } }

    readonly property color fg: active ? Theme.onAccent : Theme.text

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 6
        spacing: 12

        FIcon {
            icon: root.icon
            size: 22
            fill: root.active ? 1 : 0
            color: root.fg
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            FText {
                Layout.fillWidth: true
                text: root.title
                color: root.fg
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            FText {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.subtitle
                color: root.fg
                opacity: 0.75
                font.pixelSize: Theme.fsSm
                elide: Text.ElideRight
            }
        }

        FIconButton {
            visible: root.hasDetails
            icon: "chevron_right"
            size: 30
            iconColor: root.fg
            onClicked: root.detailsClicked()
            z: 3
        }
    }

    StateLayer {
        id: main
        z: -1 // below the row so the details chevron gets its own clicks
        tint: root.fg
        onClicked: root.clicked()
    }
}
