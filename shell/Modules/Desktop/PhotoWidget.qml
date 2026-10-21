import QtQuick
import Quickshell.Widgets
import qs.Commons
import qs.Services
import qs.Widgets

// A photo frame: the picture you chose (hover it while arranging widgets →
// Choose picture), or a slideshow of your wallpapers that changes every few
// minutes, cross-fading. Click it for the next one.
Item {
    id: root
    property real k: 1
    property var spec
    property bool editing: false
    readonly property string chosen: spec?.path ?? ""
    readonly property var pool: Wallpapers.files.filter(f => !Paths.isVideo(f) || Wallpapers.still(f) !== "")
    property int at: Math.floor(Math.random() * 1000)
    readonly property string shown: chosen ? Paths.expand(chosen) : pool.length ? Wallpapers.still(pool[at % pool.length]) : ""
    implicitWidth: Math.round(300 * k)
    implicitHeight: Math.round(200 * k)

    // two pictures, cross-fading when it changes
    property bool useA: true
    onShownChanged: {
        useA = !useA;
        (useA ? a : b).path = Paths.toUrl(shown);
    }
    Component.onCompleted: a.path = Paths.toUrl(shown)

    ClippingRectangle {
        anchors.fill: parent
        radius: Theme.rLg
        color: Theme.alpha(Theme.text, 0.06)
        SafeImage {
            id: a
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(root.width * 2, root.height * 2)
            opacity: root.useA && status === Image.Ready ? 1 : 0
            Behavior on opacity { Anim { duration: 900 } }
        }
        SafeImage {
            id: b
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(root.width * 2, root.height * 2)
            opacity: !root.useA && status === Image.Ready ? 1 : 0
            Behavior on opacity { Anim { duration: 900 } }
        }
        FIcon {
            anchors.centerIn: parent
            visible: root.shown === ""
            icon: "photo"
            size: Math.round(40 * root.k)
            color: Theme.textDim
        }
    }
    Timer {
        running: !root.chosen && root.pool.length > 1
        interval: 5 * 60000
        repeat: true
        onTriggered: root.at++
    }
    MouseArea {
        anchors.fill: parent
        enabled: !root.editing && !root.chosen
        cursorShape: Qt.PointingHandCursor
        onClicked: root.at++
    }
}
