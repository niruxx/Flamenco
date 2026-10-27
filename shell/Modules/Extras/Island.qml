import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Commons
import qs.Services
import qs.Widgets

// The Dynamic island (Settings → Desktop widgets → Dynamic island): a pill at the
// top of the screen in use. While something plays it shows the track; it grows for
// a moment to show a notification, or the volume or brightness as they change.
// Only the pill takes clicks.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property ShellScreen modelData
        readonly property var cfg: Settings.data.island
        readonly property bool here: modelData.name === Panels.targetScreen("")
        // what it shows: "note" (a notification), "level" (volume / brightness), "media", or ""
        property string mode: ""
        property var note: null
        property string levelIcon: ""
        property real level: 0
        readonly property bool media: (cfg.media ?? true) && Media.playing
        readonly property string showing: flash.running ? mode : media ? "media" : ""

        function pop(m) {
            mode = m;
            flash.restart();
        }
        Timer { id: flash; interval: win.mode === "note" ? 3500 : 1500 }
        Connections {
            target: Notifs.popups
            enabled: win.cfg.notifications ?? true
            function onCountChanged() {
                if (Notifs.popups.count > 0) {
                    const n = Notifs.popups.get(0);
                    win.note = { app: n.appName, icon: n.appIcon, summary: n.summary, body: n.body };
                    win.pop("note");
                }
            }
        }
        Connections {
            target: Audio
            enabled: win.cfg.levels ?? true
            function onVolumeChanged() {
                win.levelIcon = Audio.muted ? "volume_off" : "volume_up";
                win.level = Audio.volume;
                win.pop("level");
            }
        }
        Connections {
            target: Brightness
            enabled: win.cfg.levels ?? true
            function onValueChanged() {
                win.levelIcon = "brightness_6";
                win.level = Brightness.value;
                win.pop("level");
            }
        }

        screen: modelData
        visible: (cfg.enabled ?? false) && here
        color: "transparent"
        anchors.top: true
        margins.top: Theme.edge
        implicitWidth: 520
        implicitHeight: 120
        exclusionMode: ExclusionMode.Normal
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "flamenco-island"
        mask: Region { item: pill }

        Rectangle {
            id: pill
            anchors.horizontalCenter: parent.horizontalCenter
            y: 0
            readonly property bool big: win.showing === "note"
            width: win.showing === "" ? 120 : big ? 440 : win.showing === "level" ? 260 : 320
            height: win.showing === "" ? 26 : big ? 76 : 40
            radius: height / 2
            color: "#000000"
            opacity: win.showing === "" && !(win.cfg.idle ?? true) ? 0 : 1
            Behavior on width { Anim { easing.bezierCurve: Theme.curves.spring } }
            Behavior on height { Anim { easing.bezierCurve: Theme.curves.spring } }
            Behavior on opacity { Anim {} }

            // media
            RowLayout {
                visible: win.showing === "media"
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 14
                spacing: 10
                ClippingRectangle {
                    implicitWidth: 28; implicitHeight: 28; radius: 14
                    color: "#222"
                    Image { anchors.fill: parent; source: Media.art; fillMode: Image.PreserveAspectCrop; asynchronous: true }
                }
                FText { Layout.fillWidth: true; text: Media.title + (Media.artist ? " · " + Media.artist : ""); color: "#ffffff"; elide: Text.ElideRight; font.pixelSize: Theme.fsSm }
                FIcon { icon: "graphic_eq"; size: 18; color: Theme.accent }
            }
            // a notification
            RowLayout {
                visible: win.showing === "note"
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12
                AppIcon { implicitSize: 40; name: win.note?.icon || win.note?.app || "" }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    FText { Layout.fillWidth: true; text: win.note?.summary ?? ""; color: "#ffffff"; font.weight: Font.DemiBold; elide: Text.ElideRight }
                    FText { Layout.fillWidth: true; text: String(win.note?.body ?? "").replace(/<[^>]*>/g, ""); color: "#bbbbbb"; font.pixelSize: Theme.fsSm; elide: Text.ElideRight; maximumLineCount: 2; wrapMode: Text.Wrap }
                }
            }
            // volume / brightness
            RowLayout {
                visible: win.showing === "level"
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 16
                spacing: 10
                FIcon { icon: win.levelIcon; size: 18; color: "#ffffff" }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 6
                    radius: 3
                    color: "#333333"
                    Rectangle { width: parent.width * Math.max(0, Math.min(1, win.level)); height: parent.height; radius: 3; color: Theme.accent }
                }
                FText { text: Math.round(win.level * 100); color: "#ffffff"; mono: true; font.pixelSize: Theme.fsSm }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: win.showing === "note" ? Panels.toggle("notifications", win.modelData.name) : Panels.openDashboard("media", win.modelData.name)
            }
        }
    }
}
