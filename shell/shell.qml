//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
// the settings window draws its own title bar
//@ pragma Env QT_WAYLAND_DISABLE_WINDOWDECORATION=1

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services
import qs.Modules.Assistant
import qs.Modules.Background
import qs.Modules.Frame
import qs.Modules.Share
import qs.Modules.Keys
import qs.Modules.Notepad
import qs.Modules.Clipboard
import qs.Modules.Switcher
import qs.Modules.Overview
import qs.Modules.ThirdParty
// registers the compatibility modules Noctalia and DMS plugins import (see Compat/CompatModules.qml)
import qs.Compat
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
import qs.Modules.Windows
import qs.Modules.Polkit
import qs.Modules.Extras

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
        AutoMode.on;
        SuperKey.status;
        ThirdParty.plugins;
        Clipboard.available;
        // its one-time shortcut additions (Super+L, Alt+Tab) run at startup, not only once Settings → Keyboard opens
        Keyboard.cfg;
        // battery warnings, and the polkit agent (built here, not first from a Connections
        // target during loading, which DMS found could crash Quickshell)
        BatteryAlerts.on;
        Hooks.armed;
        PolkitAuth.agent;
    }

    // first run: open setup once settings are loaded (after the login animation)
    Timer {
        running: Settings.ready && !Settings.data.general.setupDone
        interval: 2600
        onTriggered: if (!Settings.data.general.setupDone) Panels.setupOpen = true
    }

    Background {}
    Desktop {}
    VisualizerBand {}
    Bar {}
    ScreenFrame {}
    SharePicker {}
    Dock {}
    HotCorners {}
    Popups {}
    DevicePopups {}
    ToastPopup {}
    PolkitDialog {}
    WhatsNew {}
    Island {}
    BrowserPicker {}
    QrPanel {}
    Osd { id: osd }

    ControlCenter {}
    NotificationCenter {}
    NotificationShade {}
    Launcher {}
    CalendarPanel {}
    PerformancePanel {}
    VolumePanel {}
    WallpaperPicker {}
    WallpaperCarousel {}
    WidgetEditor {}
    AssistantPanel {}
    KeysPanel {}
    ResizePanel {}
    NotepadPanel {}
    ClipboardPanel {}
    Switcher {}
    Overview {}
    ThirdPartyPanel {}
    PowerMenu {}
    SessionOverlay {}
    SettingsWindow {}
    SetupWindow {}
    Identify {}
    ConfirmChanges {}
    Lock { id: lock }

    // ── IPC: `flamenco ipc <target> <function> [args]` / `qs -p … ipc call …` ──

    // the panel is named after the IPC target (no property: IpcHandler warns about those)
    component PanelIpc: IpcHandler {
        function panelName(): string { return target === "wallpapers" ? "wallpaper" : target; }
        function toggle(): void { Panels.toggle(panelName(), ""); }
        function open(): void { Panels.open(panelName(), ""); }
        function close(): void { Panels.close(); }
        // open with text already typed, e.g. ":" for emoji
        function openWith(text: string): void {
            Panels.launcherQuery = text;
            Panels.open(panelName(), "");
        }
    }

    PanelIpc { target: "launcher" }
    PanelIpc { target: "control" }
    PanelIpc { target: "notifications" }
    PanelIpc { target: "calendar" }
    PanelIpc { target: "performance" }
    PanelIpc { target: "wallpapers" }
    PanelIpc { target: "power" }
    PanelIpc { target: "assistant" }
    PanelIpc { target: "keys" }
    PanelIpc { target: "notepad" }
    PanelIpc { target: "overview" }
    PanelIpc { target: "clipboard" }

    // the app switcher: `flamenco switcher next|prev` (Alt+Tab, Alt+Shift+Tab)
    IpcHandler {
        target: "switcher"
        function next(): void { Switcher.step(1); }
        function prev(): void { Switcher.step(-1); }
        function go(): void { Switcher.activate(); }
        function cancel(): void { Switcher.cancel(); }
    }

    // Super tapped on its own (Settings → Overview)
    Connections {
        target: SuperKey
        function onTapped() {
            if (!lock.locked)
                Panels.toggle("overview", "");
        }
    }

    // screen sharing's "which screen?" (`flamenco portals choose`, from the wlr portal)
    IpcHandler {
        target: "share"
        function pick(id: string, outputs: string): void { Share.ask(id, outputs); }
    }

    IpcHandler {
        target: "browser"
        function pick(url: string): void { Panels.browserUrl = url; }
    }

    IpcHandler {
        target: "windows"
        function toggleMode(): void { Compositor.setFloating(!Settings.data.windows.floating); }
        function floating(): void { Compositor.setFloating(true); }
        function tiling(): void { Compositor.setFloating(false); }
        function resize(): void { Resize.open(null, ""); }
    }

    IpcHandler {
        target: "bar"
        function toggle(): void { Panels.barHidden = !Panels.barHidden; }
        function hide(): void { Panels.barHidden = true; }
        function show(): void { Panels.barHidden = false; }
        function mode(m: string): void { if (["never", "auto", "windows"].includes(m)) Settings.data.bar.hide = m; }
    }

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
        function set(path: string): void { Wallpapers.set(path, ""); }
        function setFor(screen: string, path: string): void { Wallpapers.set(path, screen); }
        function random(): void { Wallpapers.random(""); }
        function next(): void { Wallpapers.next(""); }
        function get(): string { return Wallpapers.current; }
        function getFor(screen: string): string { return Wallpapers.forScreen(screen); }
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
