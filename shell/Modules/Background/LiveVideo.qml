import QtQuick
import QtMultimedia

// A live (video) wallpaper, looping. In a file of its own and loaded by URL, so
// without Qt Multimedia (qt6-multimedia) only this fails and the desktop shows
// the video's still instead.
Item {
    id: root

    property string url
    property bool playing: true
    property real speed: 1
    property bool sound: false
    property int fillMode: Image.PreserveAspectCrop
    // the first frame is up (Background fades it in over the still then)
    property bool started: false

    onPlayingChanged: playing ? player.play() : player.pause()

    MediaPlayer {
        id: player
        source: root.url
        loops: MediaPlayer.Infinite
        playbackRate: Math.max(0.25, Math.min(2, root.speed))
        videoOutput: out
        audioOutput: root.sound ? audio : null
        onPositionChanged: if (position > 0) root.started = true
        onErrorOccurred: (error, errorString) => console.warn("[LiveVideo]", errorString, root.url)
        Component.onCompleted: if (root.playing) play()
    }
    AudioOutput {
        id: audio
        volume: 0.5
    }
    VideoOutput {
        id: out
        anchors.fill: parent
        fillMode: root.fillMode === Image.Stretch ? VideoOutput.Stretch : root.fillMode === Image.PreserveAspectFit ? VideoOutput.PreserveAspectFit : VideoOutput.PreserveAspectCrop
    }
}
