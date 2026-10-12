import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.Commons
import qs.Widgets

// Themed menu for a tray item, read over DBusMenu via QsMenuOpener.
// Submenus open in place with a back row; clicking outside closes it.
PopupWindow {
    id: root

    required property var window
    property var trayItem: null
    property var stack: []                    // submenu entries, innermost last
    readonly property var menuHandle: stack.length > 0 ? stack[stack.length - 1] : trayItem?.menu ?? null
    property rect at: Qt.rect(0, 0, 1, 1)

    function open(item, rect) {
        trayItem = item;
        stack = [];
        at = rect;
        visible = true;
        openAnim.restart();
    }

    function close() {
        visible = false;
        trayItem = null;
        stack = [];
    }

    readonly property int gap: 8
    anchor.window: window
    anchor.rect.x: Theme.barPos === "right" ? at.x - gap : Theme.barPos === "left" ? at.x + at.width + gap : at.x + at.width / 2
    anchor.rect.y: Theme.barPos === "bottom" ? at.y - gap : Theme.barVertical ? at.y : at.y + at.height + gap
    anchor.rect.width: 1
    anchor.rect.height: 1
    anchor.edges: Theme.barPos === "bottom" ? Edges.Top : Theme.barPos === "left" ? Edges.Right : Theme.barPos === "right" ? Edges.Left : Edges.Bottom
    anchor.gravity: Theme.barPos === "bottom" ? Edges.Top : Theme.barPos === "left" ? Edges.Right : Theme.barPos === "right" ? Edges.Left : Edges.Bottom
    grabFocus: true
    color: "transparent"
    visible: false
    onVisibleChanged: if (!visible) {
        trayItem = null;
        stack = [];
    }

    implicitWidth: Math.max(200, Math.min(360, list.implicitWidth + 12))
    implicitHeight: list.implicitHeight + 12

    QsMenuOpener {
        id: opener
        menu: root.menuHandle
    }

    Rectangle {
        id: body
        anchors.fill: parent
        radius: Theme.rLg
        color: Theme.panelBg
        border.width: 1
        border.color: Theme.alpha(Theme.border, 0.7)

        property real p: 1
        Anim {
            id: openAnim
            target: body
            property: "p"
            from: 0
            to: 1
            duration: Theme.durMed
            easing.bezierCurve: Theme.curves.emphasizedDecel
        }
        opacity: p
        scale: 0.94 + 0.06 * p

        ColumnLayout {
            id: list
            anchors.fill: parent
            anchors.margins: 6
            spacing: 0

            // back row inside submenus
            MenuRow {
                visible: root.stack.length > 0
                label: root.stack.length > 0 ? root.stack[root.stack.length - 1].text : ""
                leadIcon: "arrow_back"
                bold: true
                onActivated: root.stack = root.stack.slice(0, -1)
            }

            Repeater {
                model: opener.children

                delegate: Item {
                    id: row
                    required property QsMenuEntry modelData
                    Layout.fillWidth: true
                    implicitWidth: modelData.isSeparator ? 0 : entry.implicitWidth
                    implicitHeight: modelData.isSeparator ? 9 : entry.implicitHeight

                    Rectangle {
                        visible: row.modelData.isSeparator
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 1
                        color: Theme.border
                        opacity: 0.6
                    }

                    MenuRow {
                        id: entry
                        visible: !row.modelData.isSeparator
                        width: parent.width
                        label: row.modelData.text
                        image: row.modelData.icon
                        enabled: row.modelData.enabled
                        check: row.modelData.buttonType === QsMenuButtonType.CheckBox ? (row.modelData.checkState === Qt.Checked ? "check_box" : "check_box_outline_blank") : row.modelData.buttonType === QsMenuButtonType.RadioButton ? (row.modelData.checkState === Qt.Checked ? "radio_button_checked" : "radio_button_unchecked") : ""
                        submenu: row.modelData.hasChildren
                        onActivated: {
                            if (row.modelData.hasChildren) {
                                root.stack = root.stack.concat([row.modelData]);
                            } else {
                                row.modelData.triggered();
                                root.close();
                            }
                        }
                    }
                }
            }
        }
    }

    component MenuRow: Rectangle {
        id: mr
        property string label
        property string image: ""
        property string leadIcon: ""
        property string check: ""
        property bool submenu: false
        property bool bold: false
        signal activated

        Layout.fillWidth: true
        implicitWidth: rowLay.implicitWidth + 20
        implicitHeight: 32
        radius: Theme.rSm
        color: "transparent"
        opacity: enabled ? 1 : 0.45

        RowLayout {
            id: rowLay
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 10

            FIcon {
                visible: mr.check !== "" || mr.leadIcon !== ""
                icon: mr.check || mr.leadIcon
                size: 18
                fill: mr.check.includes("checked") || mr.check === "check_box" ? 1 : 0
                color: mr.check === "check_box" || mr.check === "radio_button_checked" ? Theme.accent : Theme.text
            }
            IconImage {
                visible: mr.image !== "" && mr.check === ""
                implicitSize: 16
                source: mr.image
            }
            FText {
                Layout.fillWidth: true
                text: mr.label.replace(/_(?!_)/g, "")   // strip mnemonic underscores
                font.weight: mr.bold ? Font.DemiBold : Font.Normal
                elide: Text.ElideRight
            }
            FIcon {
                visible: mr.submenu
                icon: "chevron_right"
                size: 18
                color: Theme.textDim
            }
        }

        StateLayer {
            disabled: !mr.enabled
            onClicked: mr.activated()
        }
    }
}
