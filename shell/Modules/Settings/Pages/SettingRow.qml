import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

// Label + description on the left, control on the right.
Item {
    id: root
    property string title
    property string subtitle
    property string icon
    default property alias control: slot.data
    readonly property bool isSettingRow: true
    // a hairline above every row but the first shown in its list (GNOME's boxed list)
    readonly property bool firstInList: {
        const kids = parent ? parent.children : [];
        for (let i = 0; i < kids.length; i++) {
            const k = kids[i];
            if (k === root)
                return true;
            if (k.isSettingRow && k.visible)
                return false;
        }
        return true;
    }
    readonly property bool lastInList: {
        const kids = parent ? parent.children : [];
        for (let i = kids.length - 1; i >= 0; i--) {
            const k = kids[i];
            if (k === root)
                return true;
            if (k.isSettingRow && k.visible)
                return false;
        }
        return true;
    }

    Layout.fillWidth: true
    implicitHeight: Math.max(60, lay.implicitHeight + 24)

    // Settings search: scroll here and flash when this is what was searched for
    readonly property bool found: Panels.settingsFind !== "" && Panels.settingsFind === root.title
    function reveal() {
        let f = root.parent;
        while (f && !(f.contentY !== undefined && f.contentItem !== undefined))
            f = f.parent;
        if (f) {
            const y = root.mapToItem(f.contentItem, 0, 0).y;
            f.contentY = Math.max(0, Math.min(f.contentHeight - f.height, y - f.height / 3));
        }
        flash.restart();
    }
    Component.onCompleted: if (found) revealSoon.restart()
    Connections {
        target: Panels
        function onFindSeqChanged() {
            if (root.found)
                revealSoon.restart();
        }
    }
    // once the page has laid out
    Timer {
        id: revealSoon
        interval: 250
        onTriggered: root.reveal()
    }

    Rectangle {
        id: hl
        anchors.fill: parent
        radius: Theme.rMd
        color: Theme.accent
        opacity: 0
        SequentialAnimation {
            id: flash
            loops: 2
            NumberAnimation { target: hl; property: "opacity"; to: 0.22; duration: 280 }
            NumberAnimation { target: hl; property: "opacity"; to: 0; duration: 420 }
        }
    }

    // its own rounded tile: the list's ends round off, the rows in between stay squarer,
    // and the 2 px between them shows through (the segmented look)
    Rectangle {
        z: -1
        anchors.fill: parent
        topLeftRadius: root.firstInList ? 20 : 6
        topRightRadius: root.firstInList ? 20 : 6
        bottomLeftRadius: root.lastInList ? 20 : 6
        bottomRightRadius: root.lastInList ? 20 : 6
        color: Theme.alpha(Theme.surfaceHigh, Math.min(1, Theme.settingsOp + 0.06))
    }

    // controls too wide to leave the text room (big buttons, high scaling) go under it
    readonly property real iconW: root.icon !== "" ? Theme.iconSize + 14 : 0
    readonly property bool stacked: slot.childrenRect.width > 0 && root.width - 32 - iconW - slot.childrenRect.width - 14 < 240

    ColumnLayout {
        id: lay
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            FIcon {
                visible: root.icon !== ""
                Layout.alignment: root.stacked ? Qt.AlignTop : Qt.AlignVCenter
                icon: root.icon
                color: Theme.textDim
            }
            // the title and description, measured at their real width so wrapped lines
            // make the row taller instead of spilling over the next one
            Item {
                Layout.fillWidth: true
                implicitHeight: texts.implicitHeight
                Column {
                    id: texts
                    width: parent.width
                    spacing: 1
                    FText { width: parent.width; text: root.title; font.weight: Font.Medium; wrapMode: Text.Wrap }
                    FText { width: parent.width; visible: text !== ""; text: root.subtitle; dim: true; font.pixelSize: Theme.fsSm; wrapMode: Text.Wrap }
                }
            }
            Item {
                id: inlineHolder
                visible: !root.stacked
                Layout.preferredWidth: root.stacked ? 0 : slot.childrenRect.width
                Layout.preferredHeight: root.stacked ? 0 : slot.childrenRect.height
            }
        }
        // under the text, lined up with it
        Item {
            id: belowHolder
            visible: root.stacked
            Layout.fillWidth: true
            Layout.leftMargin: root.iconW
            Layout.preferredHeight: root.stacked ? slot.childrenRect.height : 0
        }
    }

    Item {
        id: slot
        parent: root.stacked ? belowHolder : inlineHolder
        width: childrenRect.width
        height: childrenRect.height
    }
}
