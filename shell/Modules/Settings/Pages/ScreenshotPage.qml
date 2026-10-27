import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: I18n.tr("Screenshots")
    subtitle: Niri.hyprland ? I18n.tr("Screenshots with grim and slurp. They're copied to the clipboard and can be saved too.") : I18n.tr("Screenshots with niri's own picker. They're copied to the clipboard and can be saved too.")
    readonly property var s: Settings.data.screenshot

    Component.onCompleted: Compositor.load()

    // in a service: this page goes away while Settings is closed for the picture
    function take(mode) {
        Screenshot.fromSettings(mode);
    }

    Group {
        title: I18n.tr("Take a screenshot")
        SettingRow {
            title: I18n.tr("Take one now")
            subtitle: I18n.tr("Settings steps aside") + (page.s.delay > 0 ? ", waits " + page.s.delay + " s," : "") + " and comes back when it's taken"
            icon: "screenshot_monitor"
            RowLayout {
                spacing: 8
                FButton { text: I18n.tr("Capture an area"); icon: "screenshot_region"; variant: "tonal"; onClicked: page.take("region") }
                FButton { text: I18n.tr("Capture the screen"); icon: "desktop_windows"; variant: "tonal"; onClicked: page.take("screen") }
                FButton { text: I18n.tr("Capture a window"); icon: "web_asset"; variant: "tonal"; onClicked: page.take("window") }
            }
        }
    }

    Group {
        title: I18n.tr("Options")
        SwitchRow { title: I18n.tr("Include the pointer"); icon: "arrow_selector_tool"; target: page.s; key: "showPointer" }
        SwitchRow { title: I18n.tr("Save to a file"); subtitle: I18n.tr("Otherwise screenshots only go to the clipboard"); icon: "save"; target: page.s; key: "saveToDisk" }
        TextRow {
            title: I18n.tr("Save as")
            subtitle: "strftime codes like %Y-%m-%d work in the name"
            icon: "folder"
            visible: page.s.saveToDisk
            target: page.s
            key: "path"
            placeholder: "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"
            onEdited: Compositor.queue()
        }
        SliderRow { title: I18n.tr("Delay"); subtitle: I18n.tr("Wait before capturing the screen or window"); icon: "timer"; target: page.s; key: "delay"; from: 0; to: 10; stepSize: 1; suffix: " s" }
    }

    Group {
        title: I18n.tr("Shortcuts")
        SettingRow {
            title: I18n.tr("Print, Ctrl+Print, Alt+Print")
            subtitle: I18n.tr("Area, screen and window by default. Change them under Keyboard → Shortcuts, where they're listed as Flamenco functions")
            icon: "keyboard"
            FButton {
                text: I18n.tr("Shortcuts")
                variant: "tonal"
                onClicked: Panels.settingsPage = "keyboard"
            }
        }
        SettingRow {
            title: I18n.tr("From a terminal or script")
            subtitle: "flamenco screenshot [region|screen|window] [--delay N] [--no-save]"
            icon: "terminal"
        }
    }

    Group {
        title: I18n.tr("Screen recording")
        SettingRow {
            title: Recorder.recording ? I18n.tr("Recording · ") + Recorder.clock : I18n.tr("Start recording now")
            subtitle: Recorder.recording ? Paths.fileName(Recorder.file) : I18n.tr("Settings closes and recording starts. The bar shows a red timer; click it to stop. Needs wf-recorder or gpu-screen-recorder.")
            icon: Recorder.recording ? "stop_circle" : "screen_record"
            Row {
                spacing: 8
                FButton {
                    visible: !Recorder.recording
                    text: I18n.tr("Record the screen")
                    icon: "screen_record"
                    variant: "tonal"
                    onClicked: {
                        Panels.settingsOpen = false;
                        Recorder.start("screen", "");
                    }
                }
                FButton {
                    visible: !Recorder.recording
                    text: I18n.tr("Record an area")
                    icon: "crop"
                    variant: "tonal"
                    onClicked: {
                        Panels.settingsOpen = false;
                        Recorder.start("region", "");
                    }
                }
                FButton {
                    visible: Recorder.recording
                    text: I18n.tr("Stop")
                    icon: "stop"
                    onClicked: Recorder.stop()
                }
            }
        }
        DropdownRow {
            title: I18n.tr("Recorder")
            subtitle: "wf-recorder works on niri and Hyprland without prompts; gpu-screen-recorder is lighter on the CPU"
            icon: "videocam"
            target: Settings.data.record
            key: "backend"
            options: [{ value: "auto", label: I18n.tr("Automatic") }, { value: "wf-recorder", label: I18n.tr("wf-recorder") }, { value: "gpu-screen-recorder", label: I18n.tr("gpu-screen-recorder") }]
        }
        ChoiceRow {
            title: I18n.tr("Sound")
            subtitle: Settings.data.record.audio === "both" ? I18n.tr("Both need gpu-screen-recorder; wf-recorder records the microphone only") : ""
            icon: "graphic_eq"
            target: Settings.data.record
            key: "audio"
            options: [{ value: "none", label: I18n.tr("None") }, { value: "desktop", label: I18n.tr("Desktop") }, { value: "mic", label: I18n.tr("Mic") }, { value: "both", label: I18n.tr("Both") }]
        }
        SliderRow { title: I18n.tr("Frame rate"); icon: "speed"; target: Settings.data.record; key: "fps"; from: 15; to: 144; stepSize: 1; suffix: " fps" }
        TextRow { title: I18n.tr("Save to"); icon: "folder"; target: Settings.data.record; key: "dir"; placeholder: I18n.tr("~/Videos/Recordings") }
        SettingRow {
            title: I18n.tr("Shortcuts")
            subtitle: I18n.tr("Flamenco functions \"Record the screen\" and \"Record an area\" (press again to stop), under Keyboard → Shortcuts. Or: flamenco record toggle [screen|region]")
            icon: "keyboard"
        }
    }
}
