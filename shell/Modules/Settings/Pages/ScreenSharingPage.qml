import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services
import qs.Widgets

// Screen sharing (GNOME's or wlr's portal) and the file picker, written to
// ~/.config/xdg-desktop-portal/niri-portals.conf. Apply restarts the portals, so
// the choice works right away: no logging out.
Page {
    id: page
    title: I18n.tr("Screen sharing & files")
    subtitle: I18n.tr("Apps share your screen and open file pickers through xdg-desktop-portal. Pick how screens are shared and which file picker apps get.")

    property var st: ({ installed: [], current: {}, packages: {}, wlr: {} })
    property bool loaded: false
    property string status: ""

    // draft
    property string screenCast: ""             // gnome | wlr
    property string fileChooser: ""
    property string wlrOutput: ""
    property string wlrChooser: "flamenco"   // flamenco (the "Share your screen" window) | slurp (click a screen)
    readonly property bool hypr: Niri.hyprland
    property int maxFps: 0
    property bool forceLinear: false
    property bool gtkUsePortal: false

    readonly property var sharers: [
        { value: "gnome", label: I18n.tr("GNOME"), pkg: "xdg-desktop-portal-gnome", icon: "select_window",
          note: I18n.tr("Whole screens and single windows, with GNOME's own picker. Pulls in some GNOME libraries.") },
        { value: "wlr", label: I18n.tr("wlr"), pkg: "xdg-desktop-portal-wlr", icon: "feather",
          note: I18n.tr("Whole screens, picked in Flamenco's \"Share your screen\" window. Very light.") }
    ]
    readonly property var pickers: [
        { value: "gtk", label: I18n.tr("GTK"), pkg: "xdg-desktop-portal-gtk", note: I18n.tr("The standard GTK dialog. Light.") },
        { value: "kde", label: I18n.tr("Qt (KDE)"), pkg: "xdg-desktop-portal-kde", note: I18n.tr("KDE's Qt dialog with Dolphin-style places.") },
        { value: "gnome", label: I18n.tr("GNOME"), pkg: "xdg-desktop-portal-gnome", note: I18n.tr("GNOME's dialog (pulls in GNOME libraries).") },
        { value: "cosmic", label: I18n.tr("COSMIC"), pkg: "xdg-desktop-portal-cosmic", note: I18n.tr("COSMIC Files' dialog.") }
    ]

    readonly property var names: st.installed.map(p => p.name)
    readonly property bool usesWlr: screenCast === "wlr"
    readonly property var picker: pickers.find(p => p.value === fileChooser) ?? null
    readonly property bool ready: !!screenCast && names.includes(screenCast) && (!fileChooser || names.includes(fileChooser))

    function load() {
        if (!getter.running)
            getter.running = true;
    }

    function apply() {
        // other portals (dark mode, notifications…) go to GTK when it's there, else the file picker's
        const fallback = names.includes("gtk") ? "gtk" : (fileChooser || "gtk");
        const spec = { default: fallback, ScreenCast: screenCast, Screenshot: screenCast, FileChooser: fileChooser, wlrOutput: wlrOutput, wlrChooser: wlrChooser, maxFps: maxFps, forceLinear: forceLinear, gtkUsePortal: gtkUsePortal };
        status = I18n.tr("Applying and restarting the portals…");
        applier.command = [Paths.bin, "portals", "apply", "--json", JSON.stringify(spec)];
        applier.running = true;
    }

    function install(pkgs) {
        installer.command = Paths.termHold("sudo pacman -S --needed " + pkgs.join(" "));
        installer.running = true;
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
                    const cast = d.current.ScreenCast ?? "";
                    page.screenCast = cast === "gnome" || cast === "wlr" ? cast : "";
                    page.fileChooser = d.current.FileChooser ?? "";
                    page.wlrOutput = d.wlr.output_name ?? "";
                    page.wlrChooser = (d.wlr.chooser_type ?? "dmenu") === "simple" ? "slurp" : "flamenco";
                    page.maxFps = parseInt(d.wlr.max_fps ?? "0") || 0;
                    page.forceLinear = (d.wlr.force_mod_linear ?? "0") === "1";
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
            onStreamFinished: {
                const t = text.trim().split("\n").pop() || "";
                page.status = t.indexOf("ready now") >= 0 ? I18n.tr("Done: you can share your screen now. Apps that were already open pick it up the next time they ask.") : t.replace(/^portals: /, "");
            }
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) page.status = text.trim().split("\n").pop().replace(/^flamenco: /, "")
        }
        onExited: page.load()
    }

    // the terminal for installing: look again once it's closed
    Process {
        id: installer
        onExited: page.load()
    }

    // ── screen sharing ──
    Group {
        title: I18n.tr("Screen sharing")

        Repeater {
            model: page.sharers
            SettingRow {
                id: sh
                required property var modelData
                readonly property bool installed: page.names.includes(modelData.value)
                readonly property bool chosen: page.screenCast === modelData.value
                readonly property bool inUse: (page.st.current.ScreenCast ?? "") === modelData.value
                title: modelData.label + (inUse ? I18n.tr("  ✓ in use") : "")
                subtitle: modelData.note + (installed ? "" : I18n.tr(" Not installed (") + modelData.pkg + ").")
                    + (page.hypr && modelData.value === "gnome" ? I18n.tr(" Note: GNOME's portal can't capture on Hyprland.") : "")
                icon: chosen ? "radio_button_checked" : "radio_button_unchecked"
                Row {
                    spacing: 6
                    FButton {
                        visible: !sh.installed
                        text: I18n.tr("Install")
                        variant: "tonal"
                        disabled: installer.running
                        onClicked: page.install(sh.modelData.value === "wlr" ? [sh.modelData.pkg, "slurp"] : [sh.modelData.pkg])
                    }
                    FButton {
                        visible: sh.installed
                        text: sh.chosen ? I18n.tr("Selected") : I18n.tr("Select")
                        variant: sh.chosen ? "outlined" : "tonal"
                        disabled: sh.chosen
                        onClicked: page.screenCast = sh.modelData.value
                    }
                }
            }
        }
    }

    // ── wlr options ──
    Group {
        visible: page.usesWlr
        title: "wlr screen picker"
        SettingRow {
            visible: !page.wlrOutput
            title: I18n.tr("Ask with")
            subtitle: page.wlrChooser === "flamenco" ? I18n.tr("Flamenco's \"Share your screen\" window: every screen with a live picture, pick one (or Esc to refuse)") : I18n.tr("Click the screen to share (needs slurp)")
            icon: "ads_click"
            FSegmented {
                implicitWidth: 300
                options: [{ value: "flamenco", label: I18n.tr("Flamenco window") }, { value: "slurp", label: I18n.tr("Click a screen") }]
                current: page.wlrChooser
                onSelected: v => page.wlrChooser = v
            }
        }
        SettingRow {
            title: I18n.tr("Screen to share")
            subtitle: page.wlrOutput ? I18n.tr("Always shares this screen, no prompt") : I18n.tr("Asks each time an app wants to share")
            icon: "monitor"
            FDropdown {
                implicitWidth: 300
                options: [{ value: "", label: I18n.tr("Ask each time") }].concat(Displays.outputs.filter(o => o.enabled).map(o => ({ value: o.name, label: o.name + (o.make || o.model ? " · " + (o.make + " " + o.model).trim() : "") })))
                current: page.wlrOutput
                onSelected: v => page.wlrOutput = v
            }
        }
        SettingRow {
            title: I18n.tr("Compatibility mode")
            subtitle: I18n.tr("If the shared screen freezes on its first picture: plain (linear) video buffers, which more GPUs, drivers and apps accept (xdg-desktop-portal-wlr's force_mod_linear). Press Apply, then start sharing again")
            icon: "build"
            FSwitch {
                checked: page.forceLinear
                onToggled: c => page.forceLinear = c
            }
        }
        SettingRow {
            title: I18n.tr("Frame rate limit")
            icon: "speed"
            FSegmented {
                implicitWidth: 300
                options: [{ value: 0, label: I18n.tr("No limit") }, { value: 30, label: I18n.tr("30 fps") }, { value: 60, label: I18n.tr("60 fps") }]
                current: page.maxFps
                onSelected: v => page.maxFps = v
            }
        }
    }


    // ── file picker ──
    Group {
        title: I18n.tr("File picker")

        SettingRow {
            title: I18n.tr("File picker")
            subtitle: page.picker ? page.picker.note + (page.names.includes(page.picker.value) ? "" : I18n.tr(" Not installed (") + page.picker.pkg + ").")
                : I18n.tr("Open / save dialogs in Flatpaks, browsers and other portal-aware apps")
            icon: "folder_open"
            Row {
                spacing: 6
                FButton {
                    visible: !!page.picker && !page.names.includes(page.picker.value)
                    text: I18n.tr("Install")
                    variant: "tonal"
                    implicitHeight: 38
                    disabled: installer.running
                    onClicked: page.install([page.picker.pkg])
                }
                FDropdown {
                    implicitWidth: 240
                    options: page.pickers.map(p => ({ value: p.value, label: p.label + (page.names.includes(p.value) ? "" : I18n.tr(" (not installed)")) }))
                    current: page.fileChooser
                    placeholder: I18n.tr("Choose a file picker…")
                    onSelected: v => page.fileChooser = v
                }
            }
        }

        SettingRow {
            title: I18n.tr("Use it in every GTK app")
            subtitle: I18n.tr("Portal-aware apps (Flatpaks, Firefox, Chromium, Electron) always use the picker above. This also routes regular GTK apps through it (GTK_USE_PORTAL / GDK_DEBUG=portals in niri's environment; log in again to apply). Qt apps keep their own dialog so qt6ct theming keeps working.")
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

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.sp3
        FButton {
            text: I18n.tr("Apply")
            icon: "check"
            disabled: applier.running || !page.loaded || !page.ready
            onClicked: page.apply()
        }
        FIconButton {
            icon: "refresh"
            onClicked: page.load()
        }
        // what's actually serving screen sharing, and the portals' logs (for a frozen or failing share)
        FButton {
            text: I18n.tr("Diagnose")
            icon: "troubleshoot"
            variant: "text"
            onClicked: Quickshell.execDetached(Paths.termHold(Paths.shellQuote(Paths.bin) + " portals diagnose"))
        }
        FText {
            Layout.fillWidth: true
            text: page.status
            dim: true
            wrapMode: Text.Wrap
        }
    }
}
