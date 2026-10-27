import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: I18n.tr("Launcher")
    subtitle: I18n.tr("Type  =  for the calculator,  >  to run a command,  ;  to search clipboard history,  /  for files. Searching also finds open windows, settings and session actions.")
    readonly property var l: Settings.data.launcher

    Group {
        title: I18n.tr("Launcher app")
        ChoiceRow {
            title: I18n.tr("Open apps with")
            subtitle: page.l.backend === "fuzzel"
                ? (Fuzzel.found ? "fuzzel, in your theme's colors, fonts and corners (redone whenever the theme changes). The = > ; : # extras below are Flamenco's own and not in fuzzel"
                    : "fuzzel isn't installed, so Flamenco's launcher opens for now (Settings → System check)")
                : "Flamenco's launcher: apps, the calculator, commands, clipboard, emoji and colors"
            icon: "apps"
            target: page.l
            key: "backend"
            segWidth: 120
            options: [{ value: "flamenco", label: I18n.tr("Flamenco"), icon: "local_fire_department" }, { value: "fuzzel", label: I18n.tr("fuzzel"), icon: "search" }]
        }
        SettingRow {
            visible: page.l.backend === "fuzzel" && Fuzzel.found
            title: I18n.tr("Try it")
            subtitle: I18n.tr("Its config is ") + Fuzzel.path + "; your own ~/.config/fuzzel is left alone. Position, width and results below apply to it too"
            icon: "play_arrow"
            FButton {
                text: Fuzzel.running ? I18n.tr("Close fuzzel") : I18n.tr("Open fuzzel")
                variant: "tonal"
                onClicked: Fuzzel.toggle()
            }
        }
    }

    Group {
        title: I18n.tr("Placement")
        DropdownRow {
            title: I18n.tr("Position")
            subtitle: I18n.tr("Where the launcher opens on screen")
            icon: "picture_in_picture"
            target: page.l
            key: "position"
            options: [
                { value: "center", label: I18n.tr("Center") },
                { value: "top", label: I18n.tr("Top") },
                { value: "bottom", label: I18n.tr("Bottom") },
                { value: "top-left", label: I18n.tr("Top left") },
                { value: "top-right", label: I18n.tr("Top right") },
                { value: "bottom-left", label: I18n.tr("Bottom left") },
                { value: "bottom-right", label: I18n.tr("Bottom right") },
                { value: "bar", label: I18n.tr("Next to the bar (start)") }
            ]
        }
        SliderRow { title: I18n.tr("Width"); icon: "width"; target: page.l; key: "width"; from: 420; to: 960; stepSize: 20; suffix: "px" }
        SettingRow {
            title: I18n.tr("Preview")
            icon: "visibility"
            FButton {
                text: I18n.tr("Open launcher")
                variant: "tonal"
                icon: "apps"
                onClicked: Panels.open("launcher", "")
            }
        }
    }

    Group {
        title: I18n.tr("Search")
        ChoiceRow {
            title: I18n.tr("View")
            subtitle: (page.l.view || "list") === "grid" ? I18n.tr("Apps as a grid with categories until you type, then the list of results") : I18n.tr("A list of apps, most used first")
            icon: "apps"
            target: page.l
            key: "view"
            segWidth: 100
            options: [{ value: "list", label: I18n.tr("List"), icon: "view_list" }, { value: "grid", label: I18n.tr("Grid"), icon: "grid_view" }]
        }
        SettingRow {
            title: I18n.tr("Pinned apps")
            subtitle: (page.l.pinned || []).length ? (page.l.pinned || []).map(id => Apps.all.find(e => e.id === id)?.name ?? id).join(", ") + ". First when nothing's typed" : I18n.tr("Alt+P or right-click an app in the launcher pins it; pinned apps come first")
            icon: "keep"
            FButton { visible: (page.l.pinned || []).length > 0; text: I18n.tr("Unpin all"); variant: "text"; onClicked: page.l.pinned = [] }
        }
        SwitchRow { title: I18n.tr("Open windows"); subtitle: I18n.tr("Typing finds windows by title or app, Enter switches to it"); icon: "select_window"; target: page.l; key: "searchWindows" }
        SwitchRow { title: I18n.tr("Settings"); subtitle: I18n.tr("Flamenco's pages and options, Enter opens it"); icon: "settings"; target: page.l; key: "searchSettings" }
        SwitchRow { title: I18n.tr("Session actions"); subtitle: I18n.tr("Lock, suspend, hibernate; log out, restart and shut down open the power menu to confirm"); icon: "power_settings_new"; target: page.l; key: "searchSession" }
        SwitchRow { title: I18n.tr("Files"); subtitle: I18n.tr("Type / and a name to find files and folders in your home folder (instant with plocate)"); icon: "folder_open"; target: page.l; key: "files" }
        SwitchRow { title: I18n.tr("Web search"); subtitle: I18n.tr("\"Search the web for …\" last in the results"); icon: "travel_explore"; target: page.l; key: "webSearch" }
        DropdownRow {
            visible: page.l.webSearch
            title: I18n.tr("Search engine")
            icon: "public"
            target: page.l
            key: "webEngine"
            options: [{ value: "duckduckgo", label: I18n.tr("DuckDuckGo") }, { value: "google", label: I18n.tr("Google") }, { value: "bing", label: I18n.tr("Bing") },
                { value: "brave", label: I18n.tr("Brave Search") }, { value: "startpage", label: I18n.tr("Startpage") }, { value: "ecosia", label: I18n.tr("Ecosia") }]
        }
    }

    Group {
        title: I18n.tr("Behaviour")
        SliderRow { title: I18n.tr("Visible results"); icon: "format_list_numbered"; target: page.l; key: "maxResults"; from: 4; to: 14; stepSize: 1 }
        SwitchRow { title: I18n.tr("Calculator"); icon: "calculate"; target: page.l; key: "calculator" }
        SwitchRow { title: I18n.tr("Clipboard in the launcher"); subtitle: I18n.tr("Type ; to search the clipboard history"); icon: "content_paste"; target: page.l; key: "clipboard" }
        SwitchRow { title: I18n.tr("Emoji"); subtitle: I18n.tr("Type : and a name, Enter copies it. Recently used come first."); icon: "mood"; target: page.l; key: "emoji" }
        SwitchRow { title: I18n.tr("Colors"); subtitle: I18n.tr("Type # for a color picker on screen, or # and a hex code for its RGB and HSL"); icon: "palette"; target: page.l; key: "colors" }
        TextRow { title: I18n.tr("Terminal"); subtitle: I18n.tr("Used for terminal apps and > commands"); icon: "terminal"; target: Settings.data.general; key: "terminal"; placeholder: I18n.tr("kitty") }
    }

    Group {
        title: I18n.tr("Clipboard history")
        SettingRow {
            title: !Clipboard.available ? I18n.tr("Needs cliphist and wl-clipboard") : Clipboard.othersWatching ? I18n.tr("Recorded by something else") : Clipboard.watching ? I18n.tr("Recording") : I18n.tr("Off")
            subtitle: !Clipboard.available ? "sudo pacman -S cliphist wl-clipboard" : Clipboard.othersWatching ? I18n.tr("A wl-paste … cliphist store started elsewhere (your compositor config) keeps it") : Clipboard.entries.length + " items. Add \"Clipboard history\" to the bar (Settings → Bar) for a button that opens it."
            icon: "content_paste"
            FButton {
                text: I18n.tr("Open")
                variant: "tonal"
                disabled: !Clipboard.available
                onClicked: {
                    Panels.settingsOpen = false;
                    Panels.open("clipboard", "");
                }
            }
        }
        SwitchRow {
            visible: !Clipboard.othersWatching
            title: I18n.tr("Keep a clipboard history")
            subtitle: I18n.tr("Flamenco records what you copy, text and images, with cliphist")
            icon: "history"
            target: Settings.data.clipboard
            key: "watch"
        }
        SliderRow { title: I18n.tr("Items to keep"); icon: "format_list_numbered"; target: Settings.data.clipboard; key: "maxItems"; from: 50; to: 2000; stepSize: 50 }
        SettingRow {
            title: I18n.tr("Clear the history")
            subtitle: I18n.tr("Removes everything cliphist has kept")
            icon: "delete_sweep"
            FButton {
                id: clearBtn
                property bool sure: false
                text: sure ? I18n.tr("Clear all?") : I18n.tr("Clear")
                variant: sure ? "filled" : "tonal"
                disabled: Clipboard.entries.length === 0
                onClicked: {
                    if (sure) {
                        Clipboard.wipe();
                        sure = false;
                    } else {
                        sure = true;
                    }
                }
            }
        }
    }
}
