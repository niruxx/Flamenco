pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property var players: Mpris.players.values
    property var manual: null
    readonly property var player: (manual && players.includes(manual)) ? manual : (players.find(p => p.isPlaying) ?? players[0] ?? null)
    readonly property bool active: player !== null
    readonly property bool playing: player?.isPlaying ?? false
    readonly property string title: player?.trackTitle || "Nothing playing"
    readonly property string artist: player?.trackArtist || player?.identity || ""
    readonly property string art: player?.trackArtUrl ?? ""
    readonly property real length: player?.length ?? 0
    readonly property real position: player?.position ?? 0

    function toggle() {
        player?.togglePlaying();
    }
    function next() {
        player?.next();
    }
    function previous() {
        player?.previous();
    }
    function seek(fraction) {
        if (player?.canSeek)
            player.position = fraction * length;
    }
    function cycle() {
        if (players.length < 2)
            return;
        manual = players[(players.indexOf(player) + 1) % players.length];
    }

    // MPRIS doesn't push position updates; poke it while playing.
    Timer {
        running: root.playing
        interval: 1000
        repeat: true
        onTriggered: root.player?.positionChanged()
    }

    function fmt(sec) {
        sec = Math.max(0, Math.floor(sec));
        return Math.floor(sec / 60) + ":" + String(sec % 60).padStart(2, "0");
    }
}
