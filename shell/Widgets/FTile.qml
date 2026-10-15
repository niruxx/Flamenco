import QtQuick
import QtQuick.Layouts
import qs.Commons

// Quick-settings tile, in one of two looks (Settings → Quick settings → Style):
//   cards    icon on top, title and state below, filled with its tint when on
//   classic  icon beside the text; morphs shape and color when toggled
Rectangle {
    id: root

    property string icon
    property string title
    property string subtitle
    property bool active: false
    property bool hasDetails: false
    property color tint: Theme.accent
    readonly property bool cards: (Settings.data.control.style || "cards") === "cards"

    signal clicked
    signal detailsClicked

    implicitHeight: cards ? 80 : 64
    implicitWidth: 180
    radius: cards ? Theme.rLg : active ? Theme.rLg : Theme.rMd
    color: active ? (cards ? tint : Theme.accent) : cards ? Theme.alpha(Theme.text, main.containsMouse ? 0.09 : 0.05) : Theme.surfaceHigh
    border.width: cards && !active ? 1 : 0
    border.color: Theme.alpha(Theme.text, 0.08)
    scale: main.pressed ? 0.97 : 1

    Behavior on radius { Anim { easing.bezierCurve: Theme.curves.spring } }
    Behavior on color { CAnim {} }
    Behavior on scale { Anim { duration: Theme.durShort } }

    readonly property color fg: active ? Theme.onAccent : Theme.text

    // classic: a row
    RowLayout {
        visible: !root.cards
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

    // cards: icon on top
    ColumnLayout {
        visible: root.cards
        anchors.fill: parent
        anchors.margins: 12
        spacing: 1

        FIcon {
            icon: root.icon
            size: 22
            fill: root.active ? 1 : 0
            color: root.active ? root.fg : root.tint
        }
        Item { Layout.fillHeight: true }
        FText {
            Layout.fillWidth: true
            text: root.title
            color: root.fg
            font.weight: Font.Bold
            font.pixelSize: Theme.fsSm
            elide: Text.ElideRight
        }
        FText {
            Layout.fillWidth: true
            visible: text !== ""
            text: root.subtitle
            color: root.active ? Theme.alpha(Theme.onAccent, 0.8) : Theme.textDim
            font.pixelSize: Theme.fsXs
            elide: Text.ElideRight
        }
    }
    FIconButton {
        visible: root.cards && root.hasDetails
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 4
        icon: "chevron_right"
        size: 28
        iconColor: root.fg
        onClicked: root.detailsClicked()
        z: 3
    }

    StateLayer {
        id: main
        z: -1 // below the content so the details button gets its own clicks
        tint: root.fg
        onClicked: root.clicked()
    }
}
