import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Page {
    id: page
    title: "Bar"
    readonly property var b: Settings.data.bar
    readonly property var allWidgets: ({
            launcher: "Launcher", workspaces: "Workspaces", window: "Active window", clock: "Clock", media: "Media",
            tray: "System tray", sysstats: "CPU / RAM", keyboard: "Keyboard layout", network: "Network", bluetooth: "Bluetooth",
            audio: "Volume", brightness: "Brightness", battery: "Battery", notifications: "Notifications", weather: "Weather", power: "Power"
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
