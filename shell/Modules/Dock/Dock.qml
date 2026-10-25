import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services
import qs.Widgets
import "../Bar/Widgets"

// Pinned + running apps, macOS-style magnification, auto-hide.
// Bottom, left or right edge; everything is set in Settings → Dock.
Variants {
    // every screen, or just the chosen one (all of them if it isn't connected)
    model: {
        if (!Settings.data.dock.enabled)
            return [];
        const want = Settings.data.dock.screen;
        const match = Quickshell.screens.filter(s => s.name === want);
        return want && match.length ? match : Quickshell.screens;
    }

    PanelWindow {
        id: win

        required property ShellScreen modelData
        readonly property var cfg: Settings.data.dock
        readonly property string edge: ["bottom", "left", "right"].includes(cfg.position) ? cfg.position : "bottom"
        readonly property bool vertical: edge !== "bottom"
        readonly property int iconSize: cfg.iconSize
        readonly property real zoom: cfg.magnify ? Math.max(0, Math.min(1.5, cfg.zoom)) : 0
        readonly property int spacing: cfg.spacing
        readonly property int margin: cfg.margin
        readonly property int pad: 10
        readonly property int sepSize: 9
        readonly property int thickness: iconSize + pad * 2       // the dock body, across the edge
        readonly property int reach: margin + thickness + Math.ceil(iconSize * zoom) + 8
        readonly property int labelRoom: cfg.labels ? (vertical ? 220 : 34) : 0
        // revealed while hovered, and for a moment after the pointer leaves
        readonly property bool revealed: !cfg.autoHide || hover.hovered || hideDelay.running || menu.visible
        property real mouse: -1000                                // pointer along the dock (kept after it leaves)
        // 0 → 1 while the pointer is over the dock. Only this eases in and out;
        // icon sizes follow the pointer directly, since restarting an animation
        // on every pointer move (faster than frames) made the icons stutter.
        readonly property real hoverAmt: hoverAnim.v
        // animated value lives on an Item: Behaviors on the window itself crash Qt 6.12
        Item {
            id: hoverAnim
            property real v: hover.hovered && win.zoom > 0 ? 1 : 0
            Behavior on v { Anim { duration: Theme.durA("dock", 280); easing.bezierCurve: Theme.curves.emphasizedDecel } }
        }

        // App ids only, so the list (and its delegates) stays stable while
        // windows change titles. Pinned apps that aren't installed and aren't
        // running are skipped. "|" is the separator before unpinned running apps.
        readonly property var ids: {
            const running = [];
            for (const w of Niri.windows) {
                const id = w.app_id || "";
                if (id && !running.some(r => r.toLowerCase() === id.toLowerCase()))
                    running.push(id);
            }
            const pinned = cfg.pinned.filter(p => Apps.lookup(p) !== null || running.some(r => r.toLowerCase() === p.toLowerCase()));
            const extra = cfg.showRunning ? running.filter(id => !pinned.some(p => p.toLowerCase() === id.toLowerCase())) : [];
            const apps = pinned.concat(cfg.separator && pinned.length && extra.length ? ["|"] : [], extra);
            if (!panelStyle)
                return apps;
            // the panel style: a start button and the overview first, the clock after the pinned
            // apps, the weather at the end (Settings → Dock → Style)
            const has = k => (cfg.parts || {})[k] !== false;
            return [].concat(has("launcher") ? ["@launcher"] : [], has("overview") ? ["@overview"] : [], pinned,
                has("clock") ? ["@clock"] : [], extra.length ? (cfg.separator ? ["|"] : []).concat(extra) : [],
                has("weather") && Weather.ready ? ["@weather"] : []);
        }
        readonly property bool panelStyle: (cfg.style || "classic") === "panel"
        // how long an item is along the dock (pills are wider than icons)
        function itemLen(id) {
            if (id === "|")
                return sepSize;
            if (id === "@clock")
                return Math.round(iconSize * (Time.use24h ? 2 : 2.5));
            if (id === "@weather")
                return Math.round(iconSize * 2.1);
            return iconSize;
        }

        // where each item starts with nothing magnified. Magnification is measured
        // from these fixed spots: measuring from where icons are now made them push
        // each other around as they grew, and the dock wobbled under the pointer.
        readonly property var restStarts: {
            const out = [];
            let p = 0;
            for (const id of ids) {
                out.push(p);
                p += itemLen(id) + spacing;
            }
            return out;
        }
        readonly property real restLength: ids.length ? restStarts[ids.length - 1] + itemLen(ids[ids.length - 1]) : 0
        readonly property real restStart: ((vertical ? height : width) - restLength) / 2
        readonly property bool magnifying: hoverAmt > 0

        screen: modelData
        color: "transparent"
        anchors {
            bottom: true
            top: win.vertical
            left: win.edge !== "right"
            right: win.edge !== "left"
        }
        implicitWidth: vertical ? reach + labelRoom : 0
        implicitHeight: vertical ? 0 : reach + labelRoom
        // Normal (not Ignore) so the dock sits beside a bar on the same edge instead of on it
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: cfg.autoHide ? 0 : thickness + margin * 2
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "flamenco-dock"

        // Input region: the dock (with room for magnified icons) while revealed,
        // otherwise a thin strip along the whole edge that brings it back. A
        // fixed size, so it doesn't change under the pointer every frame.
        mask: Region { item: hitArea }

        Item {
            id: hitArea
            readonly property real across: win.revealed ? win.reach : Math.max(2, win.cfg.revealSize)
            readonly property real along: win.revealed ? win.restLength + win.pad * 2 + win.iconSize * 2 + 24 : (win.vertical ? win.height : win.width)
            width: win.vertical ? across : along
            height: win.vertical ? along : across
            // placed with x / y, not anchors: anchors switched by bindings (bottom → left…) can
            // briefly conflict when the dock moves to another edge, and Qt then drops one,
            // leaving things where the old edge put them
            x: win.edge === "left" ? 0 : win.edge === "right" ? parent.width - width : (parent.width - width) / 2
            y: win.edge === "bottom" ? parent.height - height : (parent.height - height) / 2
        }

        HoverHandler {
            id: hover
            onPointChanged: win.mouse = win.vertical ? point.position.y : point.position.x
            // the last position stays, so the icons shrink back from where the pointer was
            onHoveredChanged: if (!hovered) hideDelay.restart()
        }

        // right-click menu: the same one as the bar's window title
        WindowMenu {
            id: menu
            window: win
            side: win.edge
        }

        Timer {
            id: hideDelay
            interval: Math.max(0, win.cfg.hideDelay)
        }

        Rectangle {
            id: dock

            property real shift: win.revealed ? 0 : win.thickness + win.margin * 2
            Behavior on shift { Anim { duration: Theme.durA("dock", 450); easing.bezierCurve: Theme.curves.emphasizedDecel } }

            // x / y rather than anchors (see the hit area)
            x: win.edge === "left" ? win.margin : win.edge === "right" ? parent.width - width - win.margin : (parent.width - width) / 2
            y: win.edge === "bottom" ? parent.height - height - win.margin : (parent.height - height) / 2
            // after logging in it slides up from the edge (SessionFx.revealDock)
            readonly property real loginShift: (1 - SessionFx.revealDock) * (win.thickness + win.margin * 2 + 12)
            opacity: SessionFx.revealDock
            transform: Translate {
                x: win.edge === "left" ? -(dock.shift + dock.loginShift) : win.edge === "right" ? dock.shift + dock.loginShift : 0
                y: win.edge === "bottom" ? dock.shift + dock.loginShift : 0
            }
            visible: win.ids.length > 0
            width: win.vertical ? win.thickness : row.width + win.pad * 2
            height: win.vertical ? row.height + win.pad * 2 : win.thickness
            radius: Math.min(Theme.rXl * win.cfg.roundness, win.thickness / 2)
            color: Qt.rgba(Theme.panelBg.r, Theme.panelBg.g, Theme.panelBg.b, Theme.panelBg.a * win.cfg.opacity)
            border.width: win.cfg.border ? 1 : 0
            border.color: Theme.alpha(Theme.border, 0.6 * win.cfg.opacity)

            // the surface finish (gloss / chrome), under the content
            Finish { strength: win.cfg.opacity }

            // eases when apps come and go; while magnifying it follows the icons
            // directly, which already animate, so it never lags behind them
            Behavior on width { enabled: !win.vertical && !win.magnifying; Anim { easing.bezierCurve: Theme.curves.emphasizedDecel } }
            Behavior on height { enabled: win.vertical && !win.magnifying; Anim { easing.bezierCurve: Theme.curves.emphasizedDecel } }

            Grid {
                id: row
                columns: win.vertical ? 1 : Math.max(1, win.ids.length)
                spacing: win.spacing
                // icons grow away from the screen edge
                verticalItemAlignment: Grid.AlignBottom
                horizontalItemAlignment: win.edge === "right" ? Grid.AlignRight : Grid.AlignLeft
                // x / y rather than anchors (see the hit area): the icons sit on the dock's edge side
                x: win.edge === "left" ? win.pad : win.edge === "right" ? parent.width - width - win.pad : (parent.width - width) / 2
                y: win.edge === "bottom" ? parent.height - height - win.pad : (parent.height - height) / 2

                Repeater {
                    // ScriptModel diffs by value, so unchanged ids keep their delegates
                    model: ScriptModel { values: win.ids }

                    Item {
                        id: app
                        required property string modelData
                        required property int index
                        readonly property bool sep: modelData === "|"
                        // the panel style's pills: launcher, overview, clock, weather
                        readonly property string part: modelData.startsWith("@") ? modelData.slice(1) : ""
                        readonly property var entry: sep || part ? null : Apps.lookup(modelData)
                        readonly property bool pinned: win.cfg.pinned.includes(modelData)
                        readonly property var windows: sep || part ? [] : Niri.windows.filter(w => (w.app_id || "").toLowerCase() === modelData.toLowerCase())
                        readonly property bool focused: windows.some(w => w.id === Niri.activeWindowId)
                        readonly property real center: win.restStart + (win.restStarts[index] ?? 0) + win.iconSize / 2
                        readonly property real mag: !sep && !part && win.magnifying ? Math.max(0, 1 - Math.abs(win.mouse - center) / (win.iconSize * 2.2)) : 0
                        readonly property real size: win.iconSize * (1 + win.zoom * mag * win.hoverAmt)
                        property int cycle: 0

                        width: part ? (win.vertical ? win.iconSize : win.itemLen(modelData)) : sep ? (win.vertical ? win.iconSize : win.sepSize) : size
                        height: part ? (win.vertical ? win.itemLen(modelData) : win.iconSize) : sep ? (win.vertical ? win.sepSize : win.iconSize) : size

                        // ── a pill: the start button, the overview, the clock or the weather ──
                        Rectangle {
                            visible: app.part !== ""
                            anchors.fill: parent
                            radius: Math.min(width, height) / 2
                            color: partArea.containsMouse ? Theme.alpha(Theme.text, 0.14) : app.part === "launcher" ? "transparent" : Theme.alpha(Theme.text, 0.07)
                            Behavior on color { CAnim {} }
                            scale: partArea.pressed ? 0.92 : 1
                            Behavior on scale { Anim { easing.bezierCurve: Theme.curves.springFast } }
                            FIcon {
                                visible: app.part === "launcher" || app.part === "overview"
                                anchors.centerIn: parent
                                icon: app.part === "launcher" ? ((Settings.data.bar.startIcon || "apps") === "flamenco" ? "local_fire_department" : "apps") : "overview_key"
                                size: Math.round(win.iconSize * (app.part === "launcher" ? 0.62 : 0.46))
                                fill: 1
                                color: app.part === "launcher" ? Theme.accent : Theme.text
                            }
                            FText {
                                visible: app.part === "clock"
                                anchors.centerIn: parent
                                text: Qt.formatTime(Time.now, Time.use24h ? "HH:mm" : "h:mm AP")
                                font.pixelSize: Math.round(win.iconSize * 0.32)
                                font.weight: Font.Medium
                            }
                            Row {
                                visible: app.part === "weather"
                                anchors.centerIn: parent
                                spacing: 4
                                FIcon { anchors.verticalCenter: parent.verticalCenter; icon: Weather.icon; size: Math.round(win.iconSize * 0.42); color: Theme.text }
                                FText { anchors.verticalCenter: parent.verticalCenter; text: Math.round(Weather.temp) + "°"; font.pixelSize: Math.round(win.iconSize * 0.32); font.weight: Font.Medium }
                            }
                            MouseArea {
                                id: partArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    const s = win.modelData.name;
                                    if (app.part === "launcher")
                                        Panels.toggle("launcher", s);
                                    else if (app.part === "overview")
                                        Settings.data.overview.enabled ? Panels.toggle("overview", s) : Niri.action(Niri.hyprland ? "overview" : "toggle-overview");
                                    else if (app.part === "clock")
                                        Panels.openDashboard("calendar", s);
                                    else
                                        Panels.openDashboard("weather", s);
                                }
                            }
                        }
                        z: area.containsMouse ? 1 : 0
                        // no Behavior on the size: it follows the pointer every frame

                        // separator between pinned and other running apps
                        Rectangle {
                            visible: app.sep
                            anchors.centerIn: parent
                            width: win.vertical ? win.iconSize * 0.6 : 1
                            height: win.vertical ? 1 : win.iconSize * 0.6
                            color: Theme.alpha(Theme.text, 0.25)
                        }

                        AppIcon {
                            visible: !app.sep && !app.part
                            anchors.fill: parent
                            anchors.margins: 2
                            implicitSize: win.iconSize * (1 + win.zoom)
                            name: app.entry?.icon ?? app.modelData
                            scale: area.pressed ? 0.85 : 1
                            Behavior on scale { Anim { easing.bezierCurve: Theme.curves.springFast } }
                        }

                        // running indicator, on the screen-edge side
                        Rectangle {
                            readonly property bool dot: win.cfg.indicator === "dot"
                            readonly property real len: dot ? (app.windows.length > 0 ? 5 : 0) : app.focused ? 16 : app.windows.length > 0 ? 6 : 0
                            visible: !app.sep && !app.part && win.cfg.indicator !== "none"
                            x: win.edge === "left" ? -width - 2 : win.edge === "right" ? parent.width + 2 : (parent.width - width) / 2
                            y: win.edge === "bottom" ? parent.height + 2 : (parent.height - height) / 2
                            width: win.vertical ? (dot ? len : 4) : len
                            height: win.vertical ? len : (dot ? len : 4)
                            radius: Math.min(width, height) / 2
                            color: app.focused ? Theme.accent : Theme.textDim
                            Behavior on width { Anim { easing.bezierCurve: Theme.curves.spring } }
                            Behavior on height { Anim { easing.bezierCurve: Theme.curves.spring } }
                        }

                        // the app's name, on the side away from the edge
                        Rectangle {
                            visible: win.cfg.labels && !app.sep && !app.part && area.containsMouse
                            x: win.edge === "left" ? parent.width + 8 : win.edge === "right" ? -width - 8 : (parent.width - width) / 2
                            y: win.edge === "bottom" ? -height - 8 : (parent.height - height) / 2
                            width: label.implicitWidth + 20
                            height: label.implicitHeight + 10
                            radius: height / 2
                            color: Theme.panelBg
                            border.width: 1
                            border.color: Theme.alpha(Theme.border, 0.6)
                            FText {
                                id: label
                                anchors.centerIn: parent
                                text: app.entry?.name ?? app.modelData
                                font.pixelSize: Theme.fsSm
                            }
                        }

                        MouseArea {
                            id: area
                            enabled: !app.sep && !app.part
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => {
                                const wins = app.windows;
                                if (mouse.button === Qt.RightButton) {
                                    // the app's focused window, else its first; none: Open / Unpin
                                    const w = wins.find(x => x.id === Niri.activeWindowId) ?? wins[0] ?? null;
                                    const p = app.mapToItem(null, 0, 0);
                                    menu.open(w, Qt.rect(p.x, p.y, app.width, app.height), app.modelData);
                                } else if (mouse.button === Qt.MiddleButton || wins.length === 0) {
                                    Apps.launch(app.entry);
                                } else {
                                    app.cycle = (app.cycle + (app.focused ? 1 : 0)) % wins.length;
                                    Niri.focusWindow(wins[app.cycle].id);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
