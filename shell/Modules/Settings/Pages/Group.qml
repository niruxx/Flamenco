import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

// A titled card holding rows.
ColumnLayout {
    id: root
    property string title
    default property alias rows: card.data

    Layout.fillWidth: true
    spacing: Theme.sp2

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

    FText {
        id: heading
        visible: root.title !== ""
        text: root.title.toUpperCase()
        color: Theme.accent
        font.pixelSize: Theme.fsXs
        font.weight: Font.Bold
        font.letterSpacing: 1.2
        Layout.leftMargin: 4
        Layout.topMargin: Theme.sp2

        Rectangle {
            id: hl
            anchors.fill: parent
            anchors.margins: -4
            radius: Theme.rSm
            color: Theme.accent
            opacity: 0
            z: -1
            SequentialAnimation {
                id: flash
                loops: 2
                NumberAnimation { target: hl; property: "opacity"; to: 0.25; duration: 280 }
                NumberAnimation { target: hl; property: "opacity"; to: 0; duration: 420 }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: card.implicitHeight + 8
        radius: Theme.rLg
        color: Theme.surface

        ColumnLayout {
            id: card
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 4
            spacing: 0
        }
    }
}
