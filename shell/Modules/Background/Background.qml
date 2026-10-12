import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Commons
import qs.Services
import qs.Widgets

// Wallpaper layer with animated transitions: fade | zoom | circle | wipe | random.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win

        required property ShellScreen modelData
        readonly property string wanted: Wallpapers.current
        readonly property int fill: Settings.data.wallpaper.fillMode === "fit" ? Image.PreserveAspectFit : Settings.data.wallpaper.fillMode === "stretch" ? Image.Stretch : Image.PreserveAspectCrop
        property string kind: "fade"
        property real progress: 0

        screen: modelData
        color: Theme.bg
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Background
        // place-within-backdrop in niri's overview via a layer rule on this namespace
        WlrLayershell.namespace: "flamenco-wallpaper"

        onWantedChanged: begin()
        Component.onCompleted: back.source = Paths.toUrl(wanted)

        function begin() {
            if (!wanted || Paths.toUrl(wanted) === String(back.source))
                return;
            const t = Settings.data.wallpaper.transition;
            const kinds = ["fade", "zoom", "circle", "wipe"];
            kind = t === "random" ? kinds[Math.floor(Math.random() * kinds.length)] : t;
            anim.stop();
            progress = 0;
            front.source = Paths.toUrl(wanted);
        }

        Image {
            id: back
            anchors.fill: parent
            fillMode: win.fill
            asynchronous: true
            sourceSize: Qt.size(win.width, win.height)
            onStatusChanged: if (status === Image.Ready && String(source) === String(front.source)) win.progress = 0
        }

        ClippingRectangle {
            id: clip

            readonly property real diag: Math.hypot(win.width, win.height)
            visible: win.progress > 0
            color: "transparent"
            width: win.kind === "circle" ? diag * win.progress : win.kind === "wipe" ? win.width * win.progress : win.width
            height: win.kind === "circle" ? width : win.height
            radius: win.kind === "circle" ? width / 2 : 0
            x: win.kind === "circle" ? (win.width - width) / 2 : 0
            y: win.kind === "circle" ? (win.height - height) / 2 : 0
            opacity: win.kind === "fade" || win.kind === "zoom" ? win.progress : 1

            Image {
                id: front
                x: -clip.x
                y: -clip.y
                width: win.width
                height: win.height
                fillMode: win.fill
                asynchronous: true
                sourceSize: Qt.size(win.width, win.height)
                scale: win.kind === "zoom" ? 1.15 - 0.15 * win.progress : 1
                onStatusChanged: if (status === Image.Ready && win.progress === 0) anim.start()
            }
        }

        // soft edge on the wipe
        Rectangle {
            visible: win.kind === "wipe" && win.progress > 0 && win.progress < 1
            x: clip.width - width / 2
            width: 120
            height: win.height
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 0.5; color: Theme.alpha(Theme.accent, 0.25) }
                GradientStop { position: 1; color: "transparent" }
            }
        }

        NumberAnimation {
            id: anim
            target: win
            property: "progress"
            from: 0
            to: 1
            duration: Theme.speed <= 0 ? 0 : Settings.data.wallpaper.duration / Theme.speed
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.curves.emphasized
            onFinished: back.source = front.source
        }
    }
}
