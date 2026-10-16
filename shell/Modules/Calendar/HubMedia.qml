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
ClippingRectangle {
    id: root

    property bool live: false                  // showing right now (the visualizer and the record run only then)
    property real fillHeight: 600
    implicitHeight: Math.max(540, fillHeight)
    radius: Theme.rXl
    color: Theme.alpha(Theme.text, 0.035)

    readonly property real frac: Media.length > 0 ? Math.max(0, Math.min(1, Media.position / Media.length)) : 0
    readonly property color ink: Media.art !== "" ? "#ffffff" : Theme.text

    onLiveChanged: live ? Cava.users++ : Cava.users = Math.max(0, Cava.users - 1)
    Component.onDestruction: if (live) Cava.users = Math.max(0, Cava.users - 1)

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
        FIcon { Layout.alignment: Qt.AlignHCenter; icon: "music_off"; size: 56; color: Theme.textDim }
        FText { Layout.alignment: Qt.AlignHCenter; text: "Nothing playing"; font.pixelSize: Theme.fsXl; font.weight: Font.Bold }
        FText { Layout.alignment: Qt.AlignHCenter; text: "Play something in any app that supports MPRIS"; dim: true }
    }

    // ── the visualizer, across the bottom: cava's bars spread out, colored along the way ──
    Row {
        id: bars
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 20
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 5
        readonly property int n: Math.max(16, Math.floor((root.width - 40) / 23))
        readonly property var src: Cava.values.length ? Cava.values : new Array(16).fill(0.04)
        // n bars from cava's, in between ones blended
        readonly property var values: {
            const out = [];
            for (let i = 0; i < n; i++) {
                const t = i / Math.max(1, n - 1) * (src.length - 1);
                const a = Math.floor(t), b = Math.min(src.length - 1, a + 1);
                out.push(src[a] + (src[b] - src[a]) * (t - a));
            }
            return out;
        }
        Repeater {
            model: bars.n
            Rectangle {
                required property int index
                readonly property real t: index / Math.max(1, bars.n - 1)
                anchors.bottom: parent.bottom
                width: 18
                height: 6 + (bars.values[index] ?? 0) * 96
                radius: 3
                color: Theme.alpha(t < 0.5 ? Theme.mix(Theme.accent, Theme.accent3, t * 2) : Theme.mix(Theme.accent3, Theme.warning, (t - 0.5) * 2), 0.85)
                Behavior on height { NumberAnimation { duration: 90 } }
            }
        }
    }
}
