import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: "Screenshots"
    subtitle: Niri.hyprland ? "Screenshots with grim and slurp. They're copied to the clipboard and can be saved too." : "Screenshots with niri's own picker. They're copied to the clipboard and can be saved too."
    readonly property var s: Settings.data.screenshot

    Component.onCompleted: Compositor.load()

    // close settings first so it isn't in the picture
    function take(mode) {
        Panels.settingsOpen = false;
        shot.mode = mode;
        shot.restart();
    }

    Timer {
        id: shot
        property string mode
        interval: 450
        onTriggered: Quickshell.execDetached([Paths.bin, "screenshot", mode])
    }

    Group {
        title: "Take a screenshot"
        SettingRow {
            title: "Capture"
            subtitle: "Settings closes first" + (page.s.delay > 0 ? ", then waits " + page.s.delay + " s" : "")
            icon: "screenshot_monitor"
            RowLayout {
                spacing: 8
                FButton { text: "Area"; icon: "screenshot_region"; onClicked: page.take("region") }
                FButton { text: "Screen"; icon: "desktop_windows"; variant: "tonal"; onClicked: page.take("screen") }
                FButton { text: "Window"; icon: "web_asset"; variant: "tonal"; onClicked: page.take("window") }
            }
        }
    }

    Group {
        title: "Options"
        SwitchRow { title: "Include the pointer"; icon: "arrow_selector_tool"; target: page.s; key: "showPointer" }
        SwitchRow { title: "Save to a file"; subtitle: "Otherwise screenshots only go to the clipboard"; icon: "save"; target: page.s; key: "saveToDisk" }
        TextRow {
            title: "Save as"
            subtitle: "strftime codes like %Y-%m-%d work in the name"
            icon: "folder"
            visible: page.s.saveToDisk
            target: page.s
            key: "path"
            placeholder: "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"
            onEdited: Compositor.queue()
        }
        SliderRow { title: "Delay"; subtitle: "Wait before capturing the screen or window"; icon: "timer"; target: page.s; key: "delay"; from: 0; to: 10; stepSize: 1; suffix: " s" }
    }

    Group {
        title: "Shortcuts"
        SettingRow {
            title: "Print, Ctrl+Print, Alt+Print"
            subtitle: "Area, screen and window by default. Change them under Keyboard → Shortcuts, where they're listed as Flamenco functions"
            icon: "keyboard"
            FButton {
                text: "Shortcuts"
                variant: "tonal"
                onClicked: Panels.settingsPage = "keyboard"
            }
        }
        SettingRow {
            title: "From a terminal or script"
            subtitle: "flamenco screenshot [region|screen|window] [--delay N] [--no-save]"
            icon: "terminal"
        }
    }
}
