import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.Commons
import qs.Services
import qs.Widgets

// The Dynamic island's pill, floating (Island) or in the bar (the "island" bar
// widget). It shows the track while something plays, grows for a notification or
// a volume / brightness change, and on hover opens into a bigger pill with the
// cover, the track, a seek bar and the player's controls.
Rectangle {
    id: root
    property string screenName: ""
    property bool inBar: false               // smaller, sized for the bar
    property bool growsDown: true            // which way the hover pill opens
    readonly property var cfg: Settings.data.island
    property string mode: ""
    property var note: null
    property string levelIcon: ""
    property real level: 0
    readonly property bool media: (cfg.media ?? true) && Media.active
    readonly property bool hovered: hover.hovered
    readonly property string showing: hovered && Media.active ? "full" : flash.running ? mode : media ? "media" : ""

    function pop(m) {
        mode = m;
        flash.restart();
    }
    Timer { id: flash; interval: root.mode === "note" ? 3500 : 1500 }
    Connections {
        target: Notifs.popups
        enabled: root.cfg.notifications ?? true
        function onCountChanged() {
            if (Notifs.popups.count > 0) {
                const n = Notifs.popups.get(0);
                root.note = { app: n.appName, icon: n.appIcon, summary: n.summary, body: n.body };
                root.pop("note");
            }
        }
    }
    Connections {
        target: Audio
        enabled: root.cfg.levels ?? true
        function onVolumeChanged() {
            root.levelIcon = Audio.muted ? "volume_off" : "volume_up";
            root.level = Audio.volume;
            root.pop("level");
        }
    }
    Connections {
        target: Brightness
        enabled: root.cfg.levels ?? true
        function onValueChanged() {
            root.levelIcon = "brightness_6";
            root.level = Brightness.value;
            root.pop("level");
        }
    }

    readonly property real h0: inBar ? Theme.barItem : 26
    width: showing === "full" ? 380 : showing === "" ? (inBar ? h0 * 2.4 : 120) : showing === "note" ? 440 : showing === "level" ? 260 : (inBar ? 240 : 320)
    height: showing === "full" ? 132 : showing === "note" ? 76 : showing === "" ? h0 : Math.max(h0, 40 * (inBar ? 0 : 1))
    radius: Math.min(height / 2, 28)
    color: "#000000"
    opacity: showing === "" && !(cfg.idle ?? true) && !inBar ? 0 : 1
    Behavior on width { Anim { easing.bezierCurve: Theme.curves.spring } }
    Behavior on height { Anim { easing.bezierCurve: Theme.curves.spring } }
    Behavior on opacity { Anim {} }

    HoverHandler { id: hover }
    // lyrics are looked up while a pill shows them
    readonly property bool wantsLyrics: (cfg.enabled ?? false) && (cfg.lyrics ?? true)
    onWantsLyricsChanged: Lyrics.users += wantsLyrics ? 1 : -1
    Component.onCompleted: if (wantsLyrics) Lyrics.users++
    Component.onDestruction: if (wantsLyrics) Lyrics.users--

    // idle: a small dot
    Rectangle {
        visible: root.showing === ""
        anchors.centerIn: parent
        width: 6; height: 6; radius: 3
        color: "#666666"
    }
    // media, small
    RowLayout {
        visible: root.showing === "media"
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 12
        spacing: 10
        ClippingRectangle {
            implicitWidth: root.height - 10; implicitHeight: implicitWidth; radius: implicitWidth / 2
            color: "#222"
            Image { anchors.fill: parent; source: Media.art; fillMode: Image.PreserveAspectCrop; asynchronous: true }
        }
        FText {
            Layout.fillWidth: true
            text: (Lyrics.line && (root.cfg.lyrics ?? true)) ? Lyrics.line : Media.title + (Media.artist ? " · " + Media.artist : "")
            color: "#ffffff"; elide: Text.ElideRight; font.pixelSize: Theme.fsSm
        }
        FIcon { icon: Media.playing ? "graphic_eq" : "pause"; size: 16; color: Theme.accent }
    }
    // hovered: the bigger pill with details and controls
    RowLayout {
        visible: root.showing === "full"
        anchors.fill: parent
        anchors.margins: 14
        spacing: 14
        ClippingRectangle {
            implicitWidth: 100; implicitHeight: 100; radius: 18
            color: "#222"
            Image { anchors.fill: parent; source: Media.art; fillMode: Image.PreserveAspectCrop; asynchronous: true }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            FText { Layout.fillWidth: true; text: Media.title; color: "#ffffff"; font.weight: Font.DemiBold; elide: Text.ElideRight }
            FText { Layout.fillWidth: true; text: Media.artist; color: "#aaaaaa"; font.pixelSize: Theme.fsSm; elide: Text.ElideRight }
            FText { Layout.fillWidth: true; visible: text !== ""; text: Lyrics.line; color: Theme.accent; font.pixelSize: Theme.fsXs; font.italic: true; elide: Text.ElideRight }
            // seek bar
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 4
                radius: 2
                color: "#333333"
                Rectangle { width: parent.width * (Media.length > 0 ? Math.min(1, Media.position / Media.length) : 0); height: parent.height; radius: 2; color: "#ffffff" }
                MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: mouse => Media.seek(mouse.x / width) }
            }
            RowLayout {
                spacing: 4
                FText { text: Media.fmt(Media.position); color: "#888888"; mono: true; font.pixelSize: Theme.fsXs }
                Item { Layout.fillWidth: true }
                FIconButton { icon: "skip_previous"; size: 30; iconColor: "#ffffff"; onClicked: Media.previous() }
                FIconButton { icon: Media.playing ? "pause" : "play_arrow"; size: 34; iconColor: "#ffffff"; onClicked: Media.toggle() }
                FIconButton { icon: "skip_next"; size: 30; iconColor: "#ffffff"; onClicked: Media.next() }
                FIconButton { icon: "open_in_full"; size: 26; iconColor: "#aaaaaa"; onClicked: Panels.openDashboard("media", root.screenName) }
                Item { Layout.fillWidth: true }
                FText { text: Media.fmt(Media.length); color: "#888888"; mono: true; font.pixelSize: Theme.fsXs }
            }
        }
    }
    // a notification
    RowLayout {
        visible: root.showing === "note"
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12
        AppIcon { implicitSize: 40; name: root.note?.icon || root.note?.app || "" }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            FText { Layout.fillWidth: true; text: root.note?.summary ?? ""; color: "#ffffff"; font.weight: Font.DemiBold; elide: Text.ElideRight }
            FText { Layout.fillWidth: true; text: String(root.note?.body ?? "").replace(/<[^>]*>/g, ""); color: "#bbbbbb"; font.pixelSize: Theme.fsSm; elide: Text.ElideRight; maximumLineCount: 2; wrapMode: Text.Wrap }
        }
    }
    // volume / brightness
    RowLayout {
        visible: root.showing === "level"
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 16
        spacing: 10
        FIcon { icon: root.levelIcon; size: 18; color: "#ffffff" }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 6
            radius: 3
            color: "#333333"
            Rectangle { width: parent.width * Math.max(0, Math.min(1, root.level)); height: parent.height; radius: 3; color: Theme.accent }
        }
        FText { text: Math.round(root.level * 100); color: "#ffffff"; mono: true; font.pixelSize: Theme.fsSm }
    }
    // a click (outside the hover controls): the notification center, or the media page
    TapHandler {
        enabled: root.showing === "note" || root.showing === "media" || root.showing === ""
        onTapped: root.showing === "note" ? Panels.toggle("notifications", root.screenName) : Panels.openDashboard("media", root.screenName)
    }
}
