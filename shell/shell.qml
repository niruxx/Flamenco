//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
// the settings window draws its own title bar
//@ pragma Env QT_WAYLAND_DISABLE_WINDOWDECORATION=1

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services
import qs.Modules.Background
import qs.Modules.Desktop
import qs.Modules.Bar
import qs.Modules.Dock
import qs.Modules.Edges
import qs.Modules.OSD
import qs.Modules.Notifications
import qs.Modules.ControlCenter
import qs.Modules.Launcher
import qs.Modules.Calendar
import qs.Modules.WallpaperPicker
import qs.Modules.Session
import qs.Modules.Lock
import qs.Modules.Settings
import qs.Modules.Displays
import qs.Modules.Performance
import qs.Modules.Volume
import qs.Modules.Setup

ShellRoot {
    id: shell

    // Eagerly start services that must run even when nothing references them yet.
    Component.onCompleted: {
        Notifs.unread;
        AppTheming.cfg;
        ColorGen.available;
        Toggles.nightLight;
        SessionFx.startup();
        Displays.screenCount;
    }

    // first run: open setup once settings are loaded (after the login animation)
    Timer {
        running: Settings.ready && !Settings.data.general.setupDone
        interval: 2600
        onTriggered: if (!Settings.data.general.setupDone) Panels.setupOpen = true
    }

    Background {}
    Desktop {}
    Bar {}
    Dock {}
    HotCorners {}
    Popups {}
    Osd { id: osd }

    ControlCenter {}
    NotificationCenter {}
    Launcher {}
    CalendarPanel {}
    PerformancePanel {}
    VolumePanel {}
    WallpaperPicker {}
    WidgetEditor {}
    PowerMenu {}
    SessionOverlay {}
    SettingsWindow {}
    SetupWindow {}
    Identify {}
    ConfirmChanges {}
    Lock { id: lock }

    // ── IPC: `flamenco ipc <target> <function> [args]` / `qs -p … ipc call …` ──

    component PanelIpc: IpcHandler {
        required property string panel
        function toggle(): void { Panels.toggle(panel, ""); }
        function open(): void { Panels.open(panel, ""); }
        function close(): void { Panels.close(); }
    }

    PanelIpc { target: "launcher"; panel: "launcher" }
    PanelIpc { target: "control"; panel: "control" }
    PanelIpc { target: "notifications"; panel: "notifications" }
    PanelIpc { target: "calendar"; panel: "calendar" }
    PanelIpc { target: "performance"; panel: "performance" }
    PanelIpc { target: "wallpapers"; panel: "wallpaper" }
    PanelIpc { target: "power"; panel: "power" }

    IpcHandler {
        target: "widgets"
        function edit(): void { Panels.editWidgets(""); }
        function done(): void { Panels.widgetsEdit = false; }
        function toggle(): void { Panels.widgetsEdit ? Panels.widgetsEdit = false : Panels.editWidgets(""); }
    }

    IpcHandler {
        target: "settings"
        function open(page: string): void { Panels.openSettings(page); }
        function toggle(): void { Panels.settingsOpen = !Panels.settingsOpen; }
        function close(): void { Panels.settingsOpen = false; }
    }

    IpcHandler {
        target: "volume"
        function up(): void { Audio.step(0.05); }
        function down(): void { Audio.step(-0.05); }
        function set(percent: int): void { Audio.setVolume(percent / 100); }
        function mute(): void { Audio.toggleMute(); }
        function micMute(): void { Audio.toggleMicMute(); }
        function get(): string { return String(Math.round(Audio.volume * 100)); }
        function panel(): void { Panels.toggle("volume", ""); }
    }

    IpcHandler {
        target: "brightness"
        function up(): void { Brightness.step(0.05); }
        function down(): void { Brightness.step(-0.05); }
        function set(percent: int): void { Brightness.set(percent / 100); }
        function get(): string { return String(Math.round(Brightness.value * 100)); }
        function kbdUp(): void { Brightness.stepKbd(1); }
        function kbdDown(): void { Brightness.stepKbd(-1); }
        function kbdSet(percent: int): void { Brightness.setKbd(percent / 100); }
        function kbdToggle(): void { Brightness.toggleKbd(); }
        function kbdGet(): string { return Brightness.kbdAvailable ? String(Math.round(Brightness.kbdValue * 100)) : "none"; }
    }

    IpcHandler {
        target: "media"
        function toggle(): void { Media.toggle(); }
        function next(): void { Media.next(); }
        function previous(): void { Media.previous(); }
    }

    IpcHandler {
        target: "wallpaper"
        function set(path: string): void { Wallpapers.set(path); }
        function random(): void { Wallpapers.random(); }
        function next(): void { Wallpapers.next(); }
        function get(): string { return Wallpapers.current; }
    }

    IpcHandler {
        target: "theme"
        function palette(name: string): void { Settings.data.appearance.palette = name; }
        function mode(mode: string): void { Settings.data.appearance.mode = mode; }
        function toggleMode(): void { Settings.data.appearance.mode = Theme.dark ? "light" : "dark"; }
        function applyApps(): void { AppTheming.apply(); }
        function list(): string { return Palettes.names.concat(["wallpaper"]).join("\n"); }
    }

    IpcHandler {
        target: "setup"
        function open(): void { Panels.setupOpen = true; }
    }

    IpcHandler {
        target: "session"
        function previewIntro(): void { SessionFx.playIntro(true); }
        function previewOutro(): void { SessionFx.playOutro("Logging out…", null, true); }
    }

    IpcHandler {
        target: "notifs"
        function toggleDnd(): void { Notifs.setDnd(!Notifs.dnd); }
        function clear(): void { Notifs.clearAll(); }
    }

    IpcHandler {
        target: "toggles"
        function caffeine(): void { Toggles.caffeine = !Toggles.caffeine; }
        function nightLight(): void { Toggles.setNightLight(!Toggles.nightLight); }
    }
}
