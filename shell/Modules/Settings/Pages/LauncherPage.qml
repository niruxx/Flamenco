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
        SwitchRow { title: "Clipboard history"; subtitle: "Requires cliphist and wl-clipboard"; icon: "content_paste"; target: page.l; key: "clipboard" }
        SwitchRow { title: "Emoji"; subtitle: "Type : and a name, Enter copies it. Recently used come first."; icon: "mood"; target: page.l; key: "emoji" }
        SwitchRow { title: "Colors"; subtitle: "Type # for a color picker on screen, or # and a hex code for its RGB and HSL"; icon: "palette"; target: page.l; key: "colors" }
        TextRow { title: "Terminal"; subtitle: "Used for terminal apps and > commands"; icon: "terminal"; target: Settings.data.general; key: "terminal"; placeholder: "kitty" }
    }
}
