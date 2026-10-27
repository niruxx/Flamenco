import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

// One window rule (Settings → Windows → Window rules): which windows (an app, and
// optionally a title), and how they open. Folded to a summary line; click to edit.
Rectangle {
    id: root
    required property var rule
    required property int index
    property bool open: false
    readonly property var r: rule
    readonly property var outputs: {
        const out = [];
        for (const w of Niri.workspaces)
            if (w.output && !out.includes(w.output))
                out.push(w.output);
        return out;
    }
    readonly property string summary: {
        const s = [];
        if (r.floating === "yes") s.push("floating");
        if (r.floating === "no") s.push("tiled");
        if (r.width || r.height) s.push((r.width || "…") + " × " + (r.height || "…"));
        if (r.maximized) s.push("maximized");
        if (r.fullscreen) s.push("fullscreen");
        if (r.output) s.push("on " + r.output);
        if (r.workspace) s.push("in " + r.workspace);
        if ((r.opacity ?? 1) < 1) s.push(Math.round(r.opacity * 100) + "% opaque");
        if (r.noScreencast) s.push("hidden from screen sharing");
        return s.length ? s.join(" · ") : "Nothing set yet";
    }

    function set(k, v) {
        const all = (Settings.data.windows.rules || []).slice();
        all[index] = Object.assign({}, all[index], { [k]: v });
        Settings.data.windows.rules = all;
        Compositor.queue();
    }
    function remove() {
        Settings.data.windows.rules = (Settings.data.windows.rules || []).filter((x, i) => i !== index);
        Compositor.queue();
    }

    Layout.fillWidth: true
    implicitHeight: col.implicitHeight + Theme.sp3 * 2
    radius: Theme.rLg
    color: Theme.alpha(Theme.text, open ? 0.06 : 0.035)
    border.width: open ? 1 : 0
    border.color: Theme.alpha(Theme.accent, 0.4)

    ColumnLayout {
        id: col
        x: Theme.sp3
        y: Theme.sp3
        width: parent.width - Theme.sp3 * 2
        spacing: Theme.sp2

        // ── the summary line ──
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.sp3
            AppIcon {
                implicitSize: 30
                name: root.r.app ? (Apps.lookup(root.r.app)?.icon ?? root.r.app) : "preferences-system-windows"
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                FText {
                    Layout.fillWidth: true
                    text: (root.r.app ? (Apps.lookup(root.r.app)?.name ?? root.r.app) : "Any app") + (root.r.title ? " · title has “" + root.r.title + "”" : "")
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                FText {
                    Layout.fillWidth: true
                    text: root.summary
                    dim: true
                    font.pixelSize: Theme.fsSm
                    elide: Text.ElideRight
                }
            }
            FIconButton { icon: root.open ? "expand_less" : "edit"; size: 30; onClicked: root.open = !root.open }
            FIconButton { icon: "delete"; size: 30; iconColor: Theme.error; onClicked: root.remove() }
        }

        // ── editing ──
        GridLayout {
            visible: root.open
            Layout.fillWidth: true
            Layout.topMargin: Theme.sp2
            columns: 2
            columnSpacing: Theme.sp3
            rowSpacing: Theme.sp2

            FText { text: "App"; dim: true }
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.sp2
                FTextField {
                    Layout.fillWidth: true
                    implicitHeight: 36
                    text: root.r.app || ""
                    placeholder: "Its app id, e.g. firefox"
                    onEditingFinished: if (text.trim() !== (root.r.app || "")) root.set("app", text.trim())
                }
                FDropdown {
                    implicitWidth: 170
                    implicitHeight: 36
                    placeholder: "Pick one"
                    // apps with windows open now, then installed apps
                    options: [...new Set(Niri.windows.map(w => w.app_id).filter(Boolean))].map(a => ({ value: a, label: (Apps.lookup(a)?.name ?? a) + " (open)" }))
                        .concat(Apps.all.map(e => ({ value: e.id.replace(/\.desktop$/, ""), label: e.name })))
                    onSelected: v => root.set("app", v)
                }
            }
            FText { text: "Title has"; dim: true }
            FTextField {
                Layout.fillWidth: true
                implicitHeight: 36
                text: root.r.title || ""
                placeholder: "Optional: only windows whose title has this"
                onEditingFinished: if (text.trim() !== (root.r.title || "")) root.set("title", text.trim())
            }
            FText { text: "Opens"; dim: true }
            FSegmented {
                implicitWidth: 300
                implicitHeight: 34
                options: [{ value: "", label: "As usual" }, { value: "yes", label: "Floating" }, { value: "no", label: "Tiled" }]
                current: root.r.floating || ""
                onSelected: v => root.set("floating", v)
            }
            FText { text: "Size"; dim: true }
            RowLayout {
                spacing: Theme.sp2
                FTextField {
                    implicitWidth: 110
                    implicitHeight: 36
                    text: root.r.width || ""
                    placeholder: "Width"
                    onEditingFinished: if (/^(\d{1,5}%?)?$/.test(text.trim())) root.set("width", text.trim())
                }
                FText { text: "×"; dim: true }
                FTextField {
                    implicitWidth: 110
                    implicitHeight: 36
                    text: root.r.height || ""
                    placeholder: "Height"
                    onEditingFinished: if (/^(\d{1,5}%?)?$/.test(text.trim())) root.set("height", text.trim())
                }
                FText { text: "px, or 50%"; dim: true; font.pixelSize: Theme.fsXs }
            }
            FText { text: "Screen"; dim: true }
            FDropdown {
                implicitWidth: 220
                implicitHeight: 36
                options: [{ value: "", label: "Any" }].concat(root.outputs.map(o => ({ value: o, label: o })))
                current: root.r.output || ""
                onSelected: v => root.set("output", v)
            }
            FText { text: "Workspace"; dim: true }
            FDropdown {
                implicitWidth: 220
                implicitHeight: 36
                options: [{ value: "", label: "Any" }].concat((Settings.data.workspaces.named || []).map(w => ({ value: w.name, label: w.name })))
                current: root.r.workspace || ""
                placeholder: "Named workspaces (Workspaces page)"
                onSelected: v => root.set("workspace", v)
            }
            FText { text: "Opacity"; dim: true }
            FSlider {
                Layout.fillWidth: true
                from: 0.1
                to: 1
                stepSize: 0.05
                value: root.r.opacity ?? 1
                showValue: true
                valueText: Math.round(value * 100) + "%"
                onMoved: v => root.set("opacity", Math.round(v * 100) / 100)
            }
            FText { text: "Also"; dim: true }
            Flow {
                Layout.fillWidth: true
                spacing: Theme.sp3
                Repeater {
                    model: [{ k: "maximized", t: "Maximized" }, { k: "fullscreen", t: "Fullscreen" }, { k: "noScreencast", t: "Hidden from screen sharing" }]
                    Row {
                        required property var modelData
                        spacing: 6
                        FSwitch {
                            anchors.verticalCenter: parent.verticalCenter
                            checked: !!root.r[parent.modelData.k]
                            onToggled: c => root.set(parent.modelData.k, c)
                        }
                        FText { anchors.verticalCenter: parent.verticalCenter; text: parent.modelData.t }
                    }
                }
            }
        }
    }
}
