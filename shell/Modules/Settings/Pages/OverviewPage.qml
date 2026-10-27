import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: I18n.tr("Overview")
    subtitle: I18n.tr("Flamenco's own overview, like GNOME's Activities: search apps, see this screen's workspaces and windows, and switch between them.")
    readonly property var o: Settings.data.overview

    Group {
        title: I18n.tr("Overview")
        SwitchRow {
            title: I18n.tr("Flamenco overview")
            subtitle: I18n.tr("The start button opens it instead of the launcher (right-click the start button for the other one)")
            icon: "overview_key"
            target: page.o
            key: "enabled"
        }
        SettingRow {
            title: I18n.tr("Preview")
            icon: "visibility"
            FButton {
                text: I18n.tr("Open the overview")
                variant: "tonal"
                icon: "overview_key"
                onClicked: {
                    Panels.settingsOpen = false;
                    Panels.open("overview", "");
                }
            }
        }
    }

    Group {
        title: I18n.tr("Super key")
        visible: page.o.enabled
        SwitchRow {
            title: I18n.tr("Tap Super to open it")
            subtitle: I18n.tr("Press Super and let go without another key. Super with another key still works as a shortcut.")
            icon: "keyboard_command_key"
            target: page.o
            key: "superKey"
        }
        SliderRow {
            visible: page.o.superKey
            title: I18n.tr("Longest tap")
            subtitle: I18n.tr("Holding Super longer than this doesn't open it")
            icon: "timer"
            target: page.o
            key: "superHold"
            from: 0.2
            to: 1.5
            stepSize: 0.1
            suffix: " s"
        }
        SettingRow {
            visible: page.o.superKey
            title: SuperKey.status === "ready" ? I18n.tr("Working") : SuperKey.status === "permission" ? I18n.tr("Needs keyboard access") : SuperKey.status === "no-keyboard" ? I18n.tr("No keyboard found") : SuperKey.status === "failed" ? I18n.tr("Stopped, restarting…") : I18n.tr("Starting…")
            subtitle: SuperKey.status === "permission"
                ? "niri and Hyprland run shortcuts as soon as a key goes down, so they can't tell Super alone from Super+T. Flamenco reads the keyboard itself for this, which needs the input group. Note that being in it lets any program you run read the keyboard."
                : SuperKey.status === "ready" ? "Tap Super to try it" : SuperKey.status === "no-keyboard" ? "Plug one in; it's picked up within a few seconds" : ""
            icon: SuperKey.status === "ready" ? "check_circle" : SuperKey.status === "permission" ? "lock" : "info"
            FButton {
                visible: SuperKey.status === "permission"
                text: I18n.tr("Join the input group")
                variant: "tonal"
                icon: "terminal"
                onClicked: Quickshell.execDetached(Paths.termHold('sudo usermod -aG input "$USER" && echo && echo "Done. Log out and back in for it to take effect."'))
            }
        }
    }

    Group {
        title: I18n.tr("Layout")
        visible: page.o.enabled
        SwitchRow { title: I18n.tr("Workspaces"); subtitle: I18n.tr("Along the top. Drop a window on one to move it there."); icon: "view_carousel"; target: page.o; key: "workspaces" }
        ChoiceRow {
            title: I18n.tr("Dash")
            subtitle: I18n.tr("Your dock's pinned apps and the running ones, along the bottom")
            icon: "dock_to_bottom"
            target: page.o
            key: "dash"
            segWidth: 140
            options: [{ value: "auto", label: I18n.tr("When no dock") }, { value: "always", label: I18n.tr("Always") }, { value: "never", label: I18n.tr("Never") }]
        }
        SwitchRow { title: I18n.tr("Window pictures"); subtitle: I18n.tr("Where the compositor lets Flamenco capture windows (not in a nested niri window); app icons otherwise"); icon: "picture_in_picture"; target: page.o; key: "previews" }
        SwitchRow { title: I18n.tr("Blurred wallpaper"); subtitle: I18n.tr("Off: a plain dimmed background"); icon: "blur_on"; target: page.o; key: "blur" }
    }

    Group {
        title: I18n.tr("App switcher")
        SettingRow {
            title: I18n.tr("Alt+Tab")
            subtitle: I18n.tr("Your windows as cards, most recent first. Hold Alt and press Tab to move, let go to switch.")
            icon: "select_window"
        }
        DropdownRow {
            title: I18n.tr("Layout")
            subtitle: ({ cards: I18n.tr("Cards in a row, the picked one lifted"), grid: I18n.tr("Bigger cards in rows (↑ ↓ move a row)"), list: I18n.tr("One window per line, with its workspace"),
                    icons: "Big app icons, the picked window's title under them", compact: "A slim pill of icons; the picked one opens up with its title",
                    fullmaterial: "The whole screen: a Material surface with your windows as big cards in a grid",
                    fullcards: "The whole screen: big cards in a row, the picked one forward and the rest set back",
                    android: "Like Android's Recents: tall cards side by side, the app above each; swipe one up (or Delete) to close it" })[Settings.data.switcher.layout || "cards"] ?? ""
            icon: "view_quilt"
            target: Settings.data.switcher
            key: "layout"
            options: [{ value: "cards", label: I18n.tr("Cards") }, { value: "grid", label: I18n.tr("Grid") }, { value: "list", label: I18n.tr("List") }, { value: "icons", label: I18n.tr("Icons") },
                { value: "compact", label: I18n.tr("Compact") }, { value: "fullmaterial", label: I18n.tr("Full screen · Material") }, { value: "fullcards", label: I18n.tr("Full screen · Cards") },
                { value: "android", label: I18n.tr("Android (Recents)") }]
        }
        ChoiceRow {
            title: I18n.tr("Style")
            subtitle: ({ tonal: I18n.tr("Material 3 tonal: the picked one tinted in your accent"), filled: I18n.tr("Material 3 filled: the picked one in your accent, solid"), outlined: I18n.tr("Material 3 outlined: see-through, outlined, the picked one in your accent") })[Settings.data.switcher.look || "tonal"] ?? ""
            icon: "style"
            target: Settings.data.switcher
            key: "look"
            segWidth: 100
            options: [{ value: "tonal", label: I18n.tr("Tonal") }, { value: "filled", label: I18n.tr("Filled") }, { value: "outlined", label: I18n.tr("Outlined") }]
        }
        SwitchRow {
            title: I18n.tr("Window previews")
            subtitle: I18n.tr("A picture of each window on its card, where the compositor allows capturing windows (Hyprland does; niri may show icons). Not in a nested niri window.")
            icon: "preview"
            target: Settings.data.switcher
            key: "previews"
        }
    }

    Group {
        title: I18n.tr("More ways to open it")
        SettingRow {
            title: I18n.tr("Start button")
            subtitle: I18n.tr("Its icon, label and what it opens are in Bar → Start button")
            icon: "toolbar"
            FButton {
                text: I18n.tr("Bar settings")
                variant: "text"
                onClicked: Panels.findSetting("bar", "Start button")
            }
        }
        SettingRow {
            title: I18n.tr("A shortcut or a screen corner")
            subtitle: "\"Overview (Flamenco)\" in Keyboard shortcuts and Screen edges. From a script: flamenco overview"
            icon: "keyboard"
        }
    }
}
