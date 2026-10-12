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
        onLoaded: root.ready = true
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                writeAdapter();
            root.ready = true;
        }
        onAdapterUpdated: saveTimer.restart()

        JsonAdapter {
            id: adapter

            property JsonObject general: JsonObject {
                property bool use24h: true
                property bool showSeconds: false
                property string avatar: "~/.face"
                property string terminal: "kitty"
            }

            property JsonObject appearance: JsonObject {
                property string palette: "flamenco"   // see Palettes.qml, or "wallpaper"
                property string mode: "dark"          // dark | light
                property real roundness: 1.0          // corner radius multiplier
                property real panelOpacity: 0.94
                property real animSpeed: 1.0          // 0 disables animations
                property real uiScale: 1.0
                property string fontFamily: "Inter"
                property string monoFamily: "JetBrains Mono"
                property bool shadows: true
                property bool dimBehindPanels: true
            }

            property JsonObject bar: JsonObject {
                property string position: "top"       // top | bottom | left | right
                property string style: "floating"     // floating | attached | islands
                property int height: 40
                property string workspaceStyle: "pills" // pills | numbers | dots
                property bool trayHidePassive: false  // hide tray icons whose app reports "passive"
                property bool trayNativeMenus: false  // use Qt's native menus instead of themed ones
                property int trayMaxVisible: 6        // extra icons go into an overflow drawer
                property var left: ["launcher", "workspaces", "window"]
                property var center: ["clock", "media"]
                property var right: ["tray", "sysstats", "keyboard", "network", "bluetooth", "audio", "battery", "notifications", "power"]
            }

            property JsonObject dock: JsonObject {
                property bool enabled: false
                property bool autoHide: true
                property bool magnify: true
                property int iconSize: 48
                property var pinned: ["firefox", "org.kde.dolphin", "kitty"]
            }

            property JsonObject launcher: JsonObject {
                property int maxResults: 8
                property bool calculator: true
                property bool clipboard: true
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
                property string transition: "circle"  // fade | zoom | circle | wipe | random
                property int duration: 900
                property string fillMode: "crop"      // crop | fit | stretch
                property bool cycle: false
                property int cycleMinutes: 30
            }

            property JsonObject lock: JsonObject {
                property bool autoLock: true
                property int idleMinutes: 10
                property int screenOffMinutes: 15
                property bool showMedia: true
            }

            property JsonObject weather: JsonObject {
                property bool enabled: true
                property string city: ""
                property bool fahrenheit: false
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
