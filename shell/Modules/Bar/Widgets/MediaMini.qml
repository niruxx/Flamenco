import QtQuick
import Quickshell.Widgets
import qs.Commons
import qs.Services
import qs.Widgets

BarChip {
    id: root
    property string screenName
    property int barLevel: 0
    property bool barVisible: Media.active && barLevel < 3
    padding: 6
    highlighted: Panels.current === "calendar" && Panels.dashboardShown === "media"
    onClicked: Panels.openDashboard("media", screenName)
    onMiddleClicked: Media.toggle()
    onRightClicked: Media.next()

    BarFlow {
        // spinning "vinyl" cover
        ClippingRectangle {
            width: Theme.barHeight - 18
            height: width
            radius: width / 2
            color: Theme.surfaceHighest

            Image {
                anchors.fill: parent
                source: Media.art
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize: Qt.size(64, 64)
            }
            FIcon {
                anchors.centerIn: parent
                visible: !Media.art
                icon: "music_note"
                size: 14
            }

            RotationAnimation on rotation {
                running: Media.playing && Theme.speed > 0
                from: 0; to: 360
                duration: 8000
                loops: Animation.Infinite
            }
        }

        FText {
            visible: !Theme.barVertical && root.barLevel < 1
            width: Math.min(implicitWidth, 220)
            text: Media.title + (Media.artist ? "  ·  " + Media.artist : "")
            elide: Text.ElideRight
            font.pixelSize: Theme.fsSm
        }

        FIcon {
            icon: Media.playing ? "pause" : "play_arrow"
            fill: 1
            size: 18
            color: Theme.accent
        }
    }
}
