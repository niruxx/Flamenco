import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Widgets
import qs.Commons
import qs.Services
import qs.Widgets

// The Hub's Media page: the cover on a spinning record over the blurred cover,
// the track large, a wavy progress line, big controls, and the visualizer
// across the bottom.
// (A plain Rectangle with only the background clipped: a ClippingRectangle around
// the whole page could fail to draw when the page was built in the background.)
Rectangle {
    id: root

    property bool live: false                  // showing right now (the visualizer and the record run only then)
    property real fillHeight: 600
    implicitHeight: Math.max(420, fillHeight)
    radius: Theme.rXl
    color: Theme.alpha(Theme.text, 0.035)

    readonly property real frac: Media.length > 0 ? Math.max(0, Math.min(1, Media.position / Media.length)) : 0
    readonly property color ink: Media.art !== "" ? "#ffffff" : Theme.text

    onLiveChanged: live ? Cava.users++ : Cava.users = Math.max(0, Cava.users - 1)
    Component.onDestruction: if (live) Cava.users = Math.max(0, Cava.users - 1)

    ClippingRectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        // ── the blurred cover behind it all ──
        Image {
            id: bg
            anchors.fill: parent
            source: Media.art
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(480, 320)
            asynchronous: true
            visible: false
        }
        MultiEffect {
            anchors.fill: parent
            visible: Media.art !== ""
            source: bg
            blurEnabled: true
            blur: 1
            blurMax: 64
            brightness: -0.3
            saturation: 0.25
        }
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 1; color: Theme.alpha(Theme.shadow, Media.art !== "" ? 0.55 : 0.1) }
            }
        }
    }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 36
        anchors.topMargin: 44
        spacing: 44
        visible: Media.active

        // ── the record ──
        Item {
            Layout.preferredWidth: 340
            Layout.preferredHeight: 340
            Layout.alignment: Qt.AlignTop

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                border.width: 2
                border.color: Qt.rgba(1, 1, 1, 0.25)
            }
            Item {
                id: disc
                anchors.fill: parent
                anchors.margins: 16

                RotationAnimator on rotation {
                    from: 0
                    to: 360
                    duration: 9000
                    loops: Animation.Infinite
                    running: root.live
                    paused: running && !Media.playing
                }

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "#141414"
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.15)
                }
                // the grooves
                Repeater {
                    model: 9
                    Rectangle {
                        required property int index
                        anchors.centerIn: parent
                        width: disc.width * (0.94 - index * 0.055)
                        height: width
                        radius: width / 2
                        color: "transparent"
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, index % 3 === 0 ? 0.08 : 0.04)
                    }
                }
                // the label: the cover
                ClippingRectangle {
                    anchors.centerIn: parent
                    width: disc.width * 0.48
                    height: width
                    radius: width / 2
                    color: Theme.accent
                    Image {
                        anchors.fill: parent
                        source: Media.art
                        sourceSize: Qt.size(360, 360)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                    FIcon {
                        anchors.centerIn: parent
                        visible: Media.art === ""
                        icon: "music_note"
                        size: 48
                        color: Theme.onAccent
                    }
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: 14
                    height: 14
                    radius: 7
                    color: "#141414"
                    border.width: 2
                    border.color: Qt.rgba(1, 1, 1, 0.6)
                }
            }
        }

        // ── the track ──
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: 16
            spacing: 6

            RowLayout {
                spacing: 6
                FIcon { icon: "graphic_eq"; size: 16; color: Theme.accent3; fill: 1 }
                FText {
                    text: (Media.player?.identity ?? "").toUpperCase()
                    color: Theme.accent3
                    font.pixelSize: Theme.fsSm
                    font.weight: Font.Black
                    font.letterSpacing: 2
                }
            }
            FText {
                Layout.fillWidth: true
                text: Media.title
                color: root.ink
                font.pixelSize: 40
                font.weight: Font.Bold
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
            FText {
                Layout.fillWidth: true
                text: Media.artist
                color: Theme.accent
                font.pixelSize: Theme.fsXl
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            FText {
                Layout.fillWidth: true
                visible: text !== ""
                text: Media.player?.trackAlbum ?? ""
                color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.7)
                elide: Text.ElideRight
            }

            // the wavy progress line: a wave up to where it's at, flat after
            Canvas {
                id: wave
                Layout.fillWidth: true
                Layout.topMargin: 22
                implicitHeight: 26
                visible: Media.length > 0
                property real phase: 0
                property real shown: seek.pressed ? seek.at : root.frac
                onShownChanged: requestPaint()
                onPhaseChanged: requestPaint()
                onWidthChanged: requestPaint()
                NumberAnimation on phase {
                    from: 0
                    to: Math.PI * 2
                    duration: 1600
                    loops: Animation.Infinite
                    running: root.live && Media.playing
                }
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    const mid = height / 2, x = width * shown;
                    ctx.lineWidth = 3;
                    ctx.lineCap = "round";
                    ctx.strokeStyle = Theme.accent;
                    ctx.beginPath();
                    for (let i = 0; i <= x; i += 2)
                        i === 0 ? ctx.moveTo(i, mid + Math.sin(i / 7 - phase) * 5) : ctx.lineTo(i, mid + Math.sin(i / 7 - phase) * 5);
                    ctx.stroke();
                    ctx.strokeStyle = Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.25);
                    ctx.beginPath();
                    ctx.moveTo(x + 4, mid);
                    ctx.lineTo(width, mid);
                    ctx.stroke();
                    ctx.fillStyle = Theme.accent;
                    ctx.fillRect(x - 2, mid - 9, 4, 18);
                }
                MouseArea {
                    id: seek
                    property real at: 0
                    anchors.fill: parent
                    enabled: Media.player?.canSeek ?? false
                    cursorShape: Qt.PointingHandCursor
                    onPressed: mouse => at = Math.max(0, Math.min(1, mouse.x / width))
                    onPositionChanged: mouse => at = Math.max(0, Math.min(1, mouse.x / width))
                    onReleased: Media.seek(at)
                }
            }
            RowLayout {
                Layout.fillWidth: true
                visible: Media.length > 0
                FText { text: Media.fmt(Media.position); mono: true; font.pixelSize: Theme.fsXs; color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.75) }
                Item { Layout.fillWidth: true }
                FText { text: Media.fmt(Media.length); mono: true; font.pixelSize: Theme.fsXs; color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.75) }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 6
                spacing: 18
                FIconButton { icon: "skip_previous"; size: 46; iconColor: root.ink; onClicked: Media.previous() }
                // the big play button
                Rectangle {
                    implicitWidth: 78
                    implicitHeight: 78
                    radius: Theme.rXl
                    color: Theme.accent
                    scale: playArea.pressed ? 0.93 : 1
                    Behavior on scale { Anim { duration: Theme.durShort } }
                    FIcon {
                        anchors.centerIn: parent
                        icon: Media.playing ? "pause" : "play_arrow"
                        size: 38
                        fill: 1
                        color: Theme.onAccent
                    }
                    MouseArea {
                        id: playArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Media.toggle()
                    }
                }
                FIconButton { icon: "skip_next"; size: 46; iconColor: root.ink; onClicked: Media.next() }
            }

            // bring the player's window up
            FButton {
                Layout.topMargin: 16
                visible: Media.player?.canRaise ?? false
                text: Media.player?.identity ?? "Player"
                icon: "play_arrow"
                onClicked: {
                    Media.player.raise();
                    Panels.close();
                }
            }
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        visible: !Media.active
        spacing: 8
        // a soft disc behind the symbol
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 6
            width: 120
            height: 120
            radius: 60
            color: Theme.alpha(Theme.accent, 0.12)
            border.width: 2
            border.color: Theme.alpha(Theme.accent, 0.3)
            FIcon { anchors.centerIn: parent; icon: "music_off"; size: 56; fill: 1; color: Theme.accent }
        }
        FText { Layout.alignment: Qt.AlignHCenter; text: "No media"; font.pixelSize: Theme.fsXxl; font.weight: Font.Bold }
        FText { Layout.alignment: Qt.AlignHCenter; text: "Play something in a music or video app and it shows up here"; dim: true }
    }

    // ── the visualizer, across the bottom (the shared one: Settings → Sound → Audio visualizer) ──
    Spectrum {
        readonly property bool round: (Settings.data.visualizer.style || "bars") === "radial"
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 20
        anchors.horizontalCenter: parent.horizontalCenter
        width: round ? 150 : parent.width - 40
        height: round ? 150 : 110
        count: round ? 48 : Math.max(16, Math.floor((root.width - 40) / 23))
        active: root.live
    }
}
