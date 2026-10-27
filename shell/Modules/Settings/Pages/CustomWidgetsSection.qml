import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

// Settings → Bar → Custom widgets: bar widgets made from your own commands. Each
// runs every few seconds (or keeps running, a line per update) and shows what it
// prints: plain text, or waybar-style JSON {"text", "tooltip", "icon", "class"}.
// Add one to a section below, like any other widget.
Group {
    id: root
    title: I18n.tr("Custom widgets")
    readonly property var b: Settings.data.bar
    readonly property var ids: Object.keys(b.customs || {}).sort()
    property string editing: ""

    function set(id, k, v) {
        const all = Object.assign({}, b.customs || {});
        all[id] = Object.assign({}, all[id], { [k]: v });
        b.customs = all;
    }
    function add() {
        let n = 1;
        while ((b.customs || {})["custom:" + n])
            n++;
        const id = "custom:" + n;
        const all = Object.assign({}, b.customs || {});
        all[id] = { name: "Custom " + n, exec: "", interval: 10, watch: false, icon: "terminal", onClick: "", onRightClick: "", onMiddleClick: "" };
        b.customs = all;
        editing = id;
    }
    function remove(id) {
        const all = Object.assign({}, b.customs || {});
        delete all[id];
        b.customs = all;
        for (const k of ["left", "center", "right"])
            b[k] = (b[k] || []).filter(x => x !== id);
    }

    SettingRow {
        title: root.ids.length ? root.ids.length + (root.ids.length === 1 ? " custom widget" : " custom widgets") : I18n.tr("None yet")
        subtitle: I18n.tr("A widget from your own command, e.g. a script that prints the weather, a countdown or a server's status. Then add it to a section below")
        icon: "terminal"
        FButton { text: I18n.tr("New"); icon: "add"; variant: "tonal"; onClicked: root.add() }
    }
    Repeater {
        model: root.ids
        ColumnLayout {
            id: card
            required property string modelData
            readonly property var c: (root.b.customs || {})[modelData] ?? ({})
            readonly property bool open: root.editing === modelData
            readonly property bool placed: ["left", "center", "right"].some(k => (root.b[k] || []).includes(modelData))
            Layout.fillWidth: true
            spacing: 0
            SettingRow {
                title: card.c.name || card.modelData
                subtitle: (card.c.exec ? card.c.exec : I18n.tr("No command yet")) + (card.placed ? "" : " · not in the bar yet")
                icon: card.c.icon || "terminal"
                Row {
                    spacing: 2
                    FIconButton { icon: card.open ? "expand_less" : "edit"; size: 30; onClicked: root.editing = card.open ? "" : card.modelData }
                    FIconButton { icon: "delete"; size: 30; iconColor: Theme.error; onClicked: root.remove(card.modelData) }
                }
            }
            GridLayout {
                visible: card.open
                Layout.fillWidth: true
                Layout.margins: Theme.sp3
                columns: 2
                columnSpacing: Theme.sp3
                rowSpacing: Theme.sp2
                FText { text: I18n.tr("Name"); dim: true }
                FTextField { Layout.fillWidth: true; implicitHeight: 36; text: card.c.name || ""; onEditingFinished: root.set(card.modelData, "name", text.trim()) }
                FText { text: I18n.tr("Command"); dim: true }
                FTextField { Layout.fillWidth: true; implicitHeight: 36; text: card.c.exec || ""; placeholder: I18n.tr("e.g. ~/bin/status.sh, or: date +%A"); onEditingFinished: root.set(card.modelData, "exec", text.trim()) }
                FText { text: I18n.tr("Runs"); dim: true }
                RowLayout {
                    spacing: Theme.sp2
                    FSegmented {
                        implicitWidth: 300
                        implicitHeight: 34
                        options: [{ value: false, label: I18n.tr("Every few seconds") }, { value: true, label: I18n.tr("Keeps running") }]
                        current: card.c.watch ?? false
                        onSelected: v => root.set(card.modelData, "watch", v)
                    }
                    FTextField {
                        visible: !(card.c.watch ?? false)
                        implicitWidth: 70
                        implicitHeight: 34
                        text: String(card.c.interval ?? 10)
                        onEditingFinished: {
                            const v = parseInt(text);
                            if (v > 0)
                                root.set(card.modelData, "interval", v);
                        }
                    }
                    FText { visible: !(card.c.watch ?? false); text: I18n.tr("seconds"); dim: true }
                }
                FText { text: I18n.tr("Icon"); dim: true }
                FTextField { Layout.fillWidth: true; implicitHeight: 36; text: card.c.icon || ""; placeholder: I18n.tr("A Material Symbols name, or empty"); onEditingFinished: root.set(card.modelData, "icon", text.trim()) }
                FText { text: I18n.tr("Click"); dim: true }
                FTextField { Layout.fillWidth: true; implicitHeight: 36; text: card.c.onClick || ""; placeholder: I18n.tr("A command, or empty"); onEditingFinished: root.set(card.modelData, "onClick", text.trim()) }
                FText { text: I18n.tr("Right-click"); dim: true }
                FTextField { Layout.fillWidth: true; implicitHeight: 36; text: card.c.onRightClick || ""; onEditingFinished: root.set(card.modelData, "onRightClick", text.trim()) }
                FText { text: I18n.tr("Middle-click"); dim: true }
                FTextField { Layout.fillWidth: true; implicitHeight: 36; text: card.c.onMiddleClick || ""; onEditingFinished: root.set(card.modelData, "onMiddleClick", text.trim()) }
                Item { width: 1; height: 1 }
                RowLayout {
                    spacing: Theme.sp2
                    FButton {
                        visible: !card.placed
                        text: I18n.tr("Add to the right section")
                        icon: "add"
                        variant: "tonal"
                        onClicked: root.b.right = (root.b.right || []).concat([card.modelData])
                    }
                    FText {
                        Layout.fillWidth: true
                        text: I18n.tr("It shows the first line it prints, or JSON like {\"text\": \"…\", \"tooltip\": \"…\", \"class\": \"warning\"}")
                        dim: true
                        font.pixelSize: Theme.fsXs
                        wrapMode: Text.Wrap
                    }
                }
            }
        }
    }
}
