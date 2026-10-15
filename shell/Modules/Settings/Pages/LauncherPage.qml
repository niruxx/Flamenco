import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: "Launcher"
    subtitle: "Type  =  for the calculator,  >  to run a command,  ;  to search clipboard history."
    readonly property var l: Settings.data.launcher

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
