import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services
import qs.Widgets

// Full-screen login / logout animation on every screen. The "cover" is the
// blurred, dimmed wallpaper with a greeting; a mask decides how much of it shows.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property ShellScreen modelData
        readonly property real c: SessionFx.cover
        readonly property real diag: Math.hypot(width, height)

        function stagger(d, spread) {
            const t = Math.max(0, Math.min(1, c * (1 + spread) - d * spread));
            return 1 - Math.pow(1 - t, 3);
        }

        screen: modelData
        visible: SessionFx.mode !== ""
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "flamenco-session"
        // let clicks through once the intro is mostly open
        mask: SessionFx.mode === "intro" && c < 0.6 ? passThrough : null

        Region { id: passThrough }

        // ── the cover material ──
        Item {
            id: material
            anchors.fill: parent
            visible: false
            layer.enabled: true

            Rectangle { anchors.fill: parent; color: Theme.bg }
            Image {
                id: wall
                anchors.fill: parent
                source: Wallpapers.stillUrl(Wallpapers.forScreen(win.modelData.name))
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(Math.max(1, win.width / 2), Math.max(1, win.height / 2))
                asynchronous: true
                visible: false
            }
            MultiEffect {
                anchors.fill: parent
                source: wall
                blurEnabled: true
                blur: 1
                blurMax: 64
                brightness: -0.35
                saturation: -0.2
            }
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0; color: Theme.alpha(Theme.accent, 0.18) }
                    GradientStop { position: 0.6; color: "transparent" }
                    GradientStop { position: 1; color: Theme.alpha(Theme.accent2, 0.12) }
                }
            }
        }

        // ── mask: white = covered ──
        Item {
            id: maskShapes
            anchors.fill: parent
            visible: false
            layer.enabled: true

            // fade / zoom: everything
            Rectangle {
                anchors.fill: parent
                visible: SessionFx.preset === "fade" || SessionFx.preset === "zoom"
                color: "white"
            }
            // bloom: a hole that opens from the center (mask inverted below)
            Rectangle {
                visible: SessionFx.preset === "bloom"
                readonly property real r: (1 - win.c) * win.diag * 0.55
                x: win.width / 2 - r
                y: win.height / 2 - r
                width: r * 2
                height: width
                radius: r
                color: "white"
            }
            // curtain: two halves
            Rectangle {
                visible: SessionFx.preset === "curtain"
                width: win.width / 2 + 1
                height: win.height
                x: -width * (1 - win.c)
                color: "white"
            }
            Rectangle {
                visible: SessionFx.preset === "curtain"
                width: win.width / 2 + 1
                height: win.height
                x: win.width / 2 + width * (1 - win.c)
                color: "white"
            }
            // blinds: staggered slats
            Repeater {
                model: SessionFx.preset === "blinds" ? 10 : 0
                Rectangle {
                    required property int index
                    readonly property real t: win.stagger(index / 10, 1.1)
                    x: index * win.width / 10
                    width: (win.width / 10 + 1) * t
                    height: win.height
                    color: "white"
                }
            }
        }

        MultiEffect {
            id: coverEffect
            anchors.fill: parent
            source: material
            maskEnabled: true
            maskSource: maskShapes
            maskInverted: SessionFx.preset === "bloom"
            maskThresholdMin: 0.0
            maskSpreadAtMin: 0.0
            opacity: SessionFx.preset === "fade" || SessionFx.preset === "zoom" ? win.c : 1
            scale: SessionFx.preset === "zoom" ? 1 + 0.25 * (1 - win.c) : 1
        }

        // accent edges that follow the motion
        Rectangle {
            visible: SessionFx.preset === "bloom" && win.c > 0 && win.c < 1
            readonly property real r: (1 - win.c) * win.diag * 0.55
            x: win.width / 2 - r - 3
            y: win.height / 2 - r - 3
            width: r * 2 + 6
            height: width
            radius: width / 2
            color: "transparent"
            border.width: 3
            border.color: Theme.accent
            opacity: Math.sin(Math.PI * win.c)
        }
        Repeater {
            model: SessionFx.preset === "curtain" ? 2 : 0
            Rectangle {
                required property int index
                width: 3
                height: win.height
                x: index === 0 ? win.width / 2 * win.c - 3 : win.width - win.width / 2 * win.c
                color: Theme.accent
                opacity: Math.sin(Math.PI * win.c)
            }
        }

        // ── greeting ──
        Column {
            anchors.centerIn: parent
            spacing: Theme.sp3
            opacity: Math.max(0, (win.c - 0.35) / 0.65)
            scale: 0.9 + 0.1 * win.c

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 84
                height: 84
                radius: Theme.rXl
                gradient: Gradient {
                    GradientStop { position: 0; color: Theme.accent }
                    GradientStop { position: 1; color: Theme.accent2 }
                }
                FIcon { anchors.centerIn: parent; icon: "local_fire_department"; size: 48; fill: 1; color: Theme.onAccent }
            }
            FText {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: text !== ""
                text: SessionFx.message
                font.pixelSize: Theme.fsXxl
                font.weight: Font.Bold
                color: "white"
            }
            FText {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: text !== ""
                text: SessionFx.detail
                font.pixelSize: Theme.fsLg
                color: Qt.rgba(1, 1, 1, 0.75)
            }
        }
    }
}
