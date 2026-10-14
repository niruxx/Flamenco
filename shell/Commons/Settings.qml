pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Persistent user settings, stored at ~/.config/flamenco/settings.json.
// Every property here is live: edit the file by hand or through the
// settings app and the shell updates instantly.
Singleton {
    id: root

    readonly property alias data: adapter
    property bool ready: false

    FileView {
        id: file

        path: Paths.configDir + "/settings.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            root.migrate();
            root.ready = true;
        }
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {
                adapter.configVersion = root.currentVersion;
                writeAdapter();
            }
            root.ready = true;
        }
        onAdapterUpdated: saveTimer.restart()

        JsonAdapter {
            id: adapter

            // bumped when defaults change in a way existing configs should pick up
            // 0 = written before versioning existed; new files get currentVersion
            property int configVersion: 0

            property JsonObject general: JsonObject {
                property bool use24h: true
                property bool showSeconds: false
                property string avatar: "~/.face"
                property string terminal: "kitty"
                property bool setupDone: false        // first-run setup finished (or skipped)
                property bool nativeNetworkEditor: true          // edit connections in Settings → Network
                property string networkEditor: "nm-connection-editor"  // …or with this app
            }

            property JsonObject appearance: JsonObject {
                property string palette: "flamenco"   // see Palettes.qml, or "wallpaper"
                property string mode: "dark"          // dark | light
                property real roundness: 1.0          // corner radius multiplier
                property real panelOpacity: 0.94
                property real animSpeed: 1.0          // 0 disables animations
                property real uiScale: 1.0
                property string fontFamily: "Google Sans Flex"
                property string monoFamily: "Google Sans Code"
                property string iconStyle: "filled"     // filled | outlined
                property bool blendPanels: false        // panels connect to the bar, no gap (like DMS)
                // switch dark ↔ light by itself: off | sun (sunset / sunrise) | schedule
                property string autoMode: "off"
                property string darkAt: "20:00"
                property string lightAt: "07:00"
                property int iconWeight: 500            // 300 (light) … 700 (bold)
                property bool shadows: true
                property bool dimBehindPanels: true
                property string accentOverride: ""    // "#rrggbb" replaces the palette's accent ("" = palette)
                property string layoutPreset: ""      // last preset picked in Appearance → Layout presets
            }

            property JsonObject bar: JsonObject {
                property string position: "top"       // top | bottom | left | right
                property string style: "floating"     // floating | attached | islands
                property int height: 40
                property string workspaceStyle: "pills" // pills | numbers | dots
                property bool trayHidePassive: false  // hide tray icons whose app reports "passive"
                property bool trayNativeMenus: false  // use Qt's native menus instead of themed ones
                property int trayMaxVisible: 6        // extra icons go into an overflow drawer
                property string taskbarScope: "all"   // taskbar widget: all | screen | workspace
                property string micIndicator: "inuse" // microphone widget: inuse (while recording or muted) | always
                property bool taskbarTitles: false    // window titles next to the taskbar's icons
                property var left: ["launcher", "workspaces", "window"]
                property var center: ["clock", "media"]
                property var right: ["recording", "privacy", "tray", "sysstats", "keyboard", "network", "bluetooth", "audio", "mic", "battery", "notifications", "quicksettings", "power"]
            }

            property JsonObject dock: JsonObject {
                property bool enabled: false
                property bool autoHide: true
                property bool magnify: true
                property bool showRunning: true       // also show running apps that aren't pinned
                property int revealSize: 6            // px of the bottom edge that reveals an auto-hidden dock
                property int iconSize: 48
                property var pinned: ["firefox", "org.kde.dolphin", "kitty"]
                property string position: "bottom"   // bottom | left | right
                property string screen: ""           // output name; "" = every screen
                property real zoom: 0.5              // magnification: how much bigger the icon under the pointer gets
                property int spacing: 6              // px between icons
                property int margin: 8               // px between the dock and the screen edge
                property int hideDelay: 450          // ms an auto-hidden dock stays after the pointer leaves
                property real opacity: 1.0           // background opacity (on top of the panel opacity)
                property real roundness: 1.0         // corner radius, as a share of the theme's
                property bool border: true
                property string indicator: "line"    // line | dot | none
                property bool separator: true        // line between pinned and other running apps
                property bool labels: true           // app name on hover
            }

            // Desktop widgets: on the desktop above the wallpaper, under windows.
            // Added and arranged from quick settings → Desktop widgets.
            property JsonObject desktop: JsonObject {
                property bool enabled: true
                property string style: "card"         // card | glass | bare
                property real opacity: 0.8            // card background opacity
                // [{ id, type, screen, x, y, size, text }]; x / y: the top-left corner as a
                // share of the screen (0–1), size: s | m | l, text: a note's text
                property var widgets: []
            }

            // AI assistant (Settings → AI). API keys aren't kept here: they're in the
            // keyring (or ~/.config/flamenco/ai-keys.json), set through `flamenco ai key`.
            property JsonObject ai: JsonObject {
                property bool enabled: false
                property string provider: "anthropic"  // anthropic | openai | gemini | openrouter | lmstudio | ollama | custom
                property var providers: ({})           // per provider: { baseUrl, model }
                property string systemPrompt: "You are a helpful assistant built into the Flamenco desktop shell on Linux (niri or Hyprland). Answer clearly and concisely."
                property string effort: "low"          // Claude: low | medium | high
            }

            // Calendars shown in the calendar panel (`flamenco calendar events`):
            // [{ name, url, color, enabled }]; url: an ICS link, an .ics file or a vdir folder
            property JsonObject calendar: JsonObject {
                property var sources: []
            }

            // Screen recording (`flamenco record`)
            property JsonObject record: JsonObject {
                property string backend: "auto"       // auto | wf-recorder | gpu-screen-recorder
                property string audio: "none"         // none | desktop | mic | both
                property int fps: 60
                property string dir: "~/Videos/Recordings"
            }

            property JsonObject launcher: JsonObject {
                property int maxResults: 8
                property string position: "center"    // center | top | bottom | top-left | top-right | bottom-left | bottom-right | bar
                property int width: 600
                property bool calculator: true
                property bool clipboard: true
                property bool emoji: true             // ":" searches emoji
                property bool colors: true            // "#" color tools and the screen color picker
                property var recentEmoji: []
            }

            property JsonObject notifications: JsonObject {
                property bool popups: true
                property bool dnd: false
                property string position: "top-right" // top-right | top-left | top-center | bottom-right | bottom-left
                property int timeout: 6
            }

            property JsonObject osd: JsonObject {
                property bool enabled: true
                property string position: "bottom"    // top | bottom
            }

            property JsonObject wallpaper: JsonObject {
                property string dir: "~/Pictures/Wallpapers"
                property string current: ""
                property string transition: "mosaic"  // fade | focus | circle | ripple | wipe | sweep | blinds | mosaic | random
                property int duration: 1200
                property string fillMode: "crop"      // crop | fit | stretch
                property bool cycle: false
                property int cycleMinutes: 30
                // a different wallpaper on each screen: output name → image. A screen
                // without one shows `current`, which also drives "colors from wallpaper".
                property bool perScreen: false
                property var screens: ({})
            }

            property JsonObject lock: JsonObject {
                property bool autoLock: true
                property int idleMinutes: 10
                property int screenOffMinutes: 15
                property bool showMedia: true
                property string backend: "flamenco"  // flamenco | sddm | command
                property string sddmTheme: ""         // theme folder (full path, or a name under /usr/share/sddm/themes)
                property string sddmThemePath: ""     // or any folder containing an SDDM theme (overrides sddmTheme)
                property string command: ""           // e.g. "hyprlock" or "swaylock -f"
                property bool fingerprint: true       // also unlock with an enrolled finger (fprintd)
            }

            // Flamenco Greeter (the greetd login screen). Applied with `flamenco greeter apply`,
            // which copies it to /var/cache/flamenco-greeter for the greeter to read.
            property JsonObject greeter: JsonObject {
                property string wallpaperMode: "desktop"  // desktop | custom | color
                property string wallpaper: ""             // image for "custom"
                property string color: ""                 // background for "color" ("" = the palette's)
                property real blur: 0.0                   // 0..1
                property real dim: 0.25                   // 0..1
                property string fontFamily: ""            // "" = the shell's font
                property string monoFamily: ""
                property real fontScale: 1.0
                property bool sessionPicker: true
                property string defaultSession: ""        // session file, e.g. "niri.desktop" ("" = the last one used)
                property var hiddenSessions: []
                property bool userList: true
                property bool rememberUser: true
                property bool powerButtons: true
                property bool fingerprint: false   // offer fingerprint login (needs pam_fprintd in /etc/pam.d/greetd)
            }

            property JsonObject weather: JsonObject {
                property bool enabled: true
                property string city: ""
                property bool fahrenheit: false
                property int forecastDays: 5          // 1–7
                property bool showFeelsLike: true
                property bool showWind: true
                property bool showHumidity: true
                property bool showSunTimes: true
                property bool showHourly: true        // next 12 hours in the Weather tab
                property bool showInOverview: true    // weather card on the dashboard's Overview tab
            }

            // Keyboard layout + shortcuts, written into niri's config by `flamenco keyboard apply`
            property JsonObject keyboard: JsonObject {
                property bool imported: false         // true once read from the niri config
                property string layout: ""            // "us,es"
                property string variant: ""           // ",intl"
                property string options: ""           // "grp:alt_shift_toggle,caps:escape"
                property string model: ""
                property int repeatDelay: 600
                property int repeatRate: 25
                property bool numlock: true
                property string trackLayout: "global" // global | window
                property var shortcuts: []            // [{ key, type: flamenco|app|command|niri, value, title, locked }]
                property bool lockKeyAdded: false     // Super+L → lock was added once (0.20.1); removing it sticks
            }

            // Mouse & touchpad, written into the compositor config by `flamenco pointer apply`
            property JsonObject pointer: JsonObject {
                property bool imported: false         // true once read from the compositor config
                property real mouseSpeed: 0.0         // -1 (slow) … 1 (fast)
                property string mouseAccel: "adaptive" // adaptive | flat
                property bool mouseNatural: false
                property bool mouseLeftHanded: false
                property real mouseScroll: 1.0        // scroll speed multiplier
                property real touchSpeed: 0.0
                property string touchAccel: "adaptive"
                property bool touchNatural: true
                property bool tap: true               // tap to click
                property bool dwt: true               // disable while typing
                property real touchScroll: 1.0
                property bool disableWithMouse: false // turn the touchpad off while a mouse is plugged in
            }

            // Window look & behavior, written into the compositor config by `flamenco compositor apply`
            property JsonObject windows: JsonObject {
                property bool imported: false         // true once read from the compositor config
                property int gaps: 12
                property int struts: 0                // niri: px left and right where neighbour columns peek in
                property string centerColumn: "never" // niri: never | always | on-overflow
                property real defaultWidth: 0.5       // niri: new column width (0 = the app decides)
                property bool focusRing: true
                property int focusRingWidth: 2
                property bool border: false
                property int borderWidth: 2
                property bool syncColors: true        // ring / border colors follow the shell palette
                property string activeColor: "#ff5d73"
                property string inactiveColor: "#46343a"
                property string borderActiveColor: ""   // the border's own colors ("" = the focus ring's)
                property string borderInactiveColor: ""
                property bool gradient: false            // the focused window's ring / border as a gradient
                property string gradientTo: ""           // "" = the palette's second accent
                property int gradientAngle: 45
                property int cornerRadius: 12
                property bool shadows: true
                property bool focusFollowsMouse: false
                property bool warpMouse: false        // move the pointer to newly focused windows
                property bool hideCursorTyping: false
                property int hideCursorAfter: 0       // ms idle before hiding the pointer (0 = never)
                property bool preferNoCsd: true       // ask apps not to draw their own title bars
                property bool hotCorners: true        // niri's own corner (before Screen edges took it over)
                property bool skipHotkeyOverlay: true // niri: don't show the shortcut cheat sheet at login
                property bool workspaceBackForth: false // switching to the current workspace goes back
            }

            property JsonObject workspaces: JsonObject {
                property var named: []                // [{ name, output }] persistent named workspaces
                property bool hideEmpty: false        // bar: only show workspaces with windows (and the active one)
                property bool scrollSwitch: true      // bar: scroll over the workspaces to switch
                property bool invertScroll: false
                property bool showCount: false        // bar: window count on each workspace
            }

            // Screen corners: hover a corner to run an action
            property JsonObject edges: JsonObject {
                property bool enabled: false
                property string topLeft: "none"       // none | launcher | control | notifications | dashboard | overview | …
                property string topRight: "none"
                property string bottomLeft: "none"
                property string bottomRight: "none"
                property int delay: 250               // ms the pointer has to rest in the corner
                property int size: 2                  // px of the trigger area
                property bool niriImported: false     // niri's own hot corners were brought in here once
            }

            property JsonObject screenshot: JsonObject {
                property bool showPointer: false
                property bool saveToDisk: true        // false: clipboard only
                property int delay: 0                 // seconds
                property string path: "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"
            }

            property JsonObject autostart: JsonObject {
                property bool runEntries: true        // start XDG autostart apps at login
            }

            property JsonObject displays: JsonObject {
                property bool fallback: true          // turn the laptop screen on when no other screen is on
            }

            // Sleep: what the shell does itself (lid / power button live in logind, see Settings → Power)
            property JsonObject power: JsonObject {
                property bool allowSleep: true        // false: hold a systemd sleep inhibitor (lid, idle, menu)
                property bool lockOnSleep: true       // lock before any suspend/hibernate
                // power menu: seconds to hold each action before it runs (0 = runs on click)
                property real holdLogout: 3
                property real holdReboot: 3
                property real holdShutdown: 3
                property int idleSuspendBattery: 15   // minutes idle before suspending on battery (0 = never)
                property int idleSuspendAC: 0         // … when plugged in
            }

            // Sounds: theme for apps (gsettings / GTK / KDE) and the shell's own event sounds
            property JsonObject sound: JsonObject {
                property string theme: "flamenco"     // bundled; falls back to it when a theme is missing
                property bool eventSounds: true       // let apps play event sounds
                property bool notifications: true     // shell: sound when a notification pops up
                property bool volumeFeedback: true    // shell: click when you change the volume
                property bool brightnessFeedback: true // shell: tick when you change the brightness
            }

            // Login / logout animations
            property JsonObject session: JsonObject {
                property string intro: "bloom"        // bloom | curtain | blinds | zoom | fade | none
                property string outro: "curtain"
                property int duration: 1400           // ms
                property bool greeting: true
            }

            // Dashboard: the clock/calendar popout
            property JsonObject dashboard: JsonObject {
                property string defaultTab: "overview" // overview | media | wallpapers | weather
                property bool showUser: true
                property bool showMedia: true
            }

            property JsonObject night: JsonObject {
                property bool enabled: false
                property int temperature: 4000
            }

            // Theming of regular applications, applied by `flamenco apps-theme`.
            property JsonObject apps: JsonObject {
                property bool autoApply: true         // re-apply whenever the palette changes
                property bool syncFonts: true         // push shell fonts to Qt + GTK
                property string iconTheme: ""         // "" = leave untouched
                property string cursorTheme: ""
                property string gtkTheme: ""          // "" = adw-gtk3 when installed, else untouched
                property int cursorSize: 24

                // Shared stylesheet options (used by both the QSS and GTK CSS generators)
                property bool matchRoundness: true    // follow shell roundness
                property int radius: 8                // used when matchRoundness is off
                property string scrollbars: "thin"    // thin | overlay | classic
                property string buttons: "soft"       // soft | flat | outlined
                property bool accentSelection: true   // use accent for selections / focus rings
                property real contrast: 0.0           // -1..1 tweak of surface separation

                // Qt
                property bool qt: true
                property string qtStyle: "Fusion"     // any installed style, see `flamenco list-themes`
                property string kvantumTheme: ""      // used when qtStyle is "kvantum"
                property bool qss: true               // ship a generated stylesheet via qt5ct/qt6ct
                property bool kdeColors: true         // also write ~/.local/share/color-schemes + kdeglobals
                property string customQss: ""

                // GTK
                property bool gtk: true
                property bool gtk3: true
                property bool gtk4: true              // libadwaita apps
                property bool gtkExtras: true         // extra styling beyond color overrides
                property string customGtkCss: ""
            }
        }
    }

    // Debounce writes so dragging a slider doesn't hammer the disk.
    Timer {
        id: saveTimer
        interval: 400
        onTriggered: file.writeAdapter()
    }

    readonly property int currentVersion: 6

    // One-time upgrades for settings files written by older versions.
    function migrate() {
        const v = adapter.configVersion || 1;
        if (v >= currentVersion)
            return;
        if (v < 2) {
            // 0.3: quick-settings button next to power
            const b = adapter.bar;
            const used = (b.left || []).concat(b.center || [], b.right || []);
            if (!used.includes("quicksettings")) {
                const r = (b.right || []).slice();
                const i = r.indexOf("power");
                r.splice(i >= 0 ? i : r.length, 0, "quicksettings");
                b.right = r;
            }
        }
        if (v < 3) {
            // 0.17: Google Sans replaces the old default fonts (a font you picked stays)
            const a = adapter.appearance;
            if (a.fontFamily === "Inter")
                a.fontFamily = "Google Sans Flex";
            if (a.monoFamily === "JetBrains Mono")
                a.monoFamily = "Google Sans Code";
        }
        if (v < 4) {
            // 0.20.3: the microphone widget (shows only while recording or muted), after the volume
            const b = adapter.bar;
            const used = (b.left || []).concat(b.center || [], b.right || []);
            if (!used.includes("mic")) {
                for (const side of ["right", "center", "left"]) {
                    const l = (b[side] || []).slice();
                    const i = l.indexOf("audio");
                    if (i >= 0) {
                        l.splice(i + 1, 0, "mic");
                        b[side] = l;
                        break;
                    }
                }
            }
        }
        if (v < 5) {
            // 0.21.1: the privacy indicator (camera, screen sharing), at the start of the
            // section with the system icons; it only shows while something is in use
            const b = adapter.bar;
            const used = (b.left || []).concat(b.center || [], b.right || []);
            if (!used.includes("privacy")) {
                const side = ["right", "center", "left"].find(k => (b[k] || []).some(x => ["tray", "audio", "network", "mic"].includes(x))) ?? "right";
                b[side] = ["privacy"].concat(b[side] || []);
            }
        }
        if (v < 6) {
            // 0.21.2: the recording indicator (only while recording), next to the privacy one
            const b = adapter.bar;
            const used = (b.left || []).concat(b.center || [], b.right || []);
            if (!used.includes("recording")) {
                const side = ["right", "center", "left"].find(k => (b[k] || []).includes("privacy")) ?? "right";
                const l = (b[side] || []).slice();
                const i = l.indexOf("privacy");
                l.splice(Math.max(0, i), 0, "recording");
                b[side] = l;
            }
        }
        adapter.configVersion = currentVersion;
    }

    // Helpers for list-valued settings (JsonAdapter needs reassignment to notice changes).
    function listAdd(obj, key, value) {
        const l = (obj[key] || []).slice();
        if (!l.includes(value))
            l.push(value);
        obj[key] = l;
    }

    function listRemove(obj, key, value) {
        obj[key] = (obj[key] || []).filter(v => v !== value);
    }

    function listMove(obj, key, from, to) {
        const l = (obj[key] || []).slice();
        if (to < 0 || to >= l.length)
            return;
        const [item] = l.splice(from, 1);
        l.splice(to, 0, item);
        obj[key] = l;
    }
}
