import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: I18n.tr("Workspaces")
    subtitle: I18n.tr("Named workspaces that always exist, and how the bar's workspace switcher behaves.")
    readonly property var ws: Settings.data.workspaces
    readonly property var outputs: [{ value: "", label: I18n.tr("Any screen") }].concat(Displays.outputs.map(o => ({ value: o.name, label: o.name })))

    Component.onCompleted: {
        Compositor.load();
        Displays.refresh();
    }

    function setNamed(list) {
        ws.named = list;
        Compositor.queue();
    }
    function edit(i, field, value) {
        const list = (ws.named || []).map(x => Object.assign({}, x));
        if (list[i][field] === value)
            return;
        list[i][field] = value;
        setNamed(list);
    }

    Group {
        title: I18n.tr("Named workspaces")
        Repeater {
            model: page.ws.named || []
            delegate: SettingRow {
                id: row
                required property var modelData
                required property int index
                title: modelData.name || "Untitled"
                subtitle: Niri.hyprland ? I18n.tr("Workspace ") + (index + 1) : I18n.tr("Opens at the top of ") + (modelData.output || "the first screen")
                icon: "label"
                RowLayout {
                    spacing: 8
                    FTextField {
                        implicitWidth: 160
                        text: row.modelData.name
                        placeholder: I18n.tr("Name")
                        onEditingFinished: if (text.trim()) page.edit(row.index, "name", text.trim())
                        onAccepted: if (text.trim()) page.edit(row.index, "name", text.trim())
                    }
                    FDropdown {
                        implicitWidth: 150
                        options: page.outputs
                        current: row.modelData.output || ""
                        onSelected: v => page.edit(row.index, "output", v)
                    }
                    FIconButton {
                        icon: "delete"
                        onClicked: page.setNamed((page.ws.named || []).filter((_, i) => i !== row.index))
                    }
                }
            }
        }
        SettingRow {
            title: (page.ws.named || []).length ? I18n.tr("Add another") : I18n.tr("No named workspaces yet")
            subtitle: I18n.tr("Name a workspace, like “web” or “chat”, so it's always there and keeps its place")
            icon: "add"
            FButton {
                text: I18n.tr("Add workspace")
                variant: "tonal"
                icon: "add"
                onClicked: {
                    const list = (page.ws.named || []).slice();
                    let n = list.length + 1;
                    while (list.some(x => x.name === "workspace-" + n))
                        n++;
                    list.push({ name: "workspace-" + n, output: "" });
                    page.setNamed(list);
                }
            }
        }
    }

    Group {
        title: I18n.tr("Switching")
        SwitchRow { title: I18n.tr("Switch back and forth"); subtitle: I18n.tr("Choosing the current workspace again goes back to the last one"); icon: "swap_horiz"; target: Settings.data.windows; key: "workspaceBackForth"; onEdited: Compositor.queue() }
        SwitchRow { title: I18n.tr("Scroll on the bar to switch"); icon: "swap_vert"; target: page.ws; key: "scrollSwitch" }
        SwitchRow { title: I18n.tr("Reverse scroll direction"); icon: "sync_alt"; visible: page.ws.scrollSwitch; target: page.ws; key: "invertScroll" }
    }

    Group {
        title: I18n.tr("Bar switcher")
        ChoiceRow {
            title: I18n.tr("Style")
            icon: "more_horiz"
            target: Settings.data.bar
            key: "workspaceStyle"
            options: [{ value: "pills", label: I18n.tr("Pills") }, { value: "dots", label: I18n.tr("Dots") }, { value: "numbers", label: I18n.tr("Numbers") }]
        }
        SwitchRow { title: I18n.tr("Hide empty workspaces"); subtitle: I18n.tr("Only show workspaces with windows, plus the current one"); icon: "visibility_off"; target: page.ws; key: "hideEmpty" }
        SwitchRow { title: I18n.tr("Show the window count"); subtitle: I18n.tr("How many windows are on the current workspace"); icon: "filter_9_plus"; target: page.ws; key: "showCount" }
    }

    FText {
        Layout.fillWidth: true
        visible: Compositor.status !== ""
        text: Compositor.status
        dim: !Compositor.failed
        color: Compositor.failed ? Theme.error : Theme.textDim
        wrapMode: Text.Wrap
    }
}
