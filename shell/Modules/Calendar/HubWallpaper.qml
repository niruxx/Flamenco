import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.Commons
import qs.Services
import qs.Widgets

// The Hub's Wallpaper page, over the current wallpaper blurred: a big preview of
// the one you're on (or hovering) with its colors and what you can do, and every
// wallpaper in a grid beside it. Click one to put it on.
ClippingRectangle {
    id: root

    property string screenName: ""
    property real fillHeight: 600
    signal openSettings(string page)
    implicitHeight: Math.max(420, fillHeight)
    radius: Theme.rXl
    color: Theme.surfaceHigh

    readonly property string current: Wallpapers.forScreen(screenName)
    property string hovered: ""
    readonly property string shown: hovered || current

    // the wallpaper, blurred, behind the page
    Image {
        id: bg
        anchors.fill: parent
        source: Paths.toUrl(root.current)
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(480, 300)
        asynchronous: true
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: bg
        blurEnabled: true
        blur: 1
        blurMax: 64
        brightness: -0.35
        saturation: 0.1
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 24

        // ── the one you're on (or hovering) ──
        ColumnLayout {
            Layout.preferredWidth: parent.width * 0.42
            Layout.maximumWidth: parent.width * 0.42
            Layout.fillHeight: true
            spacing: 12

            // the preview takes what's left after the rest, keeping 16:9
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: 100
                ClippingRectangle {
                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height * 16 / 9)
                    height: width * 9 / 16
                    radius: Theme.rXl
                    color: Theme.surface
                    border.width: 2
                    border.color: Theme.alpha(Theme.accent, 0.7)
                    Image {
                        anchors.fill: parent
                        source: Paths.toUrl(root.shown)
                        fillMode: Image.PreserveAspectCrop
                        sourceSize: Qt.size(960, 540)
                        asynchronous: true
                    }
                    Rectangle {
                        visible: root.shown === root.current && root.current !== ""
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 12
                        width: cur.implicitWidth + 20
                        height: 24
                        radius: 12
                        color: Theme.accent3
                        FText { id: cur; anchors.centerIn: parent; text: "current"; font.pixelSize: Theme.fsXs; font.weight: Font.Bold; color: Theme.onAccent }
                    }
                }
            }
            FText {
                Layout.fillWidth: true
                text: Paths.fileName(root.shown).replace(/\.[^.]+$/, "") || "No wallpaper"
                color: "#ffffff"
                font.pixelSize: Theme.fsLg
                font.weight: Font.Bold
                elide: Text.ElideMiddle
            }
            // its colors (click one to copy it)
            Row {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: quant.colors.slice(0, 8)
                    Rectangle {
                        required property color modelData
                        width: 30
                        height: 30
                        radius: 9
                        color: modelData
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.3)
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Quickshell.execDetached(["wl-copy", String(parent.modelData).slice(0, 7)])
                        }
                    }
                }
            }
            FText {
                Layout.fillWidth: true
                text: Wallpapers.files.length + " wallpapers in " + Paths.fileName(Wallpapers.dir) + (Settings.data.wallpaper.perScreen ? " · this screen only" : "")
                color: Qt.rgba(1, 1, 1, 0.7)
                font.pixelSize: Theme.fsSm
                elide: Text.ElideRight
            }
            // what you can do, in an even 2 × 2
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 8
                columnSpacing: 8
                FButton { Layout.fillWidth: true; text: "Shuffle"; icon: "shuffle"; onClicked: Wallpapers.random(root.screenName) }
                FButton { Layout.fillWidth: true; text: "Switcher"; icon: "view_carousel"; variant: "tonal"; onClicked: Panels.open("wallpaper", root.screenName) }
                FButton { Layout.fillWidth: true; text: "Rescan"; icon: "refresh"; variant: "tonal"; onClicked: Wallpapers.rescan() }
                FButton { Layout.fillWidth: true; text: "Settings"; icon: "tune"; variant: "tonal"; onClicked: root.openSettings("wallpaper") }
            }
        }

        // ── every wallpaper ──
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Theme.rXl
            color: Theme.alpha(Theme.shadow, 0.25)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.1)

            GridView {
                id: grid
                anchors.fill: parent
                anchors.margins: 12
                clip: true
                readonly property int cols: Math.max(2, Math.floor(width / 210))
                cellWidth: width / cols
                cellHeight: cellWidth * 0.62
                model: Wallpapers.files
                boundsBehavior: Flickable.StopAtBounds

                SmoothWheel {
                    view: grid
                }

                delegate: Item {
                    id: cell
                    required property string modelData
                    readonly property bool on: modelData === root.current
                    width: grid.cellWidth
                    height: grid.cellHeight

                    ClippingRectangle {
                        anchors.fill: parent
                        anchors.margins: 6
                        radius: Theme.rLg
                        color: Theme.surface
                        border.width: cell.on ? 3 : 0
                        border.color: Theme.accent
                        scale: area.containsMouse ? 1.04 : 1
                        Behavior on scale { Anim { duration: Theme.durShort } }
                        Image {
                            anchors.fill: parent
                            source: Paths.toUrl(cell.modelData)
                            fillMode: Image.PreserveAspectCrop
                            sourceSize: Qt.size(320, 200)
                            asynchronous: true
                            opacity: status === Image.Ready ? 1 : 0
                            Behavior on opacity { Anim {} }
                        }
                    }
                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.hovered = cell.modelData
                        onExited: if (root.hovered === cell.modelData) root.hovered = ""
                        onClicked: Wallpapers.set(cell.modelData, root.screenName)
                    }
                }

                FText {
                    anchors.centerIn: parent
                    visible: grid.count === 0
                    horizontalAlignment: Text.AlignHCenter
                    text: Wallpapers.scanning ? "Scanning…" : Wallpapers.status === "missing" ? "Folder not found:\n" + Wallpapers.dir : "No images in " + Wallpapers.dir
                    color: "#ffffff"
                }
            }
        }
    }

    // the colors follow the preview once the pointer settles (not every thumbnail it crosses)
    property string settled: ""
    onShownChanged: settle.restart()
    Component.onCompleted: settled = shown
    Timer {
        id: settle
        interval: 350
        onTriggered: root.settled = root.shown
    }
    ColorQuantizer {
        id: quant
        source: root.settled ? Paths.toUrl(root.settled) : ""
        depth: 3
        rescaleSize: 64
    }
}
