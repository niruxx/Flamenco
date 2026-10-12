pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Live compositor state. On niri: `niri msg --json event-stream`. On Hyprland:
// its event socket + `hyprctl -j`, mapped onto the same model so the rest of
// the shell doesn't care which compositor it runs on.
Singleton {
    id: root

    readonly property bool hyprland: !!Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")
    readonly property string compositor: hyprland ? "hyprland" : "niri"

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
        if (!hyprland) {
            Quickshell.execDetached(["niri", "msg", "action", ...args]);
            return;
        }
        // niri action names → Hyprland dispatchers
        const a = args[0], rest = args.slice(1);
        const id = rest.includes("--id") ? rest[rest.indexOf("--id") + 1] : "";
        const d = {
            "focus-workspace": ["workspace", rest[0]],
            "focus-workspace-up": ["workspace", "e-1"],
            "focus-workspace-down": ["workspace", "e+1"],
            "focus-window": ["focuswindow", "address:" + id],
            "close-window": id ? ["closewindow", "address:" + id] : ["killactive"],
            "power-off-monitors": ["dpms", "off"],
            "quit": ["exit"]
        }[a];
        if (a === "switch-layout")
            Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", rest[0] === "prev" ? "prev" : "next"]);
        else if (d)
            Quickshell.execDetached(["hyprctl", "dispatch", d[0], ...(d[1] ? [d[1]] : [])]);
    }

    function focusWorkspace(ws) {
        if (hyprland)
            action("focus-workspace", String(ws.id));
        else if (ws.output && ws.output !== focusedOutput)
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

    // ── Hyprland ──
    function hyprApply(text) {
        let d;
        try {
            d = JSON.parse(text);
        } catch (e) {
            return;
        }
        const active = {};
        let focusedMon = "";
        for (const m of d.mon ?? []) {
            active[m.name] = m.activeWorkspace?.id;
            if (m.focused)
                focusedMon = m.name;
        }
        workspaces = sortWorkspaces((d.ws ?? []).filter(w => w.id > 0).map(w => ({
                        id: w.id,
                        idx: w.id,
                        name: /^\d+$/.test(String(w.name)) ? "" : w.name,
                        output: w.monitor,
                        is_active: active[w.monitor] === w.id,
                        is_focused: active[w.monitor] === w.id && w.monitor === focusedMon
                    })));
        windows = (d.cl ?? []).filter(c => c.mapped !== false).map(c => ({
                    id: c.address,
                    app_id: c.class || c.initialClass || "",
                    title: c.title || "",
                    workspace_id: c.workspace?.id,
                    is_focused: c.focusHistoryID === 0
                }));
        focusedWindowId = windows.find(w => w.is_focused)?.id ?? null;
        const kb = (d.dev?.keyboards ?? []).find(k => k.main) ?? (d.dev?.keyboards ?? [])[0];
        if (kb) {
            const codes = String(kb.layout || "").split(",").filter(x => x);
            layouts = codes.length > 1 ? codes.map((c, i) => i === (kb.active_layout_index ?? 0) ? kb.active_keymap : c) : [kb.active_keymap];
            layoutIndex = Math.max(0, kb.active_layout_index ?? 0);
        }
    }

    Process {
        id: hyprQuery
        command: ["sh", "-c", "printf '{\"ws\":%s,\"cl\":%s,\"mon\":%s,\"dev\":%s}' \"$(hyprctl -j workspaces)\" \"$(hyprctl -j clients)\" \"$(hyprctl -j monitors)\" \"$(hyprctl -j devices)\""]
        stdout: StdioCollector {
            onStreamFinished: root.hyprApply(text)
        }
    }

    Timer {
        id: hyprRefresh
        interval: 60
        onTriggered: if (!hyprQuery.running) hyprQuery.running = true; else restart()
    }

    Socket {
        id: hyprEvents
        path: (Quickshell.env("XDG_RUNTIME_DIR") || "") + "/hypr/" + (Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") || "") + "/.socket2.sock"
        connected: root.hyprland
        parser: SplitParser {
            onRead: hyprRefresh.restart()
        }
        onConnectedChanged: if (!connected && root.hyprland) hyprReconnect.start()
    }

    Timer {
        id: hyprReconnect
        interval: 3000
        onTriggered: hyprEvents.connected = true
    }

    Component.onCompleted: if (hyprland) hyprRefresh.start()

    // ── niri ──
    Process {
        id: events
        running: !root.hyprland
        command: ["niri", "msg", "--json", "event-stream"]
        stdout: SplitParser {
            onRead: line => root.handle(line)
        }
        onExited: if (!root.hyprland) retry.start()
    }

    Timer {
        id: retry
        interval: 3000
        onTriggered: events.running = true
    }
}
