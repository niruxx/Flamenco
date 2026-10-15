pragma Singleton

import QtQuick
import Quickshell
import qs.Services as FS

// Flamenco shim for Noctalia's MediaService.
Singleton {
    readonly property var currentPlayer: FS.Media.player
    readonly property bool isPlaying: FS.Media.playing
    readonly property string trackTitle: FS.Media.player?.trackTitle ?? ""
    readonly property string trackArtist: FS.Media.player?.trackArtist ?? ""
    readonly property string trackAlbum: FS.Media.player?.trackAlbum ?? ""
    readonly property string trackArtUrl: FS.Media.art
    readonly property string playerIdentity: FS.Media.player?.identity ?? ""
    readonly property real trackLength: FS.Media.length
    readonly property real currentPosition: FS.Media.position
    function playPause() { FS.Media.toggle(); }
    function next() { FS.Media.next(); }
    function previous() { FS.Media.previous(); }
}
