import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Services.Mpris
import Quickshell.Widgets
import qs.Commons
import qs.Services
import qs.Widgets

ColumnLayout {
    id: root
    readonly property var p: Media.player
    spacing: Theme.sp3

    // empty state
    ColumnLayout {
        visible: !Media.active
        Layout.fillWidth: true
        Layout.topMargin: Theme.sp6
        Layout.bottomMargin: Theme.sp6
        spacing: Theme.sp2
        FIcon { Layout.alignment: Qt.AlignHCenter; icon: "music_off"; size: 56; color: Theme.textDim }
        FText { Layout.alignment: Qt.AlignHCenter; text: "No media playing"; font.pixelSize: Theme.fsLg; font.weight: Font.Bold }
        FText { Layout.alignment: Qt.AlignHCenter; text: "Start something in any MPRIS-capable player"; dim: true }
    }

    // player
    ClippingRectangle {
        visible: Media.active
        Layout.fillWidth: true
        implicitHeight: 220
        radius: Theme.rXl
        color: Theme.surfaceHigh

        Image {
            id: bgArt
            anchors.fill: parent
            source: Media.art
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(256, 256)
            asynchronous: true
            visible: false
        }
        MultiEffect {
            anchors.fill: parent
            source: bgArt
            visible: Media.art !== ""
            blurEnabled: true
            blur: 1
            blurMax: 64
            saturation: 0.25
            opacity: 0.6
        }
        Rectangle {
            anchors.fill: parent
            color: Theme.alpha(Theme.surfaceHigh, 0.55)
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: Theme.sp4
            spacing: Theme.sp4

            ClippingRectangle {
                Layout.preferredWidth: 180
                Layout.preferredHeight: 180
                radius: Theme.rLg
                color: Theme.surfaceHighest
                scale: Media.playing ? 1 : 0.94
                Behavior on scale { Anim { duration: Theme.durLong; easing.bezierCurve: Theme.curves.spring } }
                Image {
                    anchors.fill: parent
                    source: Media.art
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(360, 360)
                    asynchronous: true
                }
                FIcon { anchors.centerIn: parent; visible: !Media.art; icon: "album"; size: 72; color: Theme.textDim }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 2
                FText { Layout.fillWidth: true; text: Media.title; font.pixelSize: Theme.fsXl; font.weight: Font.Bold; wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight }
                FText { Layout.fillWidth: true; text: Media.artist; elide: Text.ElideRight }
                FText { Layout.fillWidth: true; visible: text !== ""; text: root.p?.trackAlbum ?? ""; dim: true; font.pixelSize: Theme.fsSm; elide: Text.ElideRight }
                FText { text: root.p?.identity ?? ""; dim: true; font.pixelSize: Theme.fsXs }
                Item { Layout.fillHeight: true }
            }
        }
    }

    // progress
    ColumnLayout {
        visible: Media.active && Media.length > 0
        Layout.fillWidth: true
        spacing: 4
        FSlider {
            Layout.fillWidth: true
            implicitHeight: 10
            value: Media.length > 0 ? Media.position / Media.length : 0
            onMoved: v => Media.seek(v)
        }
        RowLayout {
            Layout.fillWidth: true
            FText { text: Media.fmt(Media.position); mono: true; dim: true; font.pixelSize: Theme.fsXs }
            Item { Layout.fillWidth: true }
            FText { text: Media.fmt(Media.length); mono: true; dim: true; font.pixelSize: Theme.fsXs }
        }
    }

    // controls
    RowLayout {
        visible: Media.active
        Layout.alignment: Qt.AlignHCenter
        spacing: Theme.sp3
        FIconButton {
            visible: root.p?.shuffleSupported ?? false
            icon: "shuffle"
            active: root.p?.shuffle ?? false
            onClicked: root.p.shuffle = !root.p.shuffle
        }
        FIconButton { icon: "skip_previous"; size: 44; onClicked: Media.previous() }
        FIconButton { icon: Media.playing ? "pause" : "play_arrow"; size: 60; active: true; onClicked: Media.toggle() }
        FIconButton { icon: "skip_next"; size: 44; onClicked: Media.next() }
        FIconButton {
            visible: root.p?.loopSupported ?? false
            icon: root.p?.loopState === MprisLoopState.Track ? "repeat_one" : "repeat"
            active: (root.p?.loopState ?? MprisLoopState.None) !== MprisLoopState.None
            onClicked: root.p.loopState = root.p.loopState === MprisLoopState.None ? MprisLoopState.Playlist : root.p.loopState === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None
        }
    }

    // player picker
    Flow {
        visible: Media.players.length > 1
        Layout.fillWidth: true
        spacing: 6
        Repeater {
            model: Media.players
            FButton {
                required property var modelData
                text: modelData.identity || "Player"
                icon: modelData.isPlaying ? "graphic_eq" : "music_note"
                variant: modelData === Media.player ? "filled" : "tonal"
                implicitHeight: 30
                onClicked: Media.manual = modelData
            }
        }
    }
}
