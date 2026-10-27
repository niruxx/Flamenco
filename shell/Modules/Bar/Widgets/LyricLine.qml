import QtQuick
import qs.Commons
import qs.Services
import qs.Widgets

// The line of the song being sung now (synced lyrics from lrclib.net), while
// something plays and has them. Click: the media panel.
BarChip {
    id: root
    property string screenName
    property int barLevel: 0
    property bool barVisible: Media.playing && Lyrics.line !== "" && barLevel < 2 && !Theme.barVertical
    onClicked: Panels.openDashboard("media", screenName)
    Component.onCompleted: Lyrics.users++
    Component.onDestruction: Lyrics.users--

    BarFlow {
        spacing: 6
        FIcon { icon: "lyrics"; size: Theme.barIconSm; color: Theme.accent }
        FText {
            width: Math.min(implicitWidth, Settings.data.bar.lyricsWidth || 320)
            text: Lyrics.line
            elide: Text.ElideRight
            font.pixelSize: Theme.fsSm
            font.italic: true
        }
    }
}
