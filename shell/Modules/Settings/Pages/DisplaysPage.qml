import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: "Displays"
    subtitle: "Drag screens to arrange them, then pick resolution, refresh rate, scale and orientation. Changes apply live and revert after 15 seconds unless you keep them."

    property var draft: []
    property string selected: ""
    readonly property var sel: draft.find(o => o.name === selected) ?? null
    readonly property var selInfo: Displays.outputs.find(o => o.name === selected) ?? null
    readonly property bool dirty: JSON.stringify(draft) !== JSON.stringify(Displays.specFrom(Displays.outputs))

    function reset() {
        draft = Displays.specFrom(Displays.outputs);
        if (!draft.some(o => o.name === selected))
            selected = draft.find(o => o.enabled)?.name ?? draft[0]?.name ?? "";
    }

    function update(name, patch) {
        draft = draft.map(o => o.name === name ? Object.assign({}, o, patch) : o);
    }

    // logical (scaled, rotated) size in niri's layout coordinates
    function logicalSize(o) {
        if (!o || !o.mode)
            return { w: 0, h: 0 };
        const rot = ["90", "270", "flipped-90", "flipped-270"].includes(o.transform);
        return { w: Math.round((rot ? o.mode.h : o.mode.w) / o.scale), h: Math.round((rot ? o.mode.w : o.mode.h) / o.scale) };
    }

    // Drop a display at (nx, ny), snapping its edges to neighbours.
    function drop(name, nx, ny) {
        const me = draft.find(o => o.name === name);
        const s = logicalSize(me);
        const snap = 80;
        let bx = nx, by = ny, bdx = snap, bdy = snap;
        for (const o of draft) {
            if (o.name === name || !o.enabled || !o.mode)
                continue;
            const t = logicalSize(o);
            for (const cx of [o.x + t.w, o.x - s.w, o.x, o.x + t.w - s.w])
                if (Math.abs(cx - nx) < bdx) { bdx = Math.abs(cx - nx); bx = cx; }
            for (const cy of [o.y + t.h, o.y - s.h, o.y, o.y + t.h - s.h])
                if (Math.abs(cy - ny) < bdy) { bdy = Math.abs(cy - ny); by = cy; }
        }
        update(name, { x: Math.round(bx), y: Math.round(by) });
        // keep the layout anchored at 0,0
        const on = draft.filter(o => o.enabled && o.mode);
        const mx = Math.min(...on.map(o => o.x)), my = Math.min(...on.map(o => o.y));
        if (mx !== 0 || my !== 0)
            draft = draft.map(o => Object.assign({}, o, { x: o.x - mx, y: o.y - my }));
    }

    Component.onCompleted: {
        reset();
        Displays.refresh();
    }

    Connections {
        target: Displays
        function onOutputsChanged() {
            if (!Displays.confirming)
                page.reset();
        }
    }

    // ── arrangement ──
    Group {
        title: "Arrangement"

        Item {
            id: canvas
            Layout.fillWidth: true
            Layout.margins: 12
            implicitHeight: 300

            readonly property var shown: page.draft.filter(o => o.enabled && o.mode)
            readonly property var bbox: {
                if (shown.length === 0)
                    return { x: 0, y: 0, w: 1, h: 1 };
                let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity;
                for (const o of shown) {
                    const s = page.logicalSize(o);
                    x0 = Math.min(x0, o.x); y0 = Math.min(y0, o.y);
                    x1 = Math.max(x1, o.x + s.w); y1 = Math.max(y1, o.y + s.h);
                }
                return { x: x0, y: y0, w: x1 - x0, h: y1 - y0 };
            }
            readonly property real k: Math.min((width - 60) / bbox.w, (height - 60) / bbox.h)
            readonly property real ox: (width - bbox.w * k) / 2 - bbox.x * k
            readonly property real oy: (height - bbox.h * k) / 2 - bbox.y * k

            Rectangle {
                anchors.fill: parent
                radius: Theme.rMd
                color: Theme.bg
            }

            FText {
                anchors.centerIn: parent
                visible: canvas.shown.length === 0
                text: Displays.loading ? "Reading displays from niri…" : "No displays reported by niri"
                dim: true
            }

            Repeater {
                model: canvas.shown

                Rectangle {
                    id: mon
                    required property var modelData
                    readonly property var size: page.logicalSize(modelData)
                    readonly property bool isSel: modelData.name === page.selected
                    property real dx: 0
                    property real dy: 0

                    x: canvas.ox + modelData.x * canvas.k + dx
                    y: canvas.oy + modelData.y * canvas.k + dy
                    width: size.w * canvas.k
                    height: size.h * canvas.k
                    radius: Theme.rSm
                    color: isSel ? Theme.alpha(Theme.accent, 0.25) : Theme.surfaceHighest
                    border.width: isSel ? 2 : 1
                    border.color: isSel ? Theme.accent : Theme.border
                    z: drag.active ? 2 : isSel ? 1 : 0
                    scale: drag.active ? 1.03 : 1

                    Behavior on color { CAnim {} }
                    Behavior on scale { Anim { duration: Theme.durShort } }

                    Column {
                        anchors.centerIn: parent
                        spacing: 2
                        FText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: mon.modelData.name
                            font.weight: Font.Bold
                            color: mon.isSel ? Theme.accent : Theme.text
                        }
                        FText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: mon.modelData.mode.w + "×" + mon.modelData.mode.h
                            dim: true
                            font.pixelSize: Theme.fsXs
                        }
                    }

                    DragHandler {
                        id: drag
                        target: null
                        cursorShape: Qt.ClosedHandCursor
                        onActiveTranslationChanged: {
                            mon.dx = activeTranslation.x;
                            mon.dy = activeTranslation.y;
                        }
                        onActiveChanged: {
                            if (active) {
                                page.selected = mon.modelData.name;
                                return;
                            }
                            const nx = mon.modelData.x + mon.dx / canvas.k;
                            const ny = mon.modelData.y + mon.dy / canvas.k;
                            mon.dx = 0;
                            mon.dy = 0;
                            page.drop(mon.modelData.name, nx, ny);
                        }
                    }
                    TapHandler {
                        onTapped: page.selected = mon.modelData.name
                    }
                    HoverHandler { cursorShape: Qt.OpenHandCursor }
                }
            }
        }

        // disabled displays aren't on the canvas; list them so they can be selected
        Flow {
            Layout.fillWidth: true
            Layout.leftMargin: 12
            Layout.bottomMargin: 8
            spacing: 6
            visible: page.draft.some(o => !o.enabled)
            Repeater {
                model: page.draft.filter(o => !o.enabled)
                FButton {
                    required property var modelData
                    text: modelData.name + " (off)"
                    icon: "desktop_access_disabled"
                    variant: page.selected === modelData.name ? "filled" : "tonal"
                    implicitHeight: 30
                    onClicked: page.selected = modelData.name
                }
            }
        }
    }

    // ── selected display ──
    Group {
        visible: page.sel !== null
        title: page.sel ? page.sel.name + (page.selInfo && (page.selInfo.make + page.selInfo.model) ? " · " + (page.selInfo.make + " " + page.selInfo.model).trim() : "") : ""

        SettingRow {
            title: "Enabled"
            subtitle: page.draft.filter(o => o.enabled).length <= 1 && page.sel?.enabled ? "The last enabled display can't be turned off" : ""
            icon: "power_settings_new"
            FSwitch {
                checked: page.sel?.enabled ?? false
                onToggled: c => {
                    if (!c && page.draft.filter(o => o.enabled).length <= 1)
                        return;
                    page.update(page.selected, { enabled: c });
                }
            }
        }

        SettingRow {
            visible: page.sel?.enabled ?? false
            title: "Resolution"
            icon: "aspect_ratio"
            FDropdown {
                implicitWidth: 260
                readonly property var sizes: {
                    const seen = {}, out = [];
                    for (const m of page.selInfo?.modes ?? []) {
                        const key = m.w + "x" + m.h;
                        if (seen[key])
                            continue;
                        seen[key] = true;
                        out.push({ value: key, label: m.w + " × " + m.h + (m.preferred ? "  (native)" : ""), area: m.w * m.h });
                    }
                    return out.sort((a, b) => b.area - a.area);
                }
                options: sizes
                current: page.sel?.mode ? page.sel.mode.w + "x" + page.sel.mode.h : ""
                onSelected: v => {
                    // keep the closest refresh rate at the new resolution
                    const [w, h] = v.split("x").map(Number);
                    const cands = page.selInfo.modes.filter(m => m.w === w && m.h === h);
                    const r = page.sel.mode?.r ?? 60000;
                    cands.sort((a, b) => Math.abs(a.r - r) - Math.abs(b.r - r));
                    page.update(page.selected, { mode: cands[0] });
                }
            }
        }

        SettingRow {
            visible: page.sel?.enabled ?? false
            title: "Refresh rate"
            icon: "speed"
            FDropdown {
                implicitWidth: 260
                options: (page.selInfo?.modes ?? []).filter(m => page.sel?.mode && m.w === page.sel.mode.w && m.h === page.sel.mode.h).sort((a, b) => b.r - a.r).map(m => ({ value: m.r, label: (m.r / 1000).toFixed(2) + " Hz" + (m.preferred ? "  (preferred)" : "") }))
                current: page.sel?.mode?.r ?? 0
                onSelected: v => {
                    const m = page.selInfo.modes.find(x => x.w === page.sel.mode.w && x.h === page.sel.mode.h && x.r === v);
                    if (m)
                        page.update(page.selected, { mode: m });
                }
            }
        }

        SettingRow {
            visible: page.sel?.enabled ?? false
            title: "Scale"
            subtitle: page.sel ? "Looks like " + page.logicalSize(page.sel).w + " × " + page.logicalSize(page.sel).h : ""
            icon: "zoom_in"
            FDropdown {
                implicitWidth: 260
                options: [0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 2.25, 2.5, 3].map(v => ({ value: v, label: Math.round(v * 100) + "%" }))
                current: page.sel?.scale ?? 1
                onSelected: v => page.update(page.selected, { scale: v })
            }
        }

        SettingRow {
            id: orient
            visible: page.sel?.enabled ?? false
            title: "Orientation"
            icon: "screen_rotation"
            readonly property string tf: page.sel?.transform ?? "normal"
            readonly property bool flipped: tf.startsWith("flipped")
            readonly property string rot: tf === "normal" || tf === "flipped" ? "0" : tf.replace("flipped-", "")

            function setTf(rot, flipped) {
                const t = flipped ? (rot === "0" ? "flipped" : "flipped-" + rot) : (rot === "0" ? "normal" : rot);
                page.update(page.selected, { transform: t });
            }

            Row {
                spacing: 10
                FSegmented {
                    implicitWidth: 300
                    options: [{ value: "0", label: "Normal" }, { value: "90", label: "90°" }, { value: "180", label: "180°" }, { value: "270", label: "270°" }]
                    current: orient.rot
                    onSelected: v => orient.setTf(v, orient.flipped)
                }
                FIconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "flip"
                    flat: false
                    active: orient.flipped
                    onClicked: orient.setTf(orient.rot, !orient.flipped)
                }
            }
        }

        SettingRow {
            visible: (page.sel?.enabled ?? false) && (page.selInfo?.vrrSupported ?? false)
            title: "Variable refresh rate"
            subtitle: "Adaptive sync (FreeSync / G-Sync compatible)"
            icon: "motion_blur"
            FSwitch {
                checked: page.sel?.vrr ?? false
                onToggled: c => page.update(page.selected, { vrr: c })
            }
        }

        SettingRow {
            visible: page.sel?.enabled ?? false
            title: "Position"
            subtitle: "Drag the display above, or it snaps to its neighbours"
            icon: "open_with"
            FText {
                text: page.sel ? page.sel.x + ", " + page.sel.y : ""
                mono: true
                dim: true
            }
        }
    }

    // ── actions ──
    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.sp3

        FButton {
            text: "Apply"
            icon: "check"
            disabled: !page.dirty || Displays.busy || Displays.confirming
            onClicked: Displays.tryApply(page.draft)
        }
        FButton {
            text: "Reset"
            icon: "undo"
            variant: "outlined"
            disabled: !page.dirty
            onClicked: page.reset()
        }
        FButton {
            text: "Identify"
            icon: "badge"
            variant: "tonal"
            onClicked: Displays.identify()
        }
        FIconButton {
            icon: "refresh"
            onClicked: Displays.refresh()
        }
        FText {
            Layout.fillWidth: true
            text: Displays.status
            dim: true
            elide: Text.ElideRight
        }
    }

    Group {
        title: "Safety"
        SwitchRow {
            title: "Never leave every screen off"
            subtitle: "If the laptop screen is switched off and no other display is connected (e.g. at login), turn it back on. It goes off again when the external display returns."
            icon: "screenshot_monitor"
            target: Settings.data.displays
            key: "fallback"
            onEdited: if (Settings.data.displays.fallback) Displays.checkFallback()
        }
    }

    Group {
        title: "Brightness (external monitors)"
        SettingRow {
            title: !Brightness.ddcInstalled ? "ddcutil isn't installed"
                : Brightness.ddcLoading ? "Looking for monitors…"
                : Brightness.ddc.length ? Brightness.ddc.length + (Brightness.ddc.length === 1 ? " monitor" : " monitors") + " with brightness control"
                : "No monitor answered"
            subtitle: !Brightness.ddcInstalled ? "External monitors' brightness is set over the cable (DDC/CI) with ddcutil."
                : Brightness.ddcError ? Brightness.ddcError
                : Brightness.ddc.length ? "Also in quick settings. On a desktop, the brightness keys change the focused monitor."
                : "Turn on DDC/CI in the monitor's own menu, and check you can use /dev/i2c-* (the i2c group, module i2c-dev)."
            icon: "desktop_windows"
            Row {
                spacing: 8
                FButton {
                    visible: !Brightness.ddcInstalled
                    text: "Install"
                    variant: "tonal"
                    onClicked: Quickshell.execDetached(Paths.termHold("sudo pacman -S --needed ddcutil && sudo usermod -aG i2c \"$USER\" && echo i2c-dev | sudo tee /etc/modules-load.d/i2c-dev.conf && sudo modprobe i2c-dev && echo 'Log out and back in for the i2c group.'"))
                }
                FIconButton {
                    icon: "refresh"
                    size: 32
                    onClicked: Brightness.refreshDdc()
                }
            }
        }
        Repeater {
            model: Brightness.ddc
            SliderRow {
                required property var modelData
                readonly property var proxy: ({ v: modelData.value / modelData.max })
                title: modelData.connector + (modelData.name ? " · " + modelData.name : "")
                icon: "brightness_6"
                target: proxy
                key: "v"
                from: 0
                to: 1
                stepSize: 0.01
                factor: 100
                suffix: "%"
                onEdited: Brightness.setDdc(modelData.bus, proxy.v)
            }
        }
    }
}
