import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: "Launcher"
    subtitle: "Type  =  for the calculator,  >  to run a command,  ;  to search clipboard history,  /  for files. Searching also finds open windows, settings and session actions."
    readonly property var l: Settings.data.launcher

    Group {
        title: "Launcher app"
        ChoiceRow {
            title: "Open apps with"
            subtitle: page.l.backend === "fuzzel"
                ? (Fuzzel.found ? "fuzzel, in your theme's colors, fonts and corners (redone whenever the theme changes). The = > ; : # extras below are Flamenco's own and not in fuzzel"
                    : "fuzzel isn't installed, so Flamenco's launcher opens for now (Settings → System check)")
                : "Flamenco's launcher: apps, the calculator, commands, clipboard, emoji and colors"
            icon: "apps"
            target: page.l
            key: "backend"
            segWidth: 120
            options: [{ value: "flamenco", label: "Flamenco", icon: "local_fire_department" }, { value: "fuzzel", label: "fuzzel", icon: "search" }]
        }
        SettingRow {
            visible: page.l.backend === "fuzzel" && Fuzzel.found
            title: "Try it"
            subtitle: "Its config is " + Fuzzel.path + "; your own ~/.config/fuzzel is left alone. Position, width and results below apply to it too"
            icon: "play_arrow"
            FButton {
                text: Fuzzel.running ? "Close fuzzel" : "Open fuzzel"
                variant: "tonal"
                onClicked: Fuzzel.toggle()
            }
        }
    }

    Group {
        title: "Placement"
        DropdownRow {
            title: "Position"
            subtitle: "Where the launcher opens on screen"
            icon: "picture_in_picture"
            target: page.l
            key: "position"
            options: [
                { value: "center", label: "Center" },
                { value: "top", label: "Top" },
                { value: "bottom", label: "Bottom" },
                { value: "top-left", label: "Top left" },
                { value: "top-right", label: "Top right" },
                { value: "bottom-left", label: "Bottom left" },
                { value: "bottom-right", label: "Bottom right" },
                { value: "bar", label: "Next to the bar (start)" }
            ]
        }
        SliderRow { title: "Width"; icon: "width"; target: page.l; key: "width"; from: 420; to: 960; stepSize: 20; suffix: "px" }
        SettingRow {
            title: "Preview"
            icon: "visibility"
            FButton {
                text: "Open launcher"
                variant: "tonal"
                icon: "apps"
                onClicked: Panels.open("launcher", "")
            }
        }
    }

    Group {
        title: "Search"
        ChoiceRow {
            title: "View"
            subtitle: (page.l.view || "list") === "grid" ? "Apps as a grid with categories until you type, then the list of results" : "A list of apps, most used first"
            icon: "apps"
            target: page.l
            key: "view"
            segWidth: 100
            options: [{ value: "list", label: "List", icon: "view_list" }, { value: "grid", label: "Grid", icon: "grid_view" }]
        }
        SettingRow {
            title: "Pinned apps"
            subtitle: (page.l.pinned || []).length ? (page.l.pinned || []).map(id => Apps.all.find(e => e.id === id)?.name ?? id).join(", ") + ". First when nothing's typed" : "Alt+P or right-click an app in the launcher pins it; pinned apps come first"
            icon: "keep"
            FButton { visible: (page.l.pinned || []).length > 0; text: "Unpin all"; variant: "text"; onClicked: page.l.pinned = [] }
        }
        SwitchRow { title: "Open windows"; subtitle: "Typing finds windows by title or app, Enter switches to it"; icon: "select_window"; target: page.l; key: "searchWindows" }
        SwitchRow { title: "Settings"; subtitle: "Flamenco's pages and options, Enter opens it"; icon: "settings"; target: page.l; key: "searchSettings" }
        SwitchRow { title: "Session actions"; subtitle: "Lock, suspend, hibernate; log out, restart and shut down open the power menu to confirm"; icon: "power_settings_new"; target: page.l; key: "searchSession" }
        SwitchRow { title: "Files"; subtitle: "Type / and a name to find files and folders in your home folder (instant with plocate)"; icon: "folder_open"; target: page.l; key: "files" }
        SwitchRow { title: "Web search"; subtitle: "\"Search the web for …\" last in the results"; icon: "travel_explore"; target: page.l; key: "webSearch" }
        DropdownRow {
            visible: page.l.webSearch
            title: "Search engine"
            icon: "public"
            target: page.l
            key: "webEngine"
            options: [{ value: "duckduckgo", label: "DuckDuckGo" }, { value: "google", label: "Google" }, { value: "bing", label: "Bing" },
                { value: "brave", label: "Brave Search" }, { value: "startpage", label: "Startpage" }, { value: "ecosia", label: "Ecosia" }]
        }
    }

    Group {
        title: "Behaviour"
        SliderRow { title: "Visible results"; icon: "format_list_numbered"; target: page.l; key: "maxResults"; from: 4; to: 14; stepSize: 1 }
        SwitchRow { title: "Calculator"; icon: "calculate"; target: page.l; key: "calculator" }
        SwitchRow { title: "Clipboard in the launcher"; subtitle: "Type ; to search the clipboard history"; icon: "content_paste"; target: page.l; key: "clipboard" }
        SwitchRow { title: "Emoji"; subtitle: "Type : and a name, Enter copies it. Recently used come first."; icon: "mood"; target: page.l; key: "emoji" }
        SwitchRow { title: "Colors"; subtitle: "Type # for a color picker on screen, or # and a hex code for its RGB and HSL"; icon: "palette"; target: page.l; key: "colors" }
        TextRow { title: "Terminal"; subtitle: "Used for terminal apps and > commands"; icon: "terminal"; target: Settings.data.general; key: "terminal"; placeholder: "kitty" }
    }

    Group {
        title: "Clipboard history"
        SettingRow {
            title: !Clipboard.available ? "Needs cliphist and wl-clipboard" : Clipboard.othersWatching ? "Recorded by something else" : Clipboard.watching ? "Recording" : "Off"
            subtitle: !Clipboard.available ? "sudo pacman -S cliphist wl-clipboard" : Clipboard.othersWatching ? "A wl-paste … cliphist store started elsewhere (your compositor config) keeps it" : Clipboard.entries.length + " items. Add \"Clipboard history\" to the bar (Settings → Bar) for a button that opens it."
            icon: "content_paste"
            FButton {
                text: "Open"
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
            title: "Keep a clipboard history"
            subtitle: "Flamenco records what you copy, text and images, with cliphist"
            icon: "history"
            target: Settings.data.clipboard
            key: "watch"
        }
        SliderRow { title: "Items to keep"; icon: "format_list_numbered"; target: Settings.data.clipboard; key: "maxItems"; from: 50; to: 2000; stepSize: 50 }
        SettingRow {
            title: "Clear the history"
            subtitle: "Removes everything cliphist has kept"
            icon: "delete_sweep"
            FButton {
                id: clearBtn
                property bool sure: false
                text: sure ? "Clear all?" : "Clear"
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
