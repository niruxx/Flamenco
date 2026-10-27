import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Services
import qs.Widgets

// The task manager: every process, to search, sort by CPU, memory or name, and end
// (or, for one that won't, kill). Someone else's asks for your password first.
// Opened from the Performance panel, the launcher ("task manager") or a shortcut.
PanelWindow {
    id: win
    readonly property bool shown: Panels.tasks
    property var procs: []
    property string query: ""
    property string sort: "cpu"
    property bool mineOnly: true
    property int asking: 0                    // the pid whose End asks "sure?"
    property string status: ""

    readonly property var rows: {
        const q = query.trim().toLowerCase();
        let l = procs.filter(p => (!mineOnly || p.mine) && (!q || p.name.toLowerCase().includes(q) || p.cmd.toLowerCase().includes(q) || String(p.pid) === q));
        l = l.slice().sort((a, b) => sort === "mem" ? b.rss - a.rss : sort === "name" ? a.name.localeCompare(b.name) : b.cpu - a.cpu);
        return l.slice(0, 200);
    }
    function end(p, how) {
        status = "";
        killer.command = [Paths.bin, "procs", "kill", String(p.pid), how];
        killer.running = true;
        asking = 0;
    }
    function mb(b) {
        return b >= 1073741824 ? (b / 1073741824).toFixed(1) + " GB" : Math.round(b / 1048576) + " MB";
    }

    onShownChanged: {
        query = "";
        asking = 0;
        if (shown) {
            lister.running = true;
            field.focusInput();
        }
    }
    Timer {
        running: win.shown
        interval: 2000
        repeat: true
        onTriggered: if (!lister.running) lister.running = true
    }
    Process {
        id: lister
        command: [Paths.bin, "procs"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    win.procs = JSON.parse(text);
                } catch (e) {}
            }
        }
    }
    Process {
        id: killer
        stderr: StdioCollector { onStreamFinished: if (text.trim()) win.status = text.trim().split("\n").pop().replace(/^flamenco: /, "") }
        onExited: lister.running = true
    }

    visible: shown
    screen: Quickshell.screens.find(s => s.name === Panels.targetScreen("")) ?? Quickshell.screens[0]
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "flamenco-tasks"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Rectangle {
        anchors.fill: parent
        color: Theme.alpha(Theme.shadow, 0.4)
        MouseArea { anchors.fill: parent; onClicked: Panels.tasks = false }
    }
    Rectangle {
        anchors.centerIn: parent
        width: Math.min(900, parent.width - 64)
        height: Math.min(680, parent.height - 80)
        radius: Theme.rXl
        color: Theme.popupBg
        border.width: 1
        border.color: Theme.alpha(Theme.border, 0.7)
        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.sp4
            spacing: Theme.sp3
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.sp3
                FIcon { icon: "monitoring"; size: 26; color: Theme.accent; fill: 1 }
                FText { text: "Task manager"; font.pixelSize: Theme.fsXl; font.weight: Font.Bold }
                FText { text: win.rows.length + " processes · CPU " + Math.round(SystemStats.cpu * 100) + "% · memory " + Math.round(SystemStats.mem * 100) + "%"; dim: true; font.pixelSize: Theme.fsSm }
                Item { Layout.fillWidth: true }
                FIconButton { icon: "close"; onClicked: Panels.tasks = false }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.sp2
                FTextField {
                    id: field
                    Layout.fillWidth: true
                    icon: "search"
                    placeholder: "Search by name, command or PID"
                    onEdited: t => win.query = t
                    onKeyPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            Panels.tasks = false;
                            event.accepted = true;
                        }
                    }
                }
                FSegmented {
                    implicitWidth: 270
                    options: [{ value: "cpu", label: "CPU" }, { value: "mem", label: "Memory" }, { value: "name", label: "Name" }]
                    current: win.sort
                    onSelected: v => win.sort = v
                }
                Row {
                    spacing: 6
                    FSwitch { anchors.verticalCenter: parent.verticalCenter; checked: win.mineOnly; onToggled: c => win.mineOnly = c }
                    FText { anchors.verticalCenter: parent.verticalCenter; text: "Mine only"; dim: true }
                }
            }
            FText { Layout.fillWidth: true; visible: win.status !== ""; text: win.status; color: Theme.error; font.pixelSize: Theme.fsSm }

            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: ScriptModel { values: win.rows; objectProp: "pid" }
                spacing: 2
                delegate: Rectangle {
                    id: row
                    required property var modelData
                    width: list.width
                    height: 46
                    radius: Theme.rMd
                    color: rowHov.hovered ? Theme.alpha(Theme.text, 0.05) : "transparent"
                    HoverHandler { id: rowHov }
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 12
                        AppIcon { implicitSize: 26; name: Apps.iconFor(row.modelData.name) }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            FText { Layout.fillWidth: true; text: row.modelData.name; font.weight: Font.DemiBold; elide: Text.ElideRight }
                            FText { Layout.fillWidth: true; text: row.modelData.pid + " · " + row.modelData.user + " · " + row.modelData.cmd; dim: true; font.pixelSize: Theme.fsXs; elide: Text.ElideRight }
                        }
                        FText { Layout.preferredWidth: 64; horizontalAlignment: Text.AlignRight; text: row.modelData.cpu.toFixed(1) + "%"; mono: true; color: SystemStats.colorFor("cpu", row.modelData.cpu, Theme.text) }
                        FText { Layout.preferredWidth: 80; horizontalAlignment: Text.AlignRight; text: win.mb(row.modelData.rss); mono: true; dim: true }
                        FButton {
                            visible: rowHov.hovered || win.asking === row.modelData.pid
                            text: win.asking === row.modelData.pid ? "Sure?" : "End"
                            variant: win.asking === row.modelData.pid ? "filled" : "tonal"
                            implicitHeight: 30
                            onClicked: win.asking === row.modelData.pid ? win.end(row.modelData, "term") : win.asking = row.modelData.pid
                        }
                        FButton {
                            visible: rowHov.hovered
                            text: "Kill"
                            variant: "text"
                            implicitHeight: 30
                            onClicked: win.end(row.modelData, "kill")
                        }
                    }
                }
            }
        }
    }
}
