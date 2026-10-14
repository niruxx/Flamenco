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

    RowLayout {
        id: lay
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 14

        FIcon {
            visible: root.icon !== ""
            icon: root.icon
            color: Theme.textDim
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            FText { Layout.fillWidth: true; text: root.title; font.weight: Font.Medium; wrapMode: Text.Wrap }
            FText { Layout.fillWidth: true; visible: text !== ""; text: root.subtitle; dim: true; font.pixelSize: Theme.fsSm; wrapMode: Text.Wrap }
        }
        Item {
            id: slot
            Layout.preferredWidth: childrenRect.width
            Layout.preferredHeight: childrenRect.height
        }
    }
}
