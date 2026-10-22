import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services
import qs.Widgets
import "Widgets"

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win

        required property ShellScreen modelData
        readonly property var cfg: Settings.data.bar
        readonly property bool islands: cfg.style === "islands"
        // framed: a solid bar edge to edge (like attached) with each section as a grey pill on it
        readonly property bool framed: cfg.style === "framed"
        readonly property bool attached: cfg.style === "attached" || framed
        // capsule: one pill hugging the widgets, centered; minimal: no bar at all, a soft
        // shade behind the widgets; outline: a see-through bar drawn as an outline
        // freeroam (Settings → Bar → Position): a floating pill you drag anywhere by its grip;
        // laid out like the capsule, sized to its widgets, reserving no space
        readonly property bool free: cfg.position === "free"
        readonly property int gripW: free ? Math.round(Theme.barItem * 0.7) : 0
        readonly property real freeX: dragging ? dragX : Math.max(0, Math.min(modelData.width - width, (cfg.freePos?.x ?? 0.3) * modelData.width))
        readonly property real freeY: dragging ? dragY : Math.max(0, Math.min(modelData.height - height, (cfg.freePos?.y ?? 0.04) * modelData.height))
        property bool dragging: false
        property real dragX: 0
        property real dragY: 0
        readonly property bool capsule: cfg.style === "capsule" || free
        readonly property bool minimal: cfg.style === "minimal"
        readonly property bool outline: cfg.style === "outline"
        // the room between the bar's ends and its first / last widget: the same as above and below them
        readonly property int edgePad: islands ? 0 : framed ? Theme.barPillPad : Theme.barInset
        // this screen's own widgets (Settings → Bar → Layout for), else the shared layout
        readonly property var layout: (cfg.perScreen || {})[modelData.name] ?? cfg

        screen: modelData
        color: "transparent"
        readonly property bool vertical: Theme.barVertical
        readonly property int sectionGap: Theme.sp3

        // compaction level for this screen; recomputed from 0 whenever the space or layout changes
        property int level: 0
        function refit() {
            level = 0;
            refitTimer.restart();
        }
        Timer {
            id: refitTimer
            interval: 80
            onTriggered: fitTimer.restart()
        }
        Connections {
            target: Settings.data.bar
            function onLeftChanged() { win.refit(); }
            function onCenterChanged() { win.refit(); }
            function onRightChanged() { win.refit(); }
            function onPerScreenChanged() { win.refit(); }
            function onHeightChanged() { win.refit(); }
            function onPositionChanged() { win.refit(); }
        }
        Connections {
            target: Settings.data.appearance
            function onUiScaleChanged() { win.refit(); }
        }
        readonly property string pos: Theme.barPos
        readonly property int thickness: Theme.barHeight + Theme.barMargin

        anchors {
            top: win.free || win.pos !== "bottom"
            bottom: !win.free && win.pos !== "top"
            left: win.free || win.pos !== "right"
            right: !win.free && win.pos !== "left"
        }
        margins.left: free ? Math.round(freeX) : 0
        margins.top: free ? Math.round(freeY) : 0
        implicitHeight: free ? Theme.barHeight : vertical ? 0 : thickness
        implicitWidth: free ? Math.ceil(content.capLen + Theme.barInset * 2 + gripW) : vertical ? thickness : 0
        exclusionMode: free ? ExclusionMode.Ignore : ExclusionMode.Normal
        exclusiveZone: free ? 0 : !hides || cfg.hideKeepSpace ? thickness : 0
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "flamenco-bar"

        // ── hiding (Settings → Bar → Hide) ──
        // auto: out of the way until the pointer reaches the edge; windows: while the
        // screen's workspace has windows. `flamenco bar toggle` hides it by hand.
        // Brought back by the pointer at the edge (a thin strip stays there) and
        // while a panel is open on this screen.
        readonly property string hideMode: cfg.hide || "never"
        readonly property var activeWs: Niri.workspaces.find(w => w.output === modelData.name && w.is_active) ?? null
        readonly property bool hasWindows: activeWs !== null && Niri.windows.some(w => w.workspace_id === activeWs.id)
        // (a freeroam bar floats wherever you put it: hiding to an edge doesn't apply)
        readonly property bool hides: !free && (Panels.barHidden || hideMode === "auto" || hideMode === "windows" && hasWindows)
        readonly property bool panelHere: Panels.current !== "" && Panels.screen === modelData.name
        readonly property bool revealed: !hides || barHover.hovered || hideDelay.running || panelHere
        Item {
            id: hideAnim
            property real v: win.revealed ? 1 : 0
            Behavior on v { Anim { duration: Theme.durA("bar", win.revealed ? 260 : 320); easing.bezierCurve: win.revealed ? Theme.curves.emphasizedDecel : Theme.curves.emphasizedAccel } }
        }
        Timer {
            id: hideDelay
            interval: Math.max(0, win.cfg.hideDelay ?? 600)
        }
        HoverHandler {
            id: barHover
            onHoveredChanged: if (!hovered) hideDelay.restart()
        }
        // input: the whole bar while it's out, else the strip along the edge
        mask: Region { item: hitArea }
        Item {
            id: hitArea
            readonly property real across: win.revealed || hideAnim.v > 0.01 ? win.thickness : Math.max(1, win.cfg.revealSize ?? 3)
            width: win.vertical ? across : win.width
            height: win.vertical ? win.height : across
            anchors.top: win.pos === "top" || win.vertical ? parent.top : undefined
            anchors.bottom: win.pos === "bottom" ? parent.bottom : undefined
            anchors.left: win.pos === "left" || !win.vertical ? parent.left : undefined
            anchors.right: win.pos === "right" ? parent.right : undefined
        }

        // Entrance: slide in from the edge on startup, and slowly after logging in
        // (SessionFx.revealBar, Settings → Lock & Login → Session)
        readonly property real enter: Math.min(enterAnim.v, SessionFx.revealBar, hideAnim.v)

        // animated value lives on an Item: Behaviors on the window itself crash Qt 6.12
        Item {
            id: enterAnim
            property real v: 0
            Component.onCompleted: v = 1
            Behavior on v { Anim { duration: Theme.durA("bar", 650); easing.bezierCurve: Theme.curves.emphasizedDecel } }
        }

        readonly property var registry: ({
                launcher: launcherC,
                workspaces: workspacesC,
                window: windowC,
                taskbar: taskbarC,
                assistant: assistantC,
                clock: clockC,
                media: mediaC,
                tray: trayC,
                sysstats: statsC,
                keyboard: keyboardC,
                network: networkC,
                bluetooth: bluetoothC,
                audio: audioC,
                mic: micC,
                privacy: privacyC,
                recording: recordC,
                updates: updatesC,
                notepad: notepadC,
                visualizer: visualizerC,
                plugin: pluginC,
                thirdparty: thirdPartyC,
                separator: separatorC,
                clipboard: clipboardC,
                brightness: brightnessC,
                battery: batteryC,
                notifications: notifC,
                weather: weatherC,
                quicksettings: quickC,
                power: powerC
            })

        Component { id: launcherC; LauncherButton { screenName: win.modelData.name } }
        Component { id: workspacesC; Workspaces { screenName: win.modelData.name } }
        Component { id: windowC; WindowTitle { window: win } }
        Component { id: taskbarC; Taskbar { window: win; screenName: win.modelData.name } }
        Component { id: clockC; Clock { screenName: win.modelData.name } }
        Component { id: mediaC; MediaMini { screenName: win.modelData.name } }
        Component { id: trayC; Tray { window: win } }
        Component { id: statsC; SysStats { screenName: win.modelData.name } }
        Component { id: keyboardC; KeyboardLayout {} }
        Component { id: networkC; StatusIcon { screenName: win.modelData.name; icon: Network.icon; tip: Network.label; detail: "wifi" } }
        Component { id: bluetoothC; StatusIcon { screenName: win.modelData.name; icon: BluetoothState.icon; barVisible: BluetoothState.available && barLevel < 3; detail: "bluetooth" } }
        Component { id: audioC; AudioIcon { screenName: win.modelData.name } }
        Component { id: micC; MicIndicator { screenName: win.modelData.name } }
        Component { id: pluginC; PluginBarWidget { screenName: win.modelData.name } }
        Component { id: thirdPartyC; ThirdPartyBarWidget { screenName: win.modelData.name } }
        Component { id: separatorC; Separator {} }
        Component { id: clipboardC; ClipboardButton { screenName: win.modelData.name } }
        Component { id: visualizerC; Visualizer { screenName: win.modelData.name } }
        Component { id: notepadC; FIconButton { id: noteBtn; icon: "sticky_note_2"; size: Theme.barItem; iconSize: 18; active: Panels.current === "notepad"; onClicked: Panels.toggle("notepad", win.modelData.name, noteBtn) } }
        Component { id: updatesC; UpdatesIndicator { window: win; screenName: win.modelData.name } }
        Component { id: recordC; RecordIndicator { screenName: win.modelData.name } }
        Component { id: privacyC; PrivacyIndicator { window: win; screenName: win.modelData.name } }
        Component { id: brightnessC; BrightnessIcon { screenName: win.modelData.name } }
        Component { id: batteryC; Battery { screenName: win.modelData.name } }
        Component { id: notifC; NotifBell { screenName: win.modelData.name } }
        Component { id: weatherC; WeatherChip { screenName: win.modelData.name } }
        Component { id: quickC; FIconButton { id: qsBtn; icon: "menu"; size: Theme.barItem; iconSize: 18; active: Panels.current === "control" && Panels.controlDetail === ""; onClicked: Panels.toggle("control", win.modelData.name, qsBtn) } }
        Component { id: assistantC; FIconButton { id: aiBtn; property bool barVisible: Settings.data.ai.enabled; icon: "auto_awesome"; size: Theme.barItem; iconSize: 18; active: Panels.current === "assistant"; onClicked: Panels.toggle("assistant", win.modelData.name, aiBtn) } }
        Component { id: powerC; FIconButton { id: powerBtn; icon: "power_settings_new"; size: Theme.barItem; iconColor: Theme.error; onClicked: Panels.toggle("power", win.modelData.name, powerBtn) } }

        Item {
            id: content
            anchors.fill: parent
            // margin on the screen-edge side and both ends; none on the inner side
            anchors.topMargin: win.free || win.pos === "bottom" ? 0 : Theme.barMargin
            anchors.bottomMargin: win.free || win.pos === "top" ? 0 : Theme.barMargin
            anchors.leftMargin: win.free || win.pos === "right" ? 0 : Theme.barMargin
            anchors.rightMargin: win.free || win.pos === "left" ? 0 : Theme.barMargin
            opacity: win.enter
            transform: Translate {
                readonly property real d: (1 - win.enter) * (Theme.barHeight + Theme.barMargin * 2)
                x: win.pos === "left" ? -d : win.pos === "right" ? d : 0
                y: win.pos === "top" ? -d : win.pos === "bottom" ? d : 0
            }

            // capsule: where the packed sections start (centered along the bar)
            readonly property real capLen: (startSec.visible ? startSec.size + win.sectionGap : 0) + (centerSec.visible ? centerSec.size + win.sectionGap : 0) + (endSec.visible ? endSec.size : 0) - (endSec.visible ? 0 : win.sectionGap)
            readonly property real capStart: win.free ? win.gripW + Theme.barInset : ((win.vertical ? height : width) - capLen) / 2

            // minimal: a soft shade from the screen edge, so the widgets read on any wallpaper
            Rectangle {
                visible: win.minimal
                anchors.fill: parent
                anchors.margins: -Theme.barMargin
                gradient: Gradient {
                    orientation: win.vertical ? Gradient.Horizontal : Gradient.Vertical
                    GradientStop { position: 0; color: win.pos === "top" || win.pos === "left" ? Theme.alpha(Theme.shadow, 0.38 * Theme.barOp) : "transparent" }
                    GradientStop { position: 1; color: win.pos === "top" || win.pos === "left" ? "transparent" : Theme.alpha(Theme.shadow, 0.38 * Theme.barOp) }
                }
            }

            Rectangle {
                id: bg
                visible: !win.islands && !win.minimal
                // the whole bar, or (capsule) just around the widgets
                x: win.free ? 0 : win.capsule && !win.vertical ? content.capStart - Theme.barInset : 0
                y: win.capsule && win.vertical ? content.capStart - Theme.barInset : 0
                width: win.free ? parent.width : win.capsule && !win.vertical ? content.capLen + Theme.barInset * 2 : parent.width
                height: win.capsule && win.vertical ? content.capLen + Theme.barInset * 2 : parent.height
                Behavior on width { enabled: win.capsule; Anim { easing.bezierCurve: Theme.curves.emphasizedDecel } }
                Behavior on x { enabled: win.capsule; Anim { easing.bezierCurve: Theme.curves.emphasizedDecel } }
                color: win.outline ? Theme.alpha(Theme.bg, Theme.barOp * 0.3) : Theme.barBg
                radius: win.attached ? 0 : win.capsule ? Math.floor(Theme.barHeight / 2) : Theme.barRadius
                // no outline when panels blend into the bar: it would show as a seam
                border.width: win.outline ? 1.5 : win.attached || Theme.blendPanels || !(win.cfg.border ?? true) ? 0 : 1
                border.color: win.outline ? Theme.alpha(Theme.text, 0.28) : Theme.alpha(Theme.border, 0.5)

                Finish { visible: !win.outline && (Settings.data.appearance.finish || "flat") !== "flat" }

                // freeroam: the grip to drag the bar by (where it lands is kept as a share of the screen)
                Item {
                    visible: win.free
                    width: win.gripW + Theme.barInset
                    height: parent.height
                    FIcon {
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: Theme.barInset / 2
                        icon: "drag_indicator"
                        size: Math.round(Theme.barItem * 0.6)
                        color: grip.active ? Theme.accent : Theme.textDim
                    }
                    HoverHandler { cursorShape: grip.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor }
                    DragHandler {
                        id: grip
                        target: null
                        property real sx: 0
                        property real sy: 0
                        onActiveChanged: {
                            if (active) {
                                sx = win.freeX;
                                sy = win.freeY;
                                win.dragX = sx;
                                win.dragY = sy;
                                win.dragging = true;
                            } else {
                                win.cfg.freePos = { x: win.dragX / win.modelData.width, y: win.dragY / win.modelData.height };
                                win.dragging = false;
                            }
                        }
                        onTranslationChanged: {
                            if (!active)
                                return;
                            win.dragX = Math.max(0, Math.min(win.modelData.width - win.width, sx + translation.x));
                            win.dragY = Math.max(0, Math.min(win.modelData.height - win.height, sy + translation.y));
                        }
                    }
                }

                layer.enabled: Settings.data.appearance.shadows && (win.cfg.shadow ?? true) && !win.attached && !win.outline
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Theme.alpha(Theme.shadow, 0.35)
                    shadowBlur: 0.6
                    shadowVerticalOffset: 2
                }
            }

            // ── fit to the space available ──
            // Sections that don't fit step the bar through compaction levels
            // (0 full · 1 no text labels · 2 low-priority widgets hidden · 3 minimal).
            readonly property real avail: win.vertical ? height : width
            readonly property real used: (startSec.visible ? startSec.size : 0) + (centerSec.visible ? centerSec.size : 0) + (endSec.visible ? endSec.size : 0) + 2 * win.sectionGap + 2 * win.edgePad
            onUsedChanged: fitTimer.restart()
            onAvailChanged: win.refit()

            Timer {
                id: fitTimer
                interval: 80
                onTriggered: {
                    if (!win.free && content.used > content.avail && win.level < 3) {
                        win.level++;
                        restart();
                    }
                }
            }

            // start (left / top)
            BarSection {
                id: startSec
                barSide: "start"
                registry: win.registry
                islands: win.islands || win.framed
                pills: win.framed
                vertical: win.vertical
                level: win.level
                ids: win.layout.left ?? win.cfg.left
                readonly property real along: win.capsule ? content.capStart : win.edgePad
                x: win.vertical ? (parent.width - width) / 2 : along
                y: win.vertical ? along : (parent.height - height) / 2
            }

            // center: centered when there's room, otherwise kept between its neighbours
            BarSection {
                id: centerSec
                barSide: "center"
                registry: win.registry
                islands: win.islands || win.framed
                pills: win.framed
                vertical: win.vertical
                level: win.level
                ids: win.layout.center ?? win.cfg.center

                readonly property real lo: startSec.visible ? (win.vertical ? startSec.y + startSec.height : startSec.x + startSec.width) + win.sectionGap : 0
                readonly property real hi: (endSec.visible ? (win.vertical ? endSec.y : endSec.x) - win.sectionGap : (win.vertical ? parent.height : parent.width)) - size
                readonly property real ideal: ((win.vertical ? parent.height : parent.width) - size) / 2
                readonly property real pos: win.capsule ? content.capStart + (startSec.visible ? startSec.size + win.sectionGap : 0) : Math.max(lo, Math.min(hi, ideal))

                x: win.vertical ? (parent.width - width) / 2 : pos
                y: win.vertical ? pos : (parent.height - height) / 2
            }

            // end (right / bottom)
            BarSection {
                id: endSec
                barSide: "end"
                registry: win.registry
                islands: win.islands || win.framed
                pills: win.framed
                vertical: win.vertical
                level: win.level
                ids: win.layout.right ?? win.cfg.right
                readonly property real along: win.capsule ? centerSec.pos + (centerSec.visible ? centerSec.size + win.sectionGap : 0)
                    : (win.vertical ? parent.height : parent.width) - size - win.edgePad
                x: win.vertical ? (parent.width - width) / 2 : along
                y: win.vertical ? along : (parent.height - height) / 2
            }
        }
    }
}
