import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import qs.Commons
import qs.Services
import qs.Widgets

// Album-art backed media card with a blurred art backdrop.
ClippingRectangle {
    id: root
    implicitHeight: Math.max(170, info.implicitHeight + Theme.sp3 * 2)
    radius: Theme.rLg
    color: Theme.surfaceHigh

    Image {
        id: bgArt
        anchors.fill: parent
        source: Media.art
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize: Qt.size(256, 256)
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: bgArt
        visible: Media.art !== ""
        blurEnabled: true
        blur: 1
        blurMax: 48
        saturation: 0.2
        opacity: 0.55
    }
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Theme.alpha(Theme.surfaceHigh, 0.4) }
            GradientStop { position: 1; color: Theme.alpha(Theme.surfaceHigh, 0.9) }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: Theme.sp3
        spacing: Theme.sp3

        ClippingRectangle {
            Layout.preferredWidth: 120
            Layout.preferredHeight: 120
            radius: Theme.rMd
            color: Theme.surfaceHighest
            scale: Media.playing ? 1 : 0.92
            Behavior on scale { Anim { duration: Theme.durLong; easing.bezierCurve: Theme.curves.spring } }

            Image {
                anchors.fill: parent
                source: Media.art
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize: Qt.size(256, 256)
            }
            FIcon {
                anchors.centerIn: parent
                visible: !Media.art
                icon: "music_note"
                size: 48
                color: Theme.textDim
            }
        }

        ColumnLayout {
            id: info
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 4

            FText {
                Layout.fillWidth: true
                text: Media.title
                font.pixelSize: Theme.fsLg
                font.weight: Font.Bold
                elide: Text.ElideRight
            }
            FText {
                Layout.fillWidth: true
                text: Media.artist
                dim: true
                elide: Text.ElideRight
            }
            Item { Layout.fillHeight: true; Layout.minimumHeight: Theme.sp2 }

            // progress: drag or click to seek
            FSeekBar {
                Layout.fillWidth: true
                visible: Media.length > 0
                position: Media.position
                length: Media.length
                seekable: Media.player?.canSeek ?? false
                onSeek: f => Media.seek(f)
            }
            RowLayout {
                Layout.fillWidth: true
                visible: Media.length > 0
                FText { text: Media.fmt(Media.position); dim: true; font.pixelSize: Theme.fsXs; mono: true }
                Item { Layout.fillWidth: true }
                FText { text: Media.fmt(Media.length); dim: true; font.pixelSize: Theme.fsXs; mono: true }
            }

            // controls, with breathing room below the seek bar
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Theme.sp2
                Item { Layout.fillWidth: true }
                FIconButton { icon: "skip_previous"; size: 32; onClicked: Media.previous() }
                FIconButton {
                    icon: Media.playing ? "pause" : "play_arrow"
                    size: 40
                    active: true
                    onClicked: Media.toggle()
                }
                FIconButton { icon: "skip_next"; size: 32; onClicked: Media.next() }
                Item { Layout.fillWidth: true }
                FIconButton {
                    visible: Media.players.length > 1
                    icon: "swap_horiz"
                    size: 28
                    onClicked: Media.cycle()
                }
            }
        }
    }
}
