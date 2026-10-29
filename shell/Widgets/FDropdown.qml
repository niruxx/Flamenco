import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC
import qs.Commons

// Dropdown picker. `options` accepts strings or { value, label } objects.
// A search box appears automatically for long lists.
Rectangle {
    id: root

    property var options: []
    property var current
    property string placeholder: I18n.tr("Select…")
    property bool searchable: options.length > 8
    property bool fontPreview: false      // draw each option in its own font (font pickers)

    activeFocusOnTab: true
    Accessible.role: Accessible.ComboBox
    Accessible.name: currentItem ? currentItem.label : placeholder
    Accessible.onPressAction: root.openMenu()
    Keys.onPressed: event => {
        if ([Qt.Key_Space, Qt.Key_Return, Qt.Key_Enter, Qt.Key_Down, Qt.Key_Up].includes(event.key)) {
            if (!event.isAutoRepeat)
                root.openMenu();
            event.accepted = true;
        }
    }
    FocusRing {}

    function openMenu() {
        filter = "";
        place();
        popup.open();
    }

    signal selected(var value)

    readonly property var items: options.map(o => typeof o === "object" ? o : { value: o, label: String(o) })
    readonly property var currentItem: items.find(o => o.value === current) ?? null
    property string filter: ""
    readonly property var filtered: filter === "" ? items : items.filter(o => o.label.toLowerCase().includes(filter.toLowerCase()) || String(o.value).toLowerCase().includes(filter.toLowerCase()))

    implicitWidth: 280
    implicitHeight: Theme.fieldHeight
    radius: Theme.rMd
    color: Theme.surfaceHigh
    border.width: popup.opened ? 2 : 1
    border.color: popup.opened ? Theme.accent : Theme.border

    Behavior on border.color { CAnim {} }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 8
        spacing: 8

        FText {
            Layout.fillWidth: true
            font.family: root.fontPreview && root.current ? String(root.current) : Theme.fontFamily
            text: root.currentItem ? root.currentItem.label : (root.current ? String(root.current) : root.placeholder)
            dim: !root.currentItem && !root.current
            elide: Text.ElideRight
        }
        FIcon {
            icon: "expand_more"
            color: popup.opened ? Theme.accent : Theme.textDim
            rotation: popup.opened ? 180 : 0
            Behavior on rotation { Anim { easing.bezierCurve: Theme.curves.spring } }
        }
    }

    // room for the list: below the field, or above it when there's more space there,
    // so it never runs past the window's edge (where it couldn't be scrolled to)
    property real room: 360
    property bool up: false

    function place() {
        const want = Math.min(360 * Theme.scale, root.items.length * Theme.controlHeight + (root.searchable ? Theme.fieldHeight + Theme.sp2 : 0) + Theme.sp3);
        const winH = root.Window.height > 0 ? root.Window.height : 800;
        const top = root.mapToItem(null, 0, 0).y;
        const below = winH - top - root.height - 12;
        const above = top - 12;
        up = below < want && above > below;
        room = Math.max(0, Math.min(360 * Theme.scale, up ? above - 4 : below - 4));
    }

    StateLayer {
        onClicked: root.openMenu()
    }

    QQC.Popup {
        id: popup

        y: root.up ? -height - 4 : root.height + 4
        width: Math.max(root.width, 240)
        height: Math.min(root.room, list.contentHeight + (search.visible ? search.height + Theme.sp2 : 0) + (root.filtered.length ? 0 : emptyState.implicitHeight) + Theme.sp3)
        margins: 8                       // and Qt keeps it inside the window as a last resort
        padding: 6
        modal: false
        focus: true
        closePolicy: QQC.Popup.CloseOnEscape | QQC.Popup.CloseOnPressOutside

        onOpened: {
            list.currentIndex = Math.max(0, root.filtered.findIndex(o => o.value === root.current));
            list.positionViewAtIndex(list.currentIndex, ListView.Center);
            if (root.searchable)
                search.focusInput();
            else
                list.forceActiveFocus();
        }

        enter: Transition {
            ParallelAnimation {
                Anim { property: "opacity"; from: 0; to: 1; motionRole: "fade"; area: "panels" }
                Anim { property: "scale"; from: Theme.spatialMotion("panels") ? 0.96 : 1; to: 1; motionRole: "enter"; area: "panels" }
            }
        }
        exit: Transition {
            Anim { property: "opacity"; to: 0; motionRole: "exit"; area: "panels" }
        }

        background: Rectangle {
            radius: Theme.rMd
            color: Theme.surfaceHigh
            border.width: 1
            border.color: Theme.border
        }

        contentItem: ColumnLayout {
            spacing: 8

            FTextField {
                id: search
                visible: root.searchable
                Layout.fillWidth: true
                implicitHeight: Theme.fieldHeight
                icon: "search"
                placeholder: I18n.tr("Filter")
                onEdited: t => root.filter = t
                onKeyPressed: event => {
                    if (event.key === Qt.Key_Down || event.key === Qt.Key_Up) {
                        list.forceActiveFocus();
                        event.accepted = true;
                    }
                }
                onAccepted: if (root.filtered.length > 0) {
                    root.selected(root.filtered[Math.max(0, Math.min(root.filtered.length - 1, list.currentIndex))].value);
                    popup.close();
                }
            }

            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: root.filtered
                keyNavigationEnabled: true
                keyNavigationWraps: true
                onModelChanged: currentIndex = count ? 0 : -1
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                        if (!event.isAutoRepeat && currentIndex >= 0 && currentIndex < root.filtered.length) {
                            root.selected(root.filtered[currentIndex].value);
                            popup.close();
                        }
                        event.accepted = true;
                    }
                }
                boundsBehavior: Flickable.OvershootBounds

                SmoothWheel {
                    view: list
                }

                delegate: Rectangle {
                    id: opt
                    required property var modelData
                    required property int index
                    Accessible.role: Accessible.ListItem
                    Accessible.name: modelData.label
                    Accessible.onPressAction: {
                        root.selected(modelData.value);
                        popup.close();
                    }
                    readonly property bool sel: modelData.value === root.current
                    width: list.width
                    height: Theme.controlHeight
                    radius: Theme.rSm
                    color: sel || (list.activeFocus && list.currentIndex === index) ? Theme.accentContainer : "transparent"

                    FocusRing { visible: list.activeFocus && list.currentIndex === opt.index }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8
                        FText {
                            Layout.fillWidth: true
                            font.family: root.fontPreview ? String(opt.modelData.value) : Theme.fontFamily
                            text: opt.modelData.label
                            color: opt.sel || (list.activeFocus && list.currentIndex === opt.index) ? Theme.onAccentContainer : Theme.text
                            font.weight: opt.sel ? Font.DemiBold : Font.Normal
                            elide: Text.ElideRight
                        }
                        FText {
                            visible: opt.modelData.label !== String(opt.modelData.value) && opt.modelData.value !== ""
                            Layout.maximumWidth: list.width * 0.3
                            elide: Text.ElideRight
                            text: opt.modelData.value
                            dim: true
                            mono: true
                            font.pixelSize: Theme.fsXs
                        }
                        FIcon {
                            visible: opt.sel
                            icon: "check"
                            size: 18
                            color: Theme.onAccentContainer
                        }
                    }

                    StateLayer {
                        onClicked: {
                            root.selected(opt.modelData.value);
                            popup.close();
                        }
                    }
                }
            }

            FText {
                id: emptyState
                visible: root.filtered.length === 0
                Layout.alignment: Qt.AlignHCenter
                text: I18n.tr("No matches")
                dim: true
            }
        }
    }
}
