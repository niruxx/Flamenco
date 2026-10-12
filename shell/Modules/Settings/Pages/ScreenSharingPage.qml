import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services
import qs.Widgets

// Which xdg-desktop-portal backend handles screen sharing, screenshots and
// file pickers (~/.config/xdg-desktop-portal/niri-portals.conf).
Page {
    id: page
    title: "Screen sharing & files"
    subtitle: "Apps share your screen and open file pickers through xdg-desktop-portal. Choose which backend handles each."

    property var st: ({ installed: [], current: {}, packages: {}, wlr: {} })
    property bool loaded: false
    property string status: ""

    // draft
    property string screenCast: ""
    property string screenshot: ""
    property string fileChooser: ""
    property string fallback: "gtk"
    property string wlrOutput: ""
    property int maxFps: 0
    property bool gtkUsePortal: false

    readonly property var pickers: [
        { value: "gtk", label: "GTK", pkg: "xdg-desktop-portal-gtk", note: "The standard GTK dialog. Light." },
        { value: "kde", label: "Qt (KDE)", pkg: "xdg-desktop-portal-kde", note: "KDE's Qt dialog with Dolphin-style places. Only its file picker is used." },
        { value: "cosmic", label: "COSMIC", pkg: "xdg-desktop-portal-cosmic", note: "COSMIC Files' dialog. Only its file picker is used." },
        { value: "gnome", label: "GNOME", pkg: "xdg-desktop-portal-gnome", note: "The GNOME dialog (pulls in GNOME libraries)." }
    ]

    readonly property var names: st.installed.map(p => p.name)
    readonly property bool usesWlr: screenCast === "wlr" || screenshot === "wlr"

    function load() {
        if (!getter.running)
            getter.running = true;
    }

    function optionsFor(iface) {
        const capture = iface === "ScreenCast" || iface === "Screenshot";
        const label = p => {
            if (!capture)
                return p.name;
            const mark = p.niri === "works" ? "✓ " : p.niri === "no" ? "✗ " : "";
            return mark + p.name + (p.note ? ": " + p.note : "");
        };
        return [{ value: "", label: "niri's default" + (page.st.current[iface] ? " (" + page.st.current[iface] + ")" : "") }]
            .concat(page.st.installed.filter(p => p.interfaces.includes(iface)).map(p => ({ value: p.name, label: label(p) })));
    }

    function apply() {
        const spec = { default: fallback, ScreenCast: screenCast, Screenshot: screenshot, FileChooser: fileChooser, wlrOutput: wlrOutput, maxFps: maxFps, gtkUsePortal: gtkUsePortal };
        applier.command = [Paths.bin, "portals", "apply", "--json", JSON.stringify(spec)];
        applier.running = true;
    }

    function install(pkgs) {
        Quickshell.execDetached(Paths.termHold("sudo pacman -S --needed " + pkgs.join(" ")));
    }

    Component.onCompleted: {
        load();
        Displays.refresh();
    }

    Process {
        id: getter
        command: [Paths.bin, "portals", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    page.st = d;
                    // only adopt values when we wrote the file (niri's shipped defaults show as "niri's default")
                    const ours = (d.current.source || "").indexOf("/.config/") >= 0;
                    page.screenCast = ours ? (d.current.ScreenCast ?? "") : "";
                    page.screenshot = ours ? (d.current.Screenshot ?? "") : "";
                    page.fileChooser = ours ? (d.current.FileChooser ?? "") : "";
                    page.fallback = ours ? (d.current.default || "gtk") : "gtk";
                    page.wlrOutput = d.wlr.output_name ?? "";
                    page.maxFps = parseInt(d.wlr.max_fps ?? "0") || 0;
                    page.gtkUsePortal = d.gtkUsePortal ?? false;
                    page.loaded = true;
                } catch (e) {
                    page.status = "Couldn't read the portal setup";
                }
            }
        }
    }

    Process {
        id: applier
        stdout: StdioCollector {
            onStreamFinished: if (text.trim()) page.status = "Saved. Apps that were already open may need a restart."
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) page.status = text.trim().split("\n").pop().replace(/^flamenco: /, "")
        }
        onExited: page.load()
    }

    // ── file picker ──
    Group {
        title: "File picker"

        Repeater {
            model: page.pickers
            SettingRow {
                id: fp
                required property var modelData
                readonly property bool installed: page.names.includes(modelData.value)
                readonly property bool chosen: page.fileChooser === modelData.value
                title: modelData.label + (chosen ? "  ✓ in use" : "")
                subtitle: modelData.note + (installed ? "" : " Not installed (" + modelData.pkg + ").")
                icon: chosen ? "radio_button_checked" : "radio_button_unchecked"
                Row {
                    spacing: 6
                    FButton {
                        visible: !fp.installed
                        text: "Install"
                        variant: "tonal"
                        onClicked: page.install([fp.modelData.pkg])
                    }
                    FButton {
                        visible: fp.installed
                        text: fp.chosen ? "In use" : "Use"
                        variant: fp.chosen ? "outlined" : "filled"
                        disabled: fp.chosen || applier.running
                        onClicked: {
                            page.fileChooser = fp.modelData.value;
                            page.apply();
                        }
                    }
                }
            }
        }

        SettingRow {
            title: "Use it in every GTK app"
            subtitle: "Portal-aware apps (Flatpaks, Firefox, Chromium, Electron) always use the picker above. This also routes regular GTK apps through it (GTK_USE_PORTAL / GDK_DEBUG=portals in niri's environment; log in again to apply). Qt apps keep their own dialog so qt6ct theming keeps working."
            icon: "select_all"
            FSwitch {
                checked: page.gtkUsePortal
                onToggled: c => {
                    page.gtkUsePortal = c;
                    page.apply();
                }
            }
        }
    }

    // ── what's installed ──
    Group {
        title: "Screen sharing setups"
        SettingRow {
            title: "Lightweight"
            subtitle: "wlr for screen sharing and screenshots (whole screens), gtk for file pickers. No GNOME libraries."
            icon: "feather"
            Row {
                spacing: 6
                FButton {
                    visible: !page.names.includes("wlr") || !page.names.includes("gtk")
                    text: "Install"
                    variant: "tonal"
                    onClicked: page.install(["xdg-desktop-portal-wlr", "xdg-desktop-portal-gtk", "slurp"])
                }
                FButton {
                    text: "Use"
                    disabled: !page.names.includes("wlr")
                    onClicked: {
                        page.screenCast = "wlr";
                        page.screenshot = "wlr";
                        page.fileChooser = page.names.includes("gtk") ? "gtk" : "";
                        page.fallback = "gtk";
                        page.apply();
                    }
                }
            }
        }
        SettingRow {
            title: "Full"
            subtitle: "gnome for screen sharing, including single windows. Pulls in GNOME libraries."
            icon: "select_window"
            Row {
                spacing: 6
                FButton {
                    visible: !page.names.includes("gnome")
                    text: "Install"
                    variant: "tonal"
                    onClicked: page.install(["xdg-desktop-portal-gnome", "xdg-desktop-portal-gtk"])
                }
                FButton {
                    text: "Use"
                    disabled: !page.names.includes("gnome")
                    onClicked: {
                        page.screenCast = "gnome";
                        page.screenshot = "gnome";
                        page.fileChooser = page.names.includes("gtk") ? "gtk" : "gnome";
                        page.fallback = "gtk";
                        page.apply();
                    }
                }
            }
        }
        SettingRow {
            visible: page.loaded && page.st.installed.length === 0
            title: "No portal backends found"
            subtitle: "Install one of the setups above"
            icon: "warning"
        }
    }

    // ── per feature ──
    Group {
        title: "Backends"
        SettingRow {
            title: "Screen sharing"
            subtitle: "Video calls, OBS, browser screen sharing"
            icon: "screen_share"
            FDropdown {
                implicitWidth: 340
                options: page.optionsFor("ScreenCast")
                current: page.screenCast
                onSelected: v => page.screenCast = v
            }
        }
        SettingRow {
            title: "Screenshots"
            subtitle: "Screenshots requested by apps"
            icon: "screenshot_monitor"
            FDropdown {
                implicitWidth: 340
                options: page.optionsFor("Screenshot")
                current: page.screenshot
                onSelected: v => page.screenshot = v
            }
        }
        SettingRow {
            title: "File chooser"
            subtitle: "Open / save dialogs in sandboxed and portal-aware apps"
            icon: "folder_open"
            FDropdown {
                implicitWidth: 340
                options: page.optionsFor("FileChooser")
                current: page.fileChooser
                onSelected: v => page.fileChooser = v
            }
        }
        SettingRow {
            title: "Everything else"
            subtitle: "Dark-mode preference, notifications and other portals"
            icon: "apps"
            FDropdown {
                implicitWidth: 340
                options: page.st.installed.filter(p => !["wlr"].includes(p.name)).map(p => ({ value: p.name, label: p.name }))
                current: page.fallback
                onSelected: v => page.fallback = v
            }
        }
    }

    // ── wlr options ──
    Group {
        visible: page.usesWlr
        title: "wlr screen picker"
        SettingRow {
            title: "Screen to share"
            subtitle: page.wlrOutput ? "Always shares this screen, no prompt" : "Click the screen to share when an app asks (needs slurp)"
            icon: "monitor"
            FDropdown {
                implicitWidth: 300
                options: [{ value: "", label: "Ask each time" }].concat(Displays.outputs.filter(o => o.enabled).map(o => ({ value: o.name, label: o.name + (o.make || o.model ? " · " + (o.make + " " + o.model).trim() : "") })))
                current: page.wlrOutput
                onSelected: v => page.wlrOutput = v
            }
        }
        SettingRow {
            title: "Frame rate limit"
            icon: "speed"
            FSegmented {
                implicitWidth: 300
                options: [{ value: 0, label: "No limit" }, { value: 30, label: "30 fps" }, { value: 60, label: "60 fps" }]
                current: page.maxFps
                onSelected: v => page.maxFps = v
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.sp3
        FButton {
            text: "Apply"
            icon: "check"
            disabled: applier.running || !page.loaded
            onClicked: page.apply()
        }
        FIconButton {
            icon: "refresh"
            onClicked: page.load()
        }
        FText {
            Layout.fillWidth: true
            text: page.status
            dim: true
            wrapMode: Text.Wrap
        }
    }

    FText {
        Layout.fillWidth: true
        text: "kde and cosmic are listed when installed, but their screen capture only works with their own compositors (KWin and cosmic-comp). The kde file chooser works fine on niri."
        dim: true
        wrapMode: Text.Wrap
        font.pixelSize: Theme.fsSm
    }
}
