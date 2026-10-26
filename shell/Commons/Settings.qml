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
                // a frame around the screen in the bar's color, rounding the desktop's corners
                property bool screenFrame: false
                property int frameWidth: 6
                property int frameRadius: 18
                property string mode: "dark"          // dark | light
                property real roundness: 1.0          // corner radius multiplier
                // transparency (Appearance → Transparency): each part's opacity, all scaled by uiOpacity.
                // -1 = the same as the panels (so older settings keep their look)
                property real panelOpacity: 0.94
                property real uiOpacity: 1.0
                property real barOpacity: -1
                property real popupOpacity: -1          // notifications, OSD, menus, pop-ups
                property real switcherOpacity: -1       // app switcher, overview, wallpaper switcher
                property real settingsOpacity: 1.0      // the Settings window
                property bool blur: false               // blur behind the shell's surfaces (Hyprland)
                property string finish: "flat"          // surfaces: flat | gloss (Frutiger Aero glass) | chrome (Y2K metal)
                property real animSpeed: 1.0          // 0 disables animations
                // motion style for every animation: expressive (springy) | smooth (no overshoot) | snappy | minimal
                property string motionStyle: "expressive"
                // speed per area (1 = normal, 2 = twice as fast, 0 = no animation)
                property var motionAreas: ({ panels: 1, notifications: 1, bar: 1, workspaces: 1, dock: 1, launcher: 1, lock: 1 })
                property string panelEffect: "rise"     // how panels open: rise | fade | slide | zoom | none
                property string notifEffect: "slide"    // how notifications arrive: slide | fade | pop
                property bool ripple: true              // ripple where you click
                property bool smoothScroll: false       // Flamenco's gliding wheel scrolling; off: standard (niri's settings)
                property bool hoverZoom: true           // things grow a little under the pointer
                property real uiScale: 1.0
                property string fontFamily: "Google Sans Flex"
                property string monoFamily: "Google Sans Code"
                property string iconStyle: "filled"     // filled | outlined
                // the shell's own icons: flamenco (Material Symbols, built in) | apps (the icon theme
                // apps use, App Theming) | any installed icon theme's name
                property string uiIcons: "apps"
                property bool blendPanels: false        // panels connect to the bar, no gap (like DMS)
                // switch dark ↔ light by itself: off | sun (sunset / sunrise) | schedule
                property string autoMode: "off"
                property string darkAt: "20:00"
                property string lightAt: "07:00"
                property int iconWeight: 500            // 300 (light) … 700 (bold)
                property bool shadows: true
                property bool dimBehindPanels: true
                property string accentOverride: ""    // "#rrggbb" replaces the palette's accent ("" = palette)
                property string textColor: ""         // "" = the palette's | "accent" | "#rrggbb"
                property bool textColorApps: true     // apps get that text color too (App Theming)
                property string caretColor: "accent"  // the text cursor: "accent" | "text" | "#rrggbb"
                property string layoutPreset: "islands" // last preset picked in Appearance → Layout presets
            }

            property JsonObject bar: JsonObject {
                property string position: "top"       // top | bottom | left | right | top-left | top-right | bottom-left | bottom-right | free
                property string length: "full"        // full (edge to edge) | fit (just around its widgets)
                property string align: "center"       // fit: where on its edge: start | center | end
                property string arrange: "spread"     // full: spread (sections at the ends and middle) | start | center | end (packed together)
                // floating | attached | islands | framed (a solid bar with pill groups, the Flamenco look)
                // | capsule (one pill hugging the widgets) | minimal (no bar, a soft shade) | outline (see-through, outlined)
                property string style: "islands"
                property var freePos: ({ x: 0.3, y: 0.04 }) // freeroam: where the bar is (top-left, as shares of the screen)
                property int margin: -1               // px from the screen edge (-1: the windows' gap, so they line up)
                property int radius: -1               // corner radius in px (-1: the theme's roundness)
                property real spacing: 1              // between widgets: 0.6 compact · 1 normal · 1.5 roomy
                property bool border: true            // a thin outline (floating, islands)
                property bool shadow: true            // a drop shadow (with Appearance → Drop shadows on)
                property int height: 40
                property string workspaceStyle: "apps" // pills | numbers | dots | apps (each workspace's app icons)
                property bool trayHidePassive: false  // hide tray icons whose app reports "passive"
                property bool trayNativeMenus: false  // use Qt's native menus instead of themed ones
                property int trayMaxVisible: 6        // extra icons go into an overflow drawer
                property string taskbarScope: "all"   // taskbar widget: all | screen | workspace
                property string micIndicator: "inuse" // microphone widget: inuse (while recording or muted) | always
                property var perScreen: ({})          // screens with their own widgets: { "DP-1": { left, center, right } }
                property bool taskbarTitles: false    // window titles next to the taskbar's icons
                property string clockLayout: "stacked" // clock: inline (time • date) | stacked (time over date) | time
                property string clockAlign: "center"  // clock text: left | center | right
                // hiding: never | auto (until the pointer reaches the edge) | windows (while windows are open on the workspace)
                property string hide: "never"
                property int hideDelay: 600         // ms after the pointer leaves before it hides
                property int revealSize: 3          // px strip at the edge that brings it back
                property bool hideKeepSpace: false  // windows keep the bar's space while it's hidden
                // battery indicator theme: icon | battery (shape, percent inside) | outline | cells | vertical | ring | pill | dot | text
                property string batteryStyle: "battery"
                property string batteryColors: "theme"  // theme (accent) | level (red → amber → green) | mono
                property bool batteryPercent: true      // show the percent
                property int batteryLow: 15             // percent at which it turns red
                property bool batteryBlink: true        // blink when nearly empty (10% below low) and not charging
                property bool batteryChargeAnim: true   // a sweep through the fill while charging
                property string statsStyle: "rings"   // CPU / RAM widget: text | rings (circular gauges)
                property bool statsTemp: true         // CPU / RAM widget: the temperature too
                // the start button (widget "launcher")
                property string startIcon: "apps"     // apps | distro | flamenco | custom
                property string startCustom: ""       // custom: a Material Symbols name, or a picture file
                property string startLabel: ""        // text beside the icon, e.g. "Start"
                property string startAction: "auto"  // auto (the overview when it's on, else the launcher) | launcher | overview
                // the "Islands" layout (Appearance → Layout presets)
                property var left: ["launcher", "separator", "workspaces", "window"]
                property var center: ["media", "visualizer"]
                property var right: ["sysstats", "separator", "recording", "privacy", "updates", "tray", "keyboard", "network", "bluetooth", "audio", "mic", "battery", "notifications", "quicksettings", "clock", "power"]
            }

            property JsonObject dock: JsonObject {
                property bool enabled: false
                // classic (app icons) | panel (also a start button, the overview, a clock and the weather, as pills)
                property string style: "classic"
                property var parts: ({ launcher: true, overview: true, clock: true, weather: true })
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

            // Flamenco's overview, like GNOME's Activities: search, workspaces, windows, a dash
            property JsonObject overview: JsonObject {
                property bool enabled: false
                property bool superKey: true          // tap Super on its own to open it (`flamenco super-watch`)
                property real superHold: 0.6          // s: Super held longer than this isn't a tap
                property bool workspaces: true        // workspace thumbnails along the top
                property string dash: "auto"          // auto (when the dock is off) | always | never
                property bool previews: true          // pictures of the windows, where the compositor allows it
                property bool blur: true              // the wallpaper behind it, blurred
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

            // Quick settings (the control center): where it opens and what's in it
            property JsonObject control: JsonObject {
                property string align: "auto"         // auto (next to its bar button) | left | center | right
                // grid (pill tiles in two columns, editable: press and hold) | cards (icon on top, big sliders) | classic
                property string style: "grid"
                property var grid: []                 // the grid's tiles in order: [{ id, w }] (w: 1 half, 2 whole row); [] = the default
                property int width: 440
                property int columns: 2
                property var sections: ({ header: true, sliders: true, tiles: true, media: true })
                property var tiles: []                // shown tiles in order; [] = all, in the default order
            }

            // Plugins (~/.config/flamenco/plugins): the ones turned on, and each one's own settings
            property JsonObject plugins: JsonObject {
                property var enabled: []
                property var config: ({})
            }

            // Clipboard history (cliphist): the bar's clipboard button and the launcher's ";"
            property JsonObject clipboard: JsonObject {
                property bool watch: true             // Flamenco records the history (wl-paste --watch cliphist store)
                property int maxItems: 500            // entries cliphist keeps
            }

            // The app switcher (Alt+Tab)
            property JsonObject switcher: JsonObject {
                property bool previews: false         // pictures of the windows on the cards, where the compositor allows it
                property string layout: "cards"       // cards | grid | list | icons | compact
                property string look: "tonal"         // Material 3: tonal | filled | outlined
            }

            // Noctalia and DMS plugins turned on (Settings → Plugins (3rd party)): "noctalia/<id>", "dms/<id>"
            property JsonObject thirdParty: JsonObject {
                property var enabled: []
            }

            // Package updates in the bar (`flamenco updates`)
            property JsonObject updates: JsonObject {
                property bool enabled: true           // check for package updates at all
                property bool showInBar: true         // the bar's updates icon (when there are some)
                property int interval: 60             // minutes between checks
            }

            // Calendars shown in the calendar panel (`flamenco calendar events`):
            // [{ name, url, color, enabled }]; url: an ICS link, an .ics file or a vdir folder
            // sources: also { type: "caldav", account: id, url: the calendar's address } from Online Accounts
            property JsonObject calendar: JsonObject {
                property var sources: []
                // Online Accounts (CalDAV sign-ins): [{ id, kind, name, server, user }];
                // passwords are in the keyring (`flamenco accounts secret`), never here
                property var accounts: []
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
                // which launcher opens: flamenco (the shell's own) | fuzzel (themed from the shell's colors)
                property string backend: "flamenco"
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
                // who shows notifications: flamenco (the shell's own, with history) | mako (themed from the shell's colors)
                property string backend: "flamenco"
                property string position: "top-right" // top-right | top-left | top-center | bottom-right | bottom-left
                property int timeout: 6
                property string style: "panel"        // the notification center: panel (drop-down) | shade (a full-height sheet from a side)
                property string shadeSide: "auto"     // shade: auto (the bell's side of the bar) | left | right
                property bool shadeCalendar: true     // shade: the month above the notifications
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
                property string picker: "carousel"   // the switcher: carousel (3D cover flow) | grid
                // live wallpapers: videos (mp4, webm, mkv, mov) and GIFs in the folder play on the desktop
                property bool live: true              // off: they show a still
                property bool livePauseSaver: true    // still while the power profile is Power saver (they play on battery otherwise)
                property bool livePauseWindows: true  // still while windows cover the workspace
                property real liveSpeed: 1.0
                property bool liveSound: false
                property string liveSource: "wikimedia" // online live wallpapers: wikimedia | pexels | pixabay
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
                property bool switcherKeysAdded: false // Alt+Tab → app switcher was added once (0.31.0); removing it sticks
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
                property bool floating: false         // window mode: windows float (true) or tile (false)
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
                property bool mixerBoost: false        // the app mixer goes to 150%
                property bool mixerStreams: true       // an app with several streams (browser tabs) can be expanded to set each
            }

            // Login / logout animations
            property JsonObject session: JsonObject {
                property string intro: "bloom"        // bloom | curtain | blinds | zoom | fade | none
                property string outro: "curtain"
                property int duration: 1400           // ms
                property bool greeting: true
                property bool welcome: true           // the welcome screen when you log in
                property bool goodbye: true           // the goodbye screen before logging out, restarting or shutting down
                property string logout: "flamenco"    // flamenco (straight out, after the goodbye) | niri (niri's own "Exit niri?" prompt)
                property bool slideIn: true           // the bar, dock and desktop widgets slide in when you log in
                property int slideDuration: 900       // ms each one takes
                property int slideStagger: 180        // ms between the bar, the dock and the widgets
            }

            // Dashboard: the clock/calendar popout
            property JsonObject dashboard: JsonObject {
                property string style: "hub"          // hub (wide, a rail on the left, Home first) | tabs (compact)
                property string defaultTab: "overview" // tabs layout: overview | media | wallpapers | weather
                property bool showUser: true
                property bool showMedia: true
            }

            // Night light (gammastep): warmer, optionally dimmer colors, by hand or on a schedule
            // The audio visualizer (cava): the bar's, the desktop widget's, the dashboard's and the big band's
            property JsonObject visualizer: JsonObject {
                property string style: "bars"         // bars | mirror | wave | dots | radial | peaks
                property string colors: "accent"      // accent | palette | rainbow | fire | mono
                property string motion: "smooth"      // smooth | snappy | bouncy | gravity (fast up, slow down)
                property int bars: 24                 // how finely cava splits the sound (8–64)
                property int fps: 60                  // 30 | 60
                // the big one: a band across the desktop (under windows) while something plays
                property bool band: false
                property int bandHeight: 220
                property string bandPosition: "bottom" // bottom | center | top
                property real bandOpacity: 0.85
            }

            // Digital wellbeing: screen time per app (kept on this computer only), limits and breaks
            property JsonObject wellbeing: JsonObject {
                property bool enabled: true
                property var limits: ({})             // app id → minutes a day; a notification when it's reached
                property int breakEvery: 0            // minutes of use before a reminder to take a break (0 = never)
                property int idleAfter: 120           // seconds without input before time stops counting
            }

            // Date & Time (the system's own settings are in timedatectl; this is only what the shell does)
            property JsonObject datetime: JsonObject {
                property bool autoTimezone: false     // follow where you are (checked at start and every few hours)
            }

            property JsonObject night: JsonObject {
                property bool enabled: false          // on by hand (with no schedule)
                property int temperature: 4000        // K at full strength (6500 = neutral)
                property real brightness: 1.0         // also dim the screen a little (0.5–1)
                property string schedule: "off"       // off | sun (sunset → sunrise) | custom
                property string from: "21:00"         // custom: on at
                property string to: "07:00"           // custom: off at
                property int fade: 30                 // minutes it takes to warm up / cool down on a schedule
            }

            // Theming of regular applications, applied by `flamenco apps-theme`.
            property JsonObject apps: JsonObject {
                property bool autoApply: true         // re-apply whenever the palette changes
                // apps' look: flamenco (the shell's palette) | gnome (GNOME's defaults: Adwaita) | kde (KDE's: Breeze).
                // gnome / kde put back what Flamenco changed, e.g. for using that desktop instead
                property string scheme: "flamenco"
                property bool syncFonts: true         // push shell fonts to Qt + GTK
                property string iconTheme: ""         // "" = leave untouched
                property string cursorTheme: ""
                property string gtkTheme: ""          // "" = adw-gtk3 when installed, else untouched
                property int cursorSize: 24
                // the mouse pointer recolored: "" = as the theme draws it | "accent" | "#rrggbb"
                // (Flamenco writes a tinted copy of the cursor theme, "flamenco-cursor")
                property string cursorTint: ""

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
                property var extraApps: ({})          // other apps themed from the palette: { kitty: true, … }
            }
        }
    }

    // Debounce writes so dragging a slider doesn't hammer the disk.
    Timer {
        id: saveTimer
        interval: 400
        onTriggered: file.writeAdapter()
    }

    readonly property int currentVersion: 10

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
        if (v < 7) {
            // 0.23.1: package updates (only shows when there are some), before the tray
            const b = adapter.bar;
            const used = (b.left || []).concat(b.center || [], b.right || []);
            if (!used.includes("updates")) {
                const side = ["right", "center", "left"].find(k => (b[k] || []).includes("tray")) ?? "right";
                const l = (b[side] || []).slice();
                const i = l.indexOf("tray");
                l.splice(Math.max(0, i), 0, "updates");
                b[side] = l;
            }
        }
        if (v < 8) {
            // 0.28.2: the "Islands" look is the default. A bar nobody arranged (the old
            // default layout and styles, floating) switches to it; a customised one stays.
            const b = adapter.bar;
            const same = (l, w) => JSON.stringify(l || []) === JSON.stringify(w);
            const oldRight = ["recording", "privacy", "updates", "tray", "sysstats", "keyboard", "network", "bluetooth", "audio", "mic", "battery", "notifications", "quicksettings", "power"];
            if (b.style === "floating" && b.workspaceStyle === "pills" && same(b.left, ["launcher", "workspaces", "window"])
                    && same(b.center, ["clock", "media"]) && same(b.right, oldRight) && Object.keys(b.perScreen || {}).length === 0) {
                b.style = "islands";
                b.workspaceStyle = "apps";
                b.clockLayout = "stacked";
                b.batteryStyle = "battery";
                b.statsStyle = "rings";
                b.statsTemp = true;
                b.left = ["launcher", "separator", "workspaces", "window"];
                b.center = ["media", "visualizer"];
                b.right = ["sysstats", "separator", "recording", "privacy", "updates", "tray", "keyboard", "network", "bluetooth", "audio", "mic", "battery", "notifications", "quicksettings", "clock", "power"];
                adapter.appearance.layoutPreset = "islands";
            }
        }
        if (v < 9) {
            // 0.44: quick settings as the editable tile grid; "cards" was the old default
            if ((adapter.control.style || "cards") === "cards")
                adapter.control.style = "grid";
        }
        if (v < 10) {
            // 0.51.1: the shell's icons follow the icon theme apps use (picking a pack in App
            // Theming or Get themes shows everywhere); "flamenco" was the old default
            if ((adapter.appearance.uiIcons || "flamenco") === "flamenco")
                adapter.appearance.uiIcons = "apps";
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
