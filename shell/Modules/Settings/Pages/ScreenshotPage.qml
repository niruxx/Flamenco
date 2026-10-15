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

    // in a service: this page goes away while Settings is closed for the picture
    function take(mode) {
        Screenshot.fromSettings(mode);
    }

    Group {
        title: "Take a screenshot"
        SettingRow {
            title: "Take one now"
            subtitle: "Settings steps aside" + (page.s.delay > 0 ? ", waits " + page.s.delay + " s," : "") + " and comes back when it's taken"
            icon: "screenshot_monitor"
            RowLayout {
                spacing: 8
                FButton { text: "Capture an area"; icon: "screenshot_region"; variant: "tonal"; onClicked: page.take("region") }
                FButton { text: "Capture the screen"; icon: "desktop_windows"; variant: "tonal"; onClicked: page.take("screen") }
                FButton { text: "Capture a window"; icon: "web_asset"; variant: "tonal"; onClicked: page.take("window") }
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

    Group {
        title: "Screen recording"
        SettingRow {
            title: Recorder.recording ? "Recording · " + Recorder.clock : "Start recording now"
            subtitle: Recorder.recording ? Paths.fileName(Recorder.file) : "Settings closes and recording starts. The bar shows a red timer; click it to stop. Needs wf-recorder or gpu-screen-recorder."
            icon: Recorder.recording ? "stop_circle" : "screen_record"
            Row {
                spacing: 8
                FButton {
                    visible: !Recorder.recording
                    text: "Record the screen"
                    icon: "screen_record"
                    variant: "tonal"
                    onClicked: {
                        Panels.settingsOpen = false;
                        Recorder.start("screen", "");
                    }
                }
                FButton {
                    visible: !Recorder.recording
                    text: "Record an area"
                    icon: "crop"
                    variant: "tonal"
                    onClicked: {
                        Panels.settingsOpen = false;
                        Recorder.start("region", "");
                    }
                }
                FButton {
                    visible: Recorder.recording
                    text: "Stop"
                    icon: "stop"
                    onClicked: Recorder.stop()
                }
            }
        }
        DropdownRow {
            title: "Recorder"
            subtitle: "wf-recorder works on niri and Hyprland without prompts; gpu-screen-recorder is lighter on the CPU"
            icon: "videocam"
            target: Settings.data.record
            key: "backend"
            options: [{ value: "auto", label: "Automatic" }, { value: "wf-recorder", label: "wf-recorder" }, { value: "gpu-screen-recorder", label: "gpu-screen-recorder" }]
        }
        ChoiceRow {
            title: "Sound"
            subtitle: Settings.data.record.audio === "both" ? "Both need gpu-screen-recorder; wf-recorder records the microphone only" : ""
            icon: "graphic_eq"
            target: Settings.data.record
            key: "audio"
            options: [{ value: "none", label: "None" }, { value: "desktop", label: "Desktop" }, { value: "mic", label: "Mic" }, { value: "both", label: "Both" }]
        }
        SliderRow { title: "Frame rate"; icon: "speed"; target: Settings.data.record; key: "fps"; from: 15; to: 144; stepSize: 1; suffix: " fps" }
        TextRow { title: "Save to"; icon: "folder"; target: Settings.data.record; key: "dir"; placeholder: "~/Videos/Recordings" }
        SettingRow {
            title: "Shortcuts"
            subtitle: "Flamenco functions \"Record the screen\" and \"Record an area\" (press again to stop), under Keyboard → Shortcuts. Or: flamenco record toggle [screen|region]"
            icon: "keyboard"
        }
    }
}
