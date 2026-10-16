import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.Commons
import qs.Services
import qs.Widgets

// One notification. Swipe sideways to dismiss; hover pauses the timeout.
// Laid out with plain Columns and explicit widths so wrapped text always gets
// its full height (Layouts can under-measure wrapped Text and crop it).
Item {
    id: root

    required property int nid
    required property string appName
    required property string appIcon
    required property string image
    required property string summary
    required property string body
    required property int urgency
    required property real time
    required property int timeout
    required property string actionsJson
    property bool popup: false

    readonly property var actions: JSON.parse(actionsJson || "[]")
    readonly property bool critical: urgency === 2
    readonly property int life: timeout > 0 ? timeout : Settings.data.notifications.timeout * 1000
    readonly property int pad: 14

    implicitWidth: 380
    implicitHeight: card.height

    Rectangle {
        id: card

        width: parent.width
        height: content.height + root.pad * 2
        radius: Theme.rXl
        // in the center: soft cards like the dashboard's; urgent ones tinted
        color: root.popup ? Theme.panelBg : root.critical ? Theme.alpha(Theme.error, 0.1) : Theme.alpha(Theme.text, 0.05)
        border.width: root.critical ? 2 : 1
        border.color: root.critical ? Theme.error : root.popup ? Theme.alpha(Theme.border, 0.6) : Theme.alpha(Theme.text, 0.08)
        opacity: 1 - Math.min(1, Math.abs(x) / width * 1.4)

        Behavior on x {
            enabled: !drag.active
            Anim { easing.bezierCurve: Theme.curves.spring }
        }

        Column {
            id: content
            x: root.pad
            y: root.pad
            width: card.width - root.pad * 2
            spacing: 8

            // header: icon · app name · time · close
            Item {
                width: parent.width
                height: 30

                // the app's icon in a tinted bubble
                Rectangle {
                    id: appIco
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: 30
                    height: 30
                    radius: 15
                    color: Theme.alpha(root.critical ? Theme.error : Theme.accent, 0.16)
                    AppIcon {
                        anchors.centerIn: parent
                        implicitSize: 18
                        name: root.appIcon || root.appName.toLowerCase()
                        fallback: "dialog-information"
                    }
                }
                FText {
                    anchors.left: appIco.right
                    anchors.leftMargin: 8
                    anchors.right: when.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.appName || "Notification"
                    color: root.critical ? Theme.error : Theme.accent
                    font.pixelSize: Theme.fsXs
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }
                FText {
                    id: when
                    anchors.right: closeBtn.left
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    text: Notifs.ago(root.time)
                    dim: true
                    font.pixelSize: Theme.fsXs
                }
                FIconButton {
                    id: closeBtn
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "close"
                    size: 24
                    iconSize: 14
                    onClicked: Notifs.dismiss(root.nid)
                }
            }

            // image + text
            Item {
                width: parent.width
                height: Math.max(img.visible ? img.height : 0, texts.height)

                ClippingRectangle {
                    id: img
                    visible: root.image !== ""
                    width: 48
                    height: 48
                    radius: Theme.rMd
                    color: Theme.surfaceHighest
                    Image {
                        anchors.fill: parent
                        source: root.image
                        sourceSize: Qt.size(96, 96)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }

                Column {
                    id: texts
                    x: img.visible ? img.width + 12 : 0
                    width: parent.width - x
                    spacing: 3

                    FText {
                        width: parent.width
                        visible: text !== ""
                        text: root.summary
                        font.weight: Font.Bold
                        verticalAlignment: Text.AlignTop
                        wrapMode: Text.Wrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                    }
                    FText {
                        width: parent.width
                        visible: text !== ""
                        text: root.body
                        textFormat: Text.StyledText
                        dim: true
                        font.pixelSize: Theme.fsSm
                        verticalAlignment: Text.AlignTop
                        wrapMode: Text.Wrap
                        maximumLineCount: root.popup ? 4 : 8
                        elide: Text.ElideRight
                        lineHeight: 1.1
                        onLinkActivated: link => Qt.openUrlExternally(link)
                    }
                }
            }

            // actions share the width evenly
            Row {
                visible: root.actions.length > 0
                width: parent.width
                spacing: 6
                Repeater {
                    model: root.actions
                    FButton {
                        required property var modelData
                        width: (parent.width - parent.spacing * (root.actions.length - 1)) / Math.max(1, root.actions.length)
                        implicitHeight: 30
                        text: modelData.text
                        variant: "tonal"
                        onClicked: Notifs.invoke(root.nid, modelData.id)
                    }
                }
            }
        }

        // timeout bar
        Rectangle {
            visible: root.popup && !root.critical
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.bottomMargin: 4
            anchors.leftMargin: Theme.rLg / 2
            height: 3
            radius: 2
            width: (parent.width - Theme.rLg) * lifeAnim.progress
            color: Theme.accent
            opacity: 0.7
        }

        QtObject {
            id: lifeAnim
            property real progress: 1
        }

        NumberAnimation {
            target: lifeAnim
            property: "progress"
            running: root.popup && !root.critical
            paused: running && (hover.hovered || drag.active)
            from: 1
            to: 0
            duration: root.life
            onFinished: Notifs.hidePopup(root.nid)
        }

        HoverHandler { id: hover }

        DragHandler {
            id: drag
            target: card
            yAxis.enabled: false
            onActiveChanged: if (!active) {
                if (Math.abs(card.x) > card.width * 0.35) {
                    card.x = card.x > 0 ? card.width * 1.3 : -card.width * 1.3;
                    Notifs.dismiss(root.nid);
                } else {
                    card.x = 0;
                }
            }
        }
    }
}
