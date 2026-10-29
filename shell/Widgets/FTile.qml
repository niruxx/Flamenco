import QtQuick
import QtQuick.Layouts
import qs.Commons

// Quick-settings tile, in one of two looks (Settings → Quick settings → Style):
//   cards    icon on top, title and state below, filled with its tint when on
//   classic  icon beside the text; morphs shape and color when toggled
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
    property bool hasDetails: false
    property color tint: Theme.accent
    readonly property real spacingScale: Math.max(1, Math.min(1.6, Settings.data.control.panelSpacing ?? 1))
    readonly property bool pills: Settings.data.control.style === "pills"
    readonly property bool cards: (Settings.data.control.style || "cards") === "cards"

    signal clicked
    signal detailsClicked

    implicitHeight: Math.round((cards ? 104 : pills ? 76 : 64) * Theme.scale * spacingScale)
    implicitWidth: 180
    radius: pills ? height / 2 : main.pressed ? Theme.rMd : cards ? Theme.rLg : active ? Theme.rLg : Theme.rMd
    color: active ? (pills ? Theme.accentContainer : cards ? tint : Theme.accent) : Theme.controlSurface
    scale: main.pressed && Theme.spatialMotion() ? 0.98 : 1

    Behavior on radius { Anim { motionRole: "shape" } }
    Finish { strength: 0.4; visible: Theme.materialGlass }

    Behavior on color { CAnim {} }
    Behavior on scale { Anim { motionRole: "feedback" } }

    readonly property color fg: active ? (pills ? Theme.onAccentContainer : Theme.onColor(cards ? tint : Theme.accent)) : Theme.text

    // classic: a row
    RowLayout {
        visible: !root.cards
        anchors.fill: parent
        anchors.leftMargin: Theme.sp3
        anchors.rightMargin: 6
        spacing: Theme.sp3

        Rectangle {
            Layout.preferredWidth: root.pills ? Math.round(40 * Theme.scale) : Math.round(22 * Theme.scale)
            Layout.preferredHeight: width
            radius: width / 2
            color: root.pills ? Theme.alpha(root.fg, root.active ? 0.12 : 0.06) : "transparent"
            FIcon {
                anchors.centerIn: parent
                icon: root.icon
                size: Math.round(22 * Theme.scale)
                fill: root.active ? 1 : 0
                color: root.fg
            }
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
                font.pixelSize: Theme.fsMd
                elide: Text.ElideRight
            }
        }

        FIconButton {
            visible: root.hasDetails
            icon: "chevron_right"
            accessibleName: root.title + " · " + I18n.tr("Details")
            size: Math.round(34 * Theme.scale)
            iconColor: root.fg
            onClicked: root.detailsClicked()
            z: 3
        }
    }

    // cards: icon on top
    ColumnLayout {
        visible: root.cards
        anchors.fill: parent
        anchors.leftMargin: Theme.sp4
        anchors.rightMargin: Theme.sp4
        anchors.topMargin: Theme.sp3
        anchors.bottomMargin: Theme.sp3
        spacing: 3

        FIcon {
            icon: root.icon
            size: Math.round(22 * Theme.scale)
            fill: root.active ? 1 : 0
            color: root.active ? root.fg : root.tint
        }
        Item { Layout.fillHeight: true }
        FText {
            Layout.fillWidth: true
            text: root.title
            color: root.fg
            font.weight: Font.Bold
            font.pixelSize: Theme.fsMd
            elide: Text.ElideRight
        }
        FText {
            Layout.fillWidth: true
            visible: text !== ""
            text: root.subtitle
            color: root.active ? Theme.alpha(root.fg, 0.8) : Theme.textDim
            font.pixelSize: Theme.fsSm
            elide: Text.ElideRight
        }
    }
    FIconButton {
        visible: root.cards && root.hasDetails
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 4
        icon: "chevron_right"
            accessibleName: root.title + " · " + I18n.tr("Details")
        size: Math.round(34 * Theme.scale)
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
