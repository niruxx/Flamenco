import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: "Bar"
    readonly property var b: Settings.data.bar
    readonly property var allWidgets: ({
            launcher: "Launcher", workspaces: "Workspaces", window: "Active window", taskbar: "Taskbar (running apps)", clock: "Clock", media: "Media",
            tray: "System tray", sysstats: "CPU / RAM", keyboard: "Keyboard layout", network: "Network", bluetooth: "Bluetooth",
            audio: "Volume", mic: "Microphone (while in use)", privacy: "Privacy (camera, screen sharing)", recording: "Screen recording (while recording)", brightness: "Brightness", battery: "Battery", notifications: "Notifications", weather: "Weather", quicksettings: "Quick settings", assistant: "AI assistant", power: "Power"
        })
    readonly property var used: b.left.concat(b.center, b.right)

    Group {
        title: "Layout"
        ChoiceRow {
            title: "Position"
            subtitle: "Left and right give a vertical bar"
            icon: "screenshot_frame"
            target: page.b
            key: "position"
            segWidth: 84
            options: [{ value: "top", label: "Top", icon: "border_top" }, { value: "bottom", label: "Bottom", icon: "border_bottom" }, { value: "left", label: "Left", icon: "border_left" }, { value: "right", label: "Right", icon: "border_right" }]
        }
        ChoiceRow { title: "Style"; icon: "style"; target: page.b; key: "style"; options: [{ value: "floating", label: "Floating" }, { value: "attached", label: "Attached" }, { value: "islands", label: "Islands" }] }
        SliderRow { title: "Thickness"; icon: "height"; target: page.b; key: "height"; from: 30; to: 56; stepSize: 1; suffix: "px" }
        ChoiceRow { title: "Workspace indicator"; icon: "view_week"; target: page.b; key: "workspaceStyle"; options: [{ value: "pills", label: "Pills" }, { value: "numbers", label: "Numbers" }, { value: "dots", label: "Dots" }] }
    }

    Group {
        title: "System tray (app indicators)"
        SwitchRow { title: "Hide passive icons"; subtitle: "Apps that mark themselves idle stay out of the bar"; icon: "visibility_off"; target: page.b; key: "trayHidePassive" }
        SliderRow { title: "Icons before overflow"; icon: "more_horiz"; target: page.b; key: "trayMaxVisible"; from: 2; to: 16; stepSize: 1 }
        SwitchRow { title: "Native Qt menus"; subtitle: "Use the app's own Qt menu instead of the themed one"; icon: "menu"; target: page.b; key: "trayNativeMenus" }
    }

    Group {
        title: "Microphone"
        SettingRow {
            visible: !page.used.includes("mic")
            title: "Not in the bar yet"
            subtitle: "Add \"Microphone (while in use)\" to a section below. Click it to mute or unmute."
            icon: "info"
        }
        ChoiceRow {
            title: "Show it"
            subtitle: Audio.micInUse ? "In use now by " + Audio.micUsers : "Nothing is recording right now"
            icon: "mic"
            target: page.b
            key: "micIndicator"
            segWidth: 150
            options: [{ value: "inuse", label: "While in use or muted" }, { value: "always", label: "Always" }]
        }
    }

    Group {
        title: "Taskbar"
        SettingRow {
            visible: !page.used.includes("taskbar")
            title: "Not in the bar yet"
            subtitle: "Add \"Taskbar (running apps)\" to a section below. Right-click an app there for its window menu."
            icon: "info"
        }
        ChoiceRow {
            title: "Show apps from"
            icon: "select_window"
            target: page.b
            key: "taskbarScope"
            segWidth: 112
            options: [{ value: "all", label: "Every screen" }, { value: "screen", label: "This screen" }, { value: "workspace", label: "Workspace" }]
        }
        SwitchRow { title: "Window titles"; subtitle: "Next to the icons, when there's room"; icon: "title"; target: page.b; key: "taskbarTitles" }
    }

    Repeater {
        model: [{ key: "left", label: Theme.barVertical ? "Top" : "Left" }, { key: "center", label: "Center" }, { key: "right", label: Theme.barVertical ? "Bottom" : "Right" }]

        Group {
            id: grp
            required property var modelData
            title: modelData.label + " section"

            Repeater {
                model: page.b[grp.modelData.key]

                SettingRow {
                    required property string modelData
                    required property int index
                    title: page.allWidgets[modelData] ?? modelData
                    icon: "drag_indicator"

                    Row {
                        spacing: 2
                        FIconButton { icon: "arrow_upward"; size: 30; disabled: index === 0; onClicked: Settings.listMove(page.b, grp.modelData.key, index, index - 1) }
                        FIconButton { icon: "arrow_downward"; size: 30; disabled: index === page.b[grp.modelData.key].length - 1; onClicked: Settings.listMove(page.b, grp.modelData.key, index, index + 1) }
                        FIconButton { icon: "close"; size: 30; iconColor: Theme.error; onClicked: Settings.listRemove(page.b, grp.modelData.key, modelData) }
                    }
                }
            }

            Flow {
                Layout.fillWidth: true
                Layout.margins: 12
                spacing: 6
                Repeater {
                    model: Object.keys(page.allWidgets).filter(k => !page.used.includes(k))
                    FButton {
                        required property string modelData
                        text: page.allWidgets[modelData]
                        icon: "add"
                        variant: "tonal"
                        implicitHeight: 30
                        onClicked: Settings.listAdd(page.b, grp.modelData.key, modelData)
                    }
                }
            }
        }
    }
}
