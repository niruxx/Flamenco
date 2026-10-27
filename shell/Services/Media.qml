pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.Commons

Singleton {
    id: root

    readonly property var cfg: Settings.data.media
    function nameOf(p) {
        return String(p?.identity || p?.desktopEntry || p?.dbusName || "");
    }
    function same(a, b) {
        return a !== "" && String(a).toLowerCase() === String(b).toLowerCase();
    }
    // every player, minus the ones ignored in Settings → Sound
    readonly property var players: Mpris.players.values.filter(p => !(cfg.ignored || []).some(n => same(n, nameOf(p))))
    property var manual: null
    readonly property var preferred: players.find(p => same(cfg.preferred, nameOf(p))) ?? null
    readonly property bool anyPlaying: players.some(p => p.isPlaying)
    // picked by hand, else the preferred one when it has something (unless another one is
    // playing), else the one playing, else one with a track loaded, else any
    readonly property var player: (manual && players.includes(manual)) ? manual
        : (preferred && (preferred.isPlaying || !anyPlaying) && ((preferred.trackTitle ?? "") !== "" || preferred.isPlaying)) ? preferred
        : (players.find(p => p.isPlaying) ?? players.find(p => (p.trackTitle ?? "") !== "") ?? players[0] ?? null)

    // the names seen, for the settings list (kept, so a closed player can still be chosen)
    readonly property var names: Mpris.players.values.map(p => nameOf(p)).filter(n => n !== "")
    onNamesChanged: {
        const seen = (cfg.seen || []).slice();
        let added = false;
        for (const n of names)
            if (!seen.some(s => same(s, n))) {
                seen.push(n);
                added = true;
            }
        if (added && Settings.ready)
            cfg.seen = seen.slice(-30);
    }
    // something to show: a player with a track (an open but empty player doesn't count)
    readonly property bool active: player !== null && ((player.trackTitle ?? "") !== "" || player.isPlaying)
    readonly property bool playing: player?.isPlaying ?? false
    readonly property string title: player?.trackTitle || "No media"
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
