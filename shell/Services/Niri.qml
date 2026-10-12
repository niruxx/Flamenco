pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Live niri state via `niri msg --json event-stream`.
Singleton {
    id: root

    property var workspaces: []          // sorted by output, then idx
    property var windows: []
    property var focusedWindowId: null
    property bool overviewOpen: false
    property var layouts: []
    property int layoutIndex: 0

    readonly property var focusedWindow: windows.find(w => w.id === focusedWindowId) ?? null
    readonly property string focusedOutput: workspaces.find(w => w.is_focused)?.output ?? ""
    readonly property string currentLayout: layouts[layoutIndex] ?? ""

    function workspacesOn(output) {
        return workspaces.filter(w => w.output === output);
    }

    function windowsOn(workspaceId) {
        return windows.filter(w => w.workspace_id === workspaceId);
    }

    function action(...args) {
        Quickshell.execDetached(["niri", "msg", "action", ...args]);
    }

    function focusWorkspace(ws) {
        if (ws.output && ws.output !== focusedOutput)
            Quickshell.execDetached(["sh", "-c", 'niri msg action focus-monitor "$1" && niri msg action focus-workspace "$2"', "sh", ws.output, String(ws.idx)]);
        else
            action("focus-workspace", String(ws.idx));
    }

    function focusWindow(id) {
        action("focus-window", "--id", String(id));
    }

    function closeWindow(id) {
        action("close-window", "--id", String(id));
    }

    function sortWorkspaces(list) {
        return list.slice().sort((a, b) => a.output === b.output ? a.idx - b.idx : String(a.output).localeCompare(String(b.output)));
    }

    function handle(line) {
        let ev;
        try {
            ev = JSON.parse(line);
        } catch (e) {
            return;
        }

        if (ev.WorkspacesChanged) {
            workspaces = sortWorkspaces(ev.WorkspacesChanged.workspaces);
        } else if (ev.WorkspaceActivated) {
            const { id, focused } = ev.WorkspaceActivated;
            const target = workspaces.find(w => w.id === id);
            if (!target)
                return;
            workspaces = workspaces.map(w => {
                const n = Object.assign({}, w);
                if (w.output === target.output)
                    n.is_active = w.id === id;
                if (focused)
                    n.is_focused = w.id === id;
                return n;
            });
        } else if (ev.WorkspaceActiveWindowChanged) {
            const { workspace_id, active_window_id } = ev.WorkspaceActiveWindowChanged;
            workspaces = workspaces.map(w => w.id === workspace_id ? Object.assign({}, w, { active_window_id }) : w);
        } else if (ev.WindowsChanged) {
            windows = ev.WindowsChanged.windows;
            focusedWindowId = windows.find(w => w.is_focused)?.id ?? null;
        } else if (ev.WindowOpenedOrChanged) {
            const win = ev.WindowOpenedOrChanged.window;
            const i = windows.findIndex(w => w.id === win.id);
            const copy = windows.slice();
            if (i >= 0)
                copy[i] = win;
            else
                copy.push(win);
            windows = copy;
            if (win.is_focused)
                focusedWindowId = win.id;
        } else if (ev.WindowClosed) {
            windows = windows.filter(w => w.id !== ev.WindowClosed.id);
        } else if (ev.WindowFocusChanged) {
            focusedWindowId = ev.WindowFocusChanged.id ?? null;
        } else if (ev.KeyboardLayoutsChanged) {
            layouts = ev.KeyboardLayoutsChanged.keyboard_layouts.names;
            layoutIndex = ev.KeyboardLayoutsChanged.keyboard_layouts.current_idx;
        } else if (ev.KeyboardLayoutSwitched) {
            layoutIndex = ev.KeyboardLayoutSwitched.idx;
        } else if (ev.OverviewOpenedOrClosed) {
            overviewOpen = ev.OverviewOpenedOrClosed.is_open;
        }
    }

    Process {
        id: events
        running: true
        command: ["niri", "msg", "--json", "event-stream"]
        stdout: SplitParser {
            onRead: line => root.handle(line)
        }
        onExited: retry.start()
    }

    Timer {
        id: retry
        interval: 3000
        onTriggered: events.running = true
    }
}
