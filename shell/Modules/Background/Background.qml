import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services
import qs.Widgets

// Wallpaper, drawn twice per screen:
//
//  • desktop  ("flamenco-desktop")   the wallpaper on your workspaces, with the
//                                    animated transitions below.
//  • backdrop ("flamenco-wallpaper") a blurred, dimmed copy that niri puts in its
//                                    backdrop (behind workspaces in the overview
//                                    and between them while switching), via the
//                                    `place-within-backdrop` layer rule.
//
// Transitions reveal the new image through a mask. The mask shapes are drawn
// in white, blurred for a soft edge, and fed to MultiEffect; an accent glow
// follows the edge. Kinds: fade · focus · circle · ripple · wipe · sweep ·
// blinds · mosaic · random.
Scope {
    id: root

    readonly property var kinds: ["fade", "focus", "circle", "ripple", "wipe", "sweep", "blinds", "mosaic"]
    readonly property int fillMode: Settings.data.wallpaper.fillMode === "fit" ? Image.PreserveAspectFit : Settings.data.wallpaper.fillMode === "stretch" ? Image.Stretch : Image.PreserveAspectCrop

    // ── desktop ──
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property ShellScreen modelData
            readonly property string wanted: Wallpapers.forScreen(modelData.name)
            readonly property real diag: Math.hypot(width, height)
            property string kind: "fade"
            property real p: 0          // 0 → 1, linear; effects apply their own easing
            property bool running: false

            function ease(t) {          // ease-in-out cubic
                return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2;
            }
            // staggered local progress: element at normalized distance d starts later
            function stagger(d, spread) {
                const t = Math.max(0, Math.min(1, win.p * (1 + spread) - d * spread));
                return 1 - Math.pow(1 - t, 3);
            }

            function begin() {
                if (!wanted || Paths.toUrl(wanted) === String(back.source))
                    return;
                let t = Settings.data.wallpaper.transition;
                if (t === "zoom")
                    t = "focus";           // renamed
                kind = t === "random" || !root.kinds.includes(t) ? root.kinds[Math.floor(Math.random() * root.kinds.length)] : t;
                anim.stop();
                p = 0;
                running = false;
                front.source = Paths.toUrl(wanted);
            }

            onWantedChanged: begin()
            Component.onCompleted: back.source = Paths.toUrl(wanted)

            screen: modelData
            color: Theme.bg
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "flamenco-desktop"

            // current wallpaper
            Image {
                id: back
                anchors.fill: parent
                fillMode: root.fillMode
                asynchronous: true
                sourceSize: Qt.size(win.width, win.height)
                onStatusChanged: {
                    // once the new image is in place underneath, drop the transition layer
                    if (status === Image.Ready && String(source) === String(front.source) && !anim.running) {
                        win.running = false;
                        win.p = 0;
                    }
                }
            }

            // incoming wallpaper (drawn through `reveal`)
            Image {
                id: front
                anchors.fill: parent
                fillMode: root.fillMode
                asynchronous: true
                sourceSize: Qt.size(win.width, win.height)
                visible: false
                onStatusChanged: {
                    if (status === Image.Ready && !win.running && String(source) !== String(back.source)) {
                        win.running = true;
                        if (anim.duration <= 0)
                            back.source = front.source;
                        else
                            anim.restart();
                    }
                }
            }

            // ── mask: white shapes → blurred → soft-edged alpha mask ──
            Item {
                id: mask
                anchors.fill: parent
                visible: false
                layer.enabled: true

                Item {
                    id: shapes
                    anchors.fill: parent
                    visible: false
                    layer.enabled: true

                    Loader {
                        anchors.fill: parent
                        active: win.running
                        sourceComponent: win.kind === "circle" ? circleShape : win.kind === "ripple" ? rippleShape : win.kind === "wipe" ? wipeShape : win.kind === "sweep" ? sweepShape : win.kind === "blinds" ? blindsShape : win.kind === "mosaic" ? mosaicShape : null
                    }
                }

                MultiEffect {
                    anchors.fill: parent
                    source: shapes
                    blurEnabled: true
                    blur: win.kind === "mosaic" || win.kind === "blinds" ? 0.25 : 0.8
                    blurMax: 48
                }
            }

            MultiEffect {
                id: reveal
                anchors.fill: parent
                // The mask is drawn in a layer that still holds the end of the last
                // transition (fully revealed) until it redraws; showing the new picture
                // through it at once flashed the whole wallpaper before the animation.
                // So it shows once the transition is under way and the mask is fresh.
                visible: win.running && (win.p > 0.02 || win.kind === "fade" || win.kind === "focus")
                source: front
                maskEnabled: !["fade", "focus"].includes(win.kind)
                maskSource: mask
                // MultiEffect's lower edge runs from min·(1+spread) − spread to min·(1+spread):
                // 0.5 with a spread of 1 maps the mask's 0 → 1 to hidden → shown (with min 0
                // it ran from −1 to 0, so an empty mask already showed the whole new picture,
                // and the wallpaper changed before the transition played)
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
                opacity: win.kind === "fade" ? win.ease(win.p) : win.kind === "focus" ? Math.min(1, win.p * 1.6) : 1
                blurEnabled: win.kind === "focus"
                blur: win.kind === "focus" ? 1 - win.ease(win.p) : 0
                blurMax: 64
                scale: win.kind === "focus" ? 1.08 - 0.08 * win.ease(win.p) : 1
            }

            // ── accent glow along the moving edge ──
            Loader {
                anchors.fill: parent
                active: win.running
                sourceComponent: win.kind === "circle" || win.kind === "ripple" ? ringGlow : win.kind === "sweep" || win.kind === "wipe" ? edgeGlow : win.kind === "mosaic" ? tileGlow : win.kind === "blinds" ? slatGlow : null
            }

            NumberAnimation {
                id: anim
                target: win
                property: "p"
                from: 0
                to: 1
                duration: Theme.speed <= 0 ? 0 : Math.max(200, Settings.data.wallpaper.duration) / Theme.speed
                easing.type: Easing.Linear
                onFinished: back.source = front.source
            }

            // ─────────────────────────── mask shapes ───────────────────────────

            Component {
                id: circleShape
                Item {
                    Rectangle {
                        readonly property real r: win.diag * 0.55 * win.ease(win.p)
                        x: win.width / 2 - r
                        y: win.height / 2 - r
                        width: r * 2
                        height: width
                        radius: r
                        color: "white"
                    }
                }
            }

            Component {
                id: rippleShape
                Item {
                    readonly property real r: win.diag * 0.6 * win.ease(win.p)
                    Rectangle {
                        x: win.width / 2 - parent.r
                        y: win.height / 2 - parent.r
                        width: parent.r * 2
                        height: width
                        radius: parent.r
                        color: "white"
                    }
                    // thin rings racing ahead of the disc
                    Repeater {
                        model: 3
                        Rectangle {
                            required property int index
                            readonly property real rr: parent.r + (index + 1) * 70 * (1 - win.p * 0.6)
                            x: win.width / 2 - rr
                            y: win.height / 2 - rr
                            width: rr * 2
                            height: width
                            radius: rr
                            color: "transparent"
                            border.color: "white"
                            border.width: Math.max(1, 14 - index * 4)
                            opacity: (1 - win.p) * (1 - index * 0.25)
                        }
                    }
                }
            }

            Component {
                id: wipeShape
                Item {
                    Rectangle {
                        width: (win.width + 200) * win.ease(win.p)
                        height: win.height
                        color: "white"
                    }
                }
            }

            Component {
                id: sweepShape
                Item {
                    // a tilted band sliding across the whole screen
                    Rectangle {
                        width: win.diag * 2
                        height: win.diag * 2
                        rotation: -22
                        transformOrigin: Item.Right
                        // right (leading) edge travels from 0.3·diag left of the screen to 0.3·diag past it
                        x: -width - win.diag * 0.3 + (win.width + win.diag * 0.6) * win.ease(win.p)
                        y: (win.height - height) / 2
                        color: "white"
                    }
                }
            }

            Component {
                id: blindsShape
                Item {
                    readonly property int slats: 12
                    Repeater {
                        model: parent.slats
                        Rectangle {
                            required property int index
                            readonly property real t: win.stagger(index / parent.slats, 1.2)
                            x: index * win.width / parent.slats
                            width: (win.width / parent.slats + 1) * t
                            height: win.height
                            color: "white"
                        }
                    }
                }
            }

            Component {
                id: mosaicShape
                Item {
                    id: grid
                    readonly property int cols: 16
                    readonly property real cell: win.width / cols
                    readonly property int rows: Math.ceil(win.height / cell)
                    Repeater {
                        model: grid.cols * grid.rows
                        Rectangle {
                            required property int index
                            readonly property int cx: index % grid.cols
                            readonly property int cy: Math.floor(index / grid.cols)
                            // distance from the screen center, 0..1
                            readonly property real d: Math.hypot(cx + 0.5 - grid.cols / 2, cy + 0.5 - grid.rows / 2) / Math.hypot(grid.cols / 2, grid.rows / 2)
                            readonly property real t: win.stagger(d, 1.4)
                            x: cx * grid.cell
                            y: cy * grid.cell
                            width: grid.cell + 1
                            height: grid.cell + 1
                            radius: (grid.cell / 2) * (1 - t)
                            scale: t
                            color: "white"
                        }
                    }
                }
            }

            // ─────────────────────────── glows ───────────────────────────

            Component {
                id: ringGlow
                Item {
                    readonly property real r: win.diag * (win.kind === "ripple" ? 0.6 : 0.55) * win.ease(win.p)
                    Rectangle {
                        x: win.width / 2 - parent.r - 6
                        y: win.height / 2 - parent.r - 6
                        width: parent.r * 2 + 12
                        height: width
                        radius: width / 2
                        color: "transparent"
                        border.color: Theme.accent
                        border.width: 6
                        opacity: 0.55 * Math.sin(Math.PI * win.p)
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            blurEnabled: true
                            blur: 0.6
                            blurMax: 32
                        }
                    }
                }
            }

            Component {
                id: edgeGlow
                Item {
                    readonly property bool tilted: win.kind === "sweep"
                    Rectangle {
                        width: 160
                        height: parent.tilted ? win.diag * 2 : win.height
                        rotation: parent.tilted ? -22 : 0
                        x: parent.tilted ? -win.diag * 0.3 - width / 2 + (win.width + win.diag * 0.6) * win.ease(win.p) : (win.width + 200) * win.ease(win.p) - width / 2
                        y: (win.height - height) / 2
                        opacity: Math.sin(Math.PI * win.p)
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: "transparent" }
                            GradientStop { position: 0.5; color: Theme.alpha(Theme.accent, 0.45) }
                            GradientStop { position: 1; color: "transparent" }
                        }
                    }
                }
            }

            Component {
                id: tileGlow
                Item {
                    id: g
                    readonly property int cols: 16
                    readonly property real cell: win.width / cols
                    readonly property int rows: Math.ceil(win.height / cell)
                    Repeater {
                        model: g.cols * g.rows
                        Rectangle {
                            required property int index
                            readonly property int cx: index % g.cols
                            readonly property int cy: Math.floor(index / g.cols)
                            readonly property real d: Math.hypot(cx + 0.5 - g.cols / 2, cy + 0.5 - g.rows / 2) / Math.hypot(g.cols / 2, g.rows / 2)
                            readonly property real t: win.stagger(d, 1.4)
                            x: cx * g.cell + 2
                            y: cy * g.cell + 2
                            width: g.cell - 4
                            height: g.cell - 4
                            radius: 6
                            color: Theme.accent
                            // flashes as each tile lands
                            opacity: 0.4 * Math.sin(Math.PI * t)
                        }
                    }
                }
            }

            Component {
                id: slatGlow
                Item {
                    readonly property int slats: 12
                    Repeater {
                        model: parent.slats
                        Rectangle {
                            required property int index
                            readonly property real t: win.stagger(index / parent.slats, 1.2)
                            x: index * win.width / parent.slats + (win.width / parent.slats) * t - 2
                            width: 4
                            height: win.height
                            color: Theme.accent
                            opacity: 0.6 * Math.sin(Math.PI * t)
                        }
                    }
                }
            }
        }
    }

    // ── backdrop (niri overview / between workspaces) ──
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: backdrop

            required property ShellScreen modelData
            readonly property string url: Paths.toUrl(Wallpapers.forScreen(modelData.name))
            property bool useA: true

            screen: modelData
            color: Theme.bg
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Background
            // matched by `layer-rule { match namespace="^flamenco-wallpaper$"; place-within-backdrop true; }`
            WlrLayershell.namespace: "flamenco-wallpaper"

            onUrlChanged: {
                useA = !useA;
                (useA ? imgA : imgB).source = url;
            }
            Component.onCompleted: imgA.source = url

            BackdropLayer { id: imgA; shown: backdrop.useA; fillMode: root.fillMode }
            BackdropLayer { id: imgB; shown: !backdrop.useA; fillMode: root.fillMode }
        }
    }
}
