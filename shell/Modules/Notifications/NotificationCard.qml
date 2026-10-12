import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.Commons
import qs.Services
import qs.Widgets

// One notification. Swipe sideways to dismiss; hover pauses the timeout.
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

    implicitWidth: 380
    implicitHeight: card.implicitHeight

    Rectangle {
        id: card

        width: parent.width
        implicitHeight: col.implicitHeight + 28
        radius: Theme.rLg
        color: root.popup ? Theme.panelBg : Theme.surfaceHigh
        border.width: root.critical ? 2 : 1
        border.color: root.critical ? Theme.error : Theme.alpha(Theme.border, 0.6)
        opacity: 1 - Math.min(1, Math.abs(x) / width * 1.4)

        Behavior on x {
            enabled: !drag.active
            Anim { easing.bezierCurve: Theme.curves.spring }
        }

        ColumnLayout {
            id: col
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                AppIcon {
                    implicitSize: 16
                    name: root.appIcon || root.appName.toLowerCase()
                    fallback: "dialog-information"
                }
                FText {
                    Layout.fillWidth: true
                    text: root.appName || "Notification"
                    dim: true
                    font.pixelSize: Theme.fsXs
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                FText {
                    text: Notifs.ago(root.time)
                    dim: true
                    font.pixelSize: Theme.fsXs
                }
                FIconButton {
                    icon: "close"
                    size: 22
                    iconSize: 14
                    onClicked: Notifs.dismiss(root.nid)
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                ClippingRectangle {
                    visible: root.image !== ""
                    Layout.preferredWidth: 46
                    Layout.preferredHeight: 46
                    Layout.alignment: Qt.AlignTop
                    radius: Theme.rMd
                    color: Theme.surfaceHighest
                    Image {
                        anchors.fill: parent
                        source: root.image
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    FText {
                        Layout.fillWidth: true
                        text: root.summary
                        font.weight: Font.Bold
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                    FText {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: root.body
                        textFormat: Text.StyledText
                        dim: true
                        font.pixelSize: Theme.fsSm
                        wrapMode: Text.Wrap
                        maximumLineCount: root.popup ? 4 : 6
                        elide: Text.ElideRight
                        onLinkActivated: link => Qt.openUrlExternally(link)
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: root.actions.length > 0
                spacing: 6
                Repeater {
                    model: root.actions
                    FButton {
                        required property var modelData
                        Layout.fillWidth: true
                        text: modelData.text
                        variant: "tonal"
                        implicitHeight: 30
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
