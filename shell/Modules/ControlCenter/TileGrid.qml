import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.Commons
import qs.Services
import qs.Widgets

// Quick settings as a grid of pill tiles (the "Grid" style, Settings → Quick
// settings): you, the power buttons, sliders, and toggles in two columns. Press
// and hold anywhere to edit: remove a tile (−), make it half or full width (↔),
// drag it somewhere else, add widgets; ✓ keeps it, ✕ puts it back.
Item {
    id: root

    property string screenName: ""
    signal openDetail(string name)

    readonly property var qs: Settings.data.control
    // what each widget is, and how wide it starts (1 = half, 2 = the whole row)
    readonly property var catalog: ({
            profile: { label: "You", icon: "account_circle", w: 1 },
            actions: { label: "Settings, lock and power", icon: "power_settings_new", w: 1 },
            volume: { label: "Volume", icon: "volume_up", w: 1 },
            brightness: { label: "Brightness", icon: "brightness_6", w: 1 },
            miclevel: { label: "Microphone level", icon: "mic", w: 1 },
            wifi: { label: "Wi-Fi", icon: "wifi", w: 1 },
            bluetooth: { label: "Bluetooth", icon: "bluetooth", w: 1 },
            output: { label: "Sound output", icon: "speaker", w: 1 },
            input: { label: "Microphone", icon: "mic", w: 1 },
            vpn: { label: "VPN", icon: "vpn_key", w: 1 },
            disk: { label: "Disk usage", icon: "storage", w: 1 },
            picker: { label: "Color picker", icon: "colorize", w: 1 },
            caffeine: { label: "Keep awake", icon: "coffee", w: 1 },
            capture: { label: "Quick capture", icon: "screenshot_region", w: 1 },
            dnd: { label: "Do not disturb", icon: "do_not_disturb_on", w: 1 },
            power: { label: "Power profile", icon: "bolt", w: 1 },
            night: { label: "Night light", icon: "nightlight", w: 1 },
            dark: { label: "Dark mode", icon: "contrast", w: 1 },
            record: { label: "Screen recording", icon: "screen_record", w: 1 },
            widgets: { label: "Desktop widgets", icon: "widgets", w: 1 },
            wallpaper: { label: "Wallpaper", icon: "wallpaper", w: 1 },
            mixer: { label: "App mixer", icon: "tune", w: 1 },
            wellbeing: { label: "Screen time", icon: "hourglass_bottom", w: 1 },
            media: { label: "Now playing", icon: "music_note", w: 2 }
        })
    readonly property var defaults: ["profile", "actions", "volume", "brightness", "wifi", "bluetooth", "output", "input", "vpn", "disk",
        "picker", "caffeine", "capture", "dnd", "power", "night", "dark", "media"].map(id => ({ id, w: catalog[id].w }))
    readonly property var saved: (qs.grid || []).filter(t => catalog[t.id])
    readonly property var layoutList: saved.length ? saved : defaults

    // ── editing ──
    property bool editing: false
    property var draft: []
    readonly property var shown: editing ? draft : layoutList.filter(t => t.id !== "media" || Media.active)
    property bool adding: false
    function startEdit() {
        if (editing)
            return;
        draft = layoutList.map(t => ({ id: t.id, w: t.w }));
        editing = true;
        adding = false;
    }
    function finish(keep) {
        if (keep)
            qs.grid = draft.slice();
        editing = false;
        adding = false;
    }
    function removeAt(i) {
        draft = draft.filter((_, j) => j !== i);
    }
    function resizeAt(i) {
        draft = draft.map((t, j) => j === i ? { id: t.id, w: t.w === 2 ? 1 : 2 } : t);
    }
    function moveTo(from, to) {
        if (from === to || from < 0 || to < 0)
            return;
        const l = draft.slice();
        l.splice(to, 0, l.splice(from, 1)[0]);
        draft = l;
    }
    function add(id) {
        draft = draft.concat([{ id, w: catalog[id].w }]);
        adding = false;
    }
    readonly property var missing: Object.keys(catalog).filter(id => !draft.some(t => t.id === id))

    // ── layout: two columns, a full-width tile starts a row of its own ──
    readonly property int gap: Theme.gap
    readonly property int tileH: Math.round(62 * Theme.scale)
    readonly property real colW: (width - gap) / 2
    readonly property var slots: {
        const out = [];
        let row = 0, col = 0;
        for (const t of shown) {
            if (t.w === 2 && col === 1) {
                row++;
                col = 0;
            }
            out.push({ x: col * (colW + gap), y: row * (tileH + gap), w: t.w === 2 ? width : colW });
            if (t.w === 2 || col === 1) {
                row++;
                col = 0;
            } else {
                col = 1;
            }
        }
        return { list: out, rows: col === 1 ? row + 1 : row };
    }
    implicitHeight: slots.rows * (tileH + gap) - (slots.rows ? gap : 0) + (editing ? tools.height + Theme.sp3 : 0)

    // the slot nearest a point (where a dragged tile lands)
    function slotAt(cx, cy) {
        let best = -1, d = 1e9;
        slots.list.forEach((s, i) => {
            const dd = Math.hypot(s.x + s.w / 2 - cx, s.y + tileH / 2 - cy);
            if (dd < d) {
                d = dd;
                best = i;
            }
        });
        return best;
    }

    // press and hold anywhere: edit
    TapHandler {
        enabled: !root.editing
        longPressThreshold: 0.6
        onLongPressed: root.startEdit()
    }

    Repeater {
        model: root.shown
        delegate: Item {
            id: cell
            required property var modelData
            required property int index
            readonly property var slot: root.slots.list[index] ?? { x: 0, y: 0, w: root.colW }
            property bool dragging: drag.active
            x: dragging ? x : slot.x
            y: dragging ? y : slot.y
            z: dragging ? 10 : 0
            width: slot.w
            height: root.tileH
            Behavior on x { enabled: !cell.dragging; Anim { duration: Theme.durMed; easing.bezierCurve: Theme.curves.emphasizedDecel } }
            Behavior on y { enabled: !cell.dragging; Anim { duration: Theme.durMed; easing.bezierCurve: Theme.curves.emphasizedDecel } }
            Behavior on width { Anim { duration: Theme.durMed; easing.bezierCurve: Theme.curves.emphasizedDecel } }
            scale: dragging ? 1.04 : 1
            Behavior on scale { Anim { duration: Theme.durShort } }

            Loader {
                anchors.fill: parent
                sourceComponent: ({
                        profile: profileC, actions: actionsC, volume: volumeC, brightness: brightnessC, miclevel: micLevelC, wifi: wifiC,
                        bluetooth: btC, output: outputC, input: inputC, vpn: vpnC, disk: diskC, picker: pickerC, caffeine: caffeineC,
                        capture: captureC, dnd: dndC, power: powerC, night: nightC, dark: darkC, record: recordC, widgets: widgetsC,
                        wallpaper: wallpaperC, mixer: mixerC, wellbeing: wellbeingC, media: mediaC
                    })[cell.modelData.id] ?? null
                // nothing works while arranging
                enabled: !root.editing
            }

            // ── edit chrome: a frame, remove, resize; drag to move ──
            Rectangle {
                visible: root.editing
                anchors.fill: parent
                radius: height / 2
                color: Theme.alpha(Theme.bg, 0.25)
                border.width: 2
                border.color: Theme.alpha(Theme.accent, cell.dragging ? 1 : 0.6)
                DragHandler {
                    id: drag
                    enabled: root.editing
                    target: cell
                    onActiveChanged: if (!active) root.moveTo(cell.index, root.slotAt(cell.x + cell.width / 2, cell.y + cell.height / 2))
                }
            }
            Rectangle {
                visible: root.editing
                x: 6
                y: -6
                width: 22
                height: 22
                radius: 11
                color: Theme.error
                FIcon { anchors.centerIn: parent; icon: "remove"; size: 16; color: "#ffffff" }
                MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: root.removeAt(cell.index) }
            }
            Rectangle {
                visible: root.editing
                anchors.right: parent.right
                anchors.rightMargin: 10
                y: -6
                width: 30
                height: 22
                radius: 11
                color: Theme.accent
                FIcon { anchors.centerIn: parent; icon: cell.modelData.w === 2 ? "close_fullscreen" : "open_in_full"; size: 14; color: Theme.onAccent }
                MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: root.resizeAt(cell.index) }
            }
        }
    }

    // ── the edit toolbar ──
    ColumnLayout {
        id: tools
        visible: root.editing
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        spacing: Theme.sp2

        // add: the widgets not on the grid
        Flow {
            Layout.fillWidth: true
            visible: root.adding
            spacing: 6
            Repeater {
                model: root.adding ? root.missing : []
                Rectangle {
                    required property string modelData
                    width: addRow.implicitWidth + 20
                    height: 32
                    radius: 16
                    color: Theme.alpha(Theme.accent, 0.16)
                    Row {
                        id: addRow
                        anchors.centerIn: parent
                        spacing: 5
                        FIcon { anchors.verticalCenter: parent.verticalCenter; icon: root.catalog[parent.parent.modelData].icon; size: 16; color: Theme.accent }
                        FText { anchors.verticalCenter: parent.verticalCenter; text: root.catalog[parent.parent.modelData].label; font.pixelSize: Theme.fsSm }
                    }
                    StateLayer { radius: 16; onClicked: root.add(parent.modelData) }
                }
            }
            FText { visible: root.missing.length === 0; text: "Everything is on the grid"; dim: true }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.sp2
            FButton {
                text: "Add widget"
                icon: "add"
                variant: root.adding ? "filled" : "tonal"
                onClicked: root.adding = !root.adding
            }
            FIconButton {
                icon: "restart_alt"
                size: 36
                onClicked: root.draft = root.defaults.map(t => ({ id: t.id, w: t.w }))
            }
            Item { Layout.fillWidth: true }
            FIconButton { icon: "close"; size: 38; flat: false; onClicked: root.finish(false) }
            FIconButton { icon: "check"; size: 38; active: true; onClicked: root.finish(true) }
        }
    }

    // ───────────────────────────── tiles ─────────────────────────────

    // a pill: an icon in a circle, a title and a line under it; tinted while on
    component Pill: Rectangle {
        id: pill
        property string icon
        property string title
        property string subtitle
        property bool on: false
        property bool hasDetail: false
        signal clicked
        signal detail
        radius: height / 2
        color: on ? Theme.alpha(Theme.accent, 0.3) : Theme.alpha(Theme.text, 0.06)
        border.width: 1
        border.color: on ? Theme.alpha(Theme.accent, 0.55) : Theme.alpha(Theme.text, 0.05)
        Behavior on color { CAnim {} }
        StateLayer {
            radius: pill.radius
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => mouse.button === Qt.RightButton && pill.hasDetail ? pill.detail() : pill.clicked()
            onPressAndHold: root.startEdit()
        }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: pill.hasDetail ? 4 : 14
            spacing: 10
            Rectangle {
                Layout.preferredWidth: pill.height - 16
                Layout.preferredHeight: pill.height - 16
                radius: width / 2
                color: pill.on ? Theme.accent : Theme.alpha(Theme.text, 0.08)
                Behavior on color { CAnim {} }
                FIcon { anchors.centerIn: parent; icon: pill.icon; size: 20; fill: pill.on ? 1 : 0; color: pill.on ? Theme.onAccent : Theme.text }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                FText { Layout.fillWidth: true; text: pill.title; font.weight: Font.DemiBold; elide: Text.ElideRight }
                FText { Layout.fillWidth: true; visible: text !== ""; text: pill.subtitle; dim: true; font.pixelSize: Theme.fsXs; elide: Text.ElideRight }
            }
            FIconButton {
                visible: pill.hasDetail
                icon: "chevron_right"
                size: 32
                iconSize: 18
                onClicked: pill.detail()
            }
        }
    }

    // a slider tile: the whole pill is the slider
    component SliderTile: FPillSlider {}

    Component {
        id: profileC
        Rectangle {
            radius: height / 2
            color: Theme.alpha(Theme.text, 0.06)
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 12
                spacing: 10
                Avatar {
                    size: root.tileH - 12
                    path: Settings.data.general.avatar ? Paths.expand(Settings.data.general.avatar) : (Users.self?.avatar ?? "")
                    name: Users.fullName
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    FText { Layout.fillWidth: true; text: Users.me + (SystemStats.hostname ? " @ " + SystemStats.hostname : ""); font.weight: Font.DemiBold; elide: Text.ElideRight }
                    FText { Layout.fillWidth: true; text: (Niri.hyprland ? "Hyprland" : "niri") + "  ·  up " + SystemStats.uptimeText; dim: true; font.pixelSize: Theme.fsXs; elide: Text.ElideRight }
                }
            }
            StateLayer { radius: parent.radius; onClicked: Panels.openSettings("users"); onPressAndHold: root.startEdit() }
        }
    }
    Component {
        id: actionsC
        Rectangle {
            radius: height / 2
            color: Theme.alpha(Theme.text, 0.06)
            RowLayout {
                anchors.centerIn: parent
                spacing: 6
                FIconButton { icon: "settings"; size: root.tileH - 18; flat: false; onClicked: Panels.openSettings("") }
                FIconButton {
                    icon: "lock"
                    size: root.tileH - 18
                    flat: false
                    onClicked: {
                        Panels.close();
                        Quickshell.execDetached([Paths.bin, "lock"]);
                    }
                }
                FIconButton { icon: "power_settings_new"; size: root.tileH - 18; flat: false; iconColor: Theme.error; onClicked: Panels.open("power", Panels.screen) }
            }
        }
    }
    Component {
        id: volumeC
        SliderTile {
            icon: Audio.icon
            value: Audio.volume
            muted: Audio.muted
            onMoved: v => Audio.setVolume(v)
            onIconClicked: Audio.toggleMute()
        }
    }
    Component {
        id: brightnessC
        SliderTile {
            icon: "brightness_6"
            value: Brightness.value
            from: Theme.accent
            to: Theme.warning
            onMoved: v => Brightness.set(v)
        }
    }
    Component {
        id: micLevelC
        SliderTile {
            icon: Audio.micMuted ? "mic_off" : "mic"
            value: Audio.micVolume
            muted: Audio.micMuted
            from: Theme.warning
            to: Theme.accent
            onMoved: v => Audio.setMicVolume(v)
            onIconClicked: Audio.toggleMicMute()
        }
    }
    Component {
        id: wifiC
        Pill {
            icon: Network.icon
            title: Network.ssid || (Network.ethernet ? "Ethernet" : "Wi-Fi")
            subtitle: Network.ethernet ? "Wired" : Network.ssid ? Network.signal + "%" : Network.wifiEnabled ? "Not connected" : "Off"
            on: Network.wifiEnabled || Network.ethernet
            hasDetail: true
            onClicked: Network.setWifi(!Network.wifiEnabled)
            onDetail: {
                root.openDetail("wifi");
                Network.scan(true);
            }
        }
    }
    Component {
        id: btC
        Pill {
            icon: BluetoothState.icon
            title: BluetoothState.enabled ? "Enabled" : "Bluetooth"
            subtitle: BluetoothState.label
            on: BluetoothState.enabled
            hasDetail: BluetoothState.available
            onClicked: BluetoothState.setEnabled(!BluetoothState.enabled)
            onDetail: root.openDetail("bluetooth")
        }
    }
    Component {
        id: outputC
        Pill {
            icon: Audio.icon
            title: Audio.sink ? Audio.nodeName(Audio.sink) : "No output"
            subtitle: Audio.muted ? "Muted" : Math.round(Audio.volume * 100) + "%"
            on: !Audio.muted
            hasDetail: true
            onClicked: Audio.toggleMute()
            onDetail: root.openDetail("audio")
        }
    }
    Component {
        id: inputC
        Pill {
            icon: Audio.micMuted ? "mic_off" : "mic"
            title: Audio.source ? Audio.nodeName(Audio.source) : "No microphone"
            subtitle: Audio.micMuted ? "Muted" : Math.round(Audio.micVolume * 100) + "%"
            on: !Audio.micMuted && Audio.source !== null
            hasDetail: true
            onClicked: Audio.toggleMicMute()
            onDetail: root.openDetail("mic")
        }
    }
    Component {
        id: vpnC
        Pill {
            icon: Network.vpnActive ? "vpn_lock" : "vpn_key"
            title: Network.vpnActive ? Network.activeVpns.map(v => v.name).join(", ") : "VPN"
            subtitle: Network.vpnActive ? "Connected" : Network.vpns.length ? "Off" : "Not set up"
            on: Network.vpnActive
            hasDetail: true
            onClicked: {
                if (Network.vpnActive)
                    Network.activeVpns.forEach(v => Network.setVpn(v.name, false));
                else if (Network.vpns.length === 1)
                    Network.setVpn(Network.vpns[0].name, true);
                else
                    root.openDetail("vpn");
            }
            onDetail: root.openDetail("vpn")
        }
    }
    Component {
        id: diskC
        Pill {
            id: dp
            property string usage: ""
            icon: "storage"
            title: "Disk usage"
            subtitle: usage || "…"
            onClicked: Panels.toggle("performance", root.screenName)
            Process {
                running: true
                command: ["df", "-B1", "--output=size,used", Paths.home]
                stdout: StdioCollector {
                    onStreamFinished: {
                        const f = text.trim().split("\n").pop().trim().split(/\s+/).map(Number);
                        if (f.length === 2 && f[0] > 0)
                            dp.usage = SystemStats.formatBytes(f[1]).replace(" ", "") + " / " + SystemStats.formatBytes(f[0]).replace(" ", "") + " (" + Math.round(f[1] / f[0] * 100) + "%)";
                    }
                }
            }
        }
    }
    Component {
        id: pickerC
        Pill {
            icon: "colorize"
            title: "Color picker"
            subtitle: "Choose a color"
            onClicked: {
                Panels.close();
                Quickshell.execDetached(["sh", "-c", 'sleep 0.35; exec "$1" pick-color', "sh", Paths.bin]);
            }
        }
    }
    Component {
        id: caffeineC
        Pill {
            icon: "coffee"
            title: "Keep awake"
            subtitle: Toggles.caffeine ? "On" : "Off"
            on: Toggles.caffeine
            onClicked: Toggles.caffeine = !Toggles.caffeine
        }
    }
    Component {
        id: captureC
        Pill {
            icon: "screenshot_region"
            title: "Quick capture"
            subtitle: "An area of the screen"
            onClicked: {
                Panels.close();
                Screenshot.fromSettings("region");
            }
        }
    }
    Component {
        id: dndC
        Pill {
            icon: "do_not_disturb_on"
            title: "Do not disturb"
            subtitle: Notifs.dnd ? "On" : "Off"
            on: Notifs.dnd
            onClicked: Notifs.setDnd(!Notifs.dnd)
        }
    }
    Component {
        id: powerC
        Pill {
            icon: Power.profileIcon
            title: "Power profile"
            subtitle: Power.profileName
            on: Power.profileId !== "balanced"
            hasDetail: true
            onClicked: Power.cycleProfile()
            onDetail: root.openDetail("power")
        }
    }
    Component {
        id: nightC
        Pill {
            icon: "nightlight"
            title: "Night light"
            subtitle: Toggles.status
            on: Toggles.nightLight
            hasDetail: true
            onClicked: Toggles.setNightLight(!Toggles.nightLight)
            onDetail: root.openDetail("night")
        }
    }
    Component {
        id: darkC
        Pill {
            icon: "contrast"
            title: "Dark mode"
            subtitle: Theme.dark ? "On" : "Off"
            on: Theme.dark
            onClicked: Settings.data.appearance.mode = Theme.dark ? "light" : "dark"
        }
    }
    Component {
        id: recordC
        Pill {
            icon: Recorder.recording ? "stop_circle" : "screen_record"
            title: Recorder.recording ? "Stop recording" : "Record screen"
            subtitle: Recorder.recording ? Recorder.clock : "This screen"
            on: Recorder.recording
            onClicked: {
                Panels.close();
                Recorder.toggle("screen", root.screenName);
            }
        }
    }
    Component {
        id: widgetsC
        Pill {
            icon: "widgets"
            title: "Desktop widgets"
            subtitle: Settings.data.desktop.enabled ? (Settings.data.desktop.widgets.length ? Settings.data.desktop.widgets.length + " on the desktop" : "Add some") : "Off"
            on: Settings.data.desktop.enabled && Settings.data.desktop.widgets.length > 0
            onClicked: {
                Settings.data.desktop.enabled = true;
                Panels.editWidgets(root.screenName);
            }
        }
    }
    Component {
        id: wallpaperC
        Pill {
            icon: "wallpaper"
            title: "Wallpaper"
            subtitle: Paths.fileName(Wallpapers.current) || "None"
            onClicked: Panels.toggle("wallpaper", root.screenName)
        }
    }
    Component {
        id: mixerC
        Pill {
            icon: "tune"
            title: "App mixer"
            subtitle: Audio.streamGroups.length ? Audio.streamGroups.length + " playing" : "Nothing playing"
            on: Audio.streamGroups.length > 0
            onClicked: root.openDetail("mixer")
        }
    }
    Component {
        id: wellbeingC
        Pill {
            icon: "hourglass_bottom"
            title: "Screen time"
            subtitle: Wellbeing.enabled ? Wellbeing.fmt(Wellbeing.todayTotal) + " today" : "Off"
            on: Wellbeing.enabled
            onClicked: Panels.openDashboard("wellbeing", root.screenName)
        }
    }
    Component {
        id: mediaC
        Rectangle {
            radius: height / 2
            color: Theme.alpha(Theme.text, 0.06)
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 10
                spacing: 10
                ClippingRectangle {
                    Layout.preferredWidth: root.tileH - 12
                    Layout.preferredHeight: root.tileH - 12
                    radius: width / 2
                    color: Theme.alpha(Theme.accent, 0.2)
                    Image { anchors.fill: parent; source: Media.art; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize: Qt.size(96, 96) }
                    FIcon { anchors.centerIn: parent; visible: Media.art === ""; icon: "music_note"; color: Theme.accent }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    FText { Layout.fillWidth: true; text: Media.title || "Nothing playing"; font.weight: Font.DemiBold; elide: Text.ElideRight }
                    FText { Layout.fillWidth: true; text: Media.artist; dim: true; font.pixelSize: Theme.fsXs; elide: Text.ElideRight }
                }
                FIconButton { icon: "skip_previous"; size: 32; onClicked: Media.previous() }
                FIconButton { icon: Media.playing ? "pause" : "play_arrow"; size: 36; active: true; onClicked: Media.toggle() }
                FIconButton { icon: "skip_next"; size: 32; onClicked: Media.next() }
            }
        }
    }
}
