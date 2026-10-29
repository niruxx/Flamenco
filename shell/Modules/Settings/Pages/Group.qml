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
        // GNOME / macOS: a quiet title over a rounded list
        text: root.title
        color: Theme.accent
        font.pixelSize: Theme.fsMd
        font.weight: Font.Medium
        Layout.leftMargin: 8
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
                NumberAnimation { target: hl; property: "opacity"; to: 0.25; duration: Theme.motionDuration("fade", "panels") }
                NumberAnimation { target: hl; property: "opacity"; to: 0; duration: Theme.motionDuration("enter", "panels") }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        // the rows draw themselves (rounded at the ends of the list, 2 px apart);
        // anything else in a group sits on this faint backing
        implicitHeight: card.implicitHeight
        radius: 20
        color: Theme.alpha(Theme.text, 0.02)

        ColumnLayout {
            id: card
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: 2
        }
    }
}
