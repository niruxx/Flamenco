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
        ChoiceRow { title: "Position"; icon: "vertical_align_top"; target: page.b; key: "position"; options: [{ value: "top", label: "Top" }, { value: "bottom", label: "Bottom" }] }
        ChoiceRow { title: "Style"; icon: "style"; target: page.b; key: "style"; options: [{ value: "floating", label: "Floating" }, { value: "attached", label: "Attached" }, { value: "islands", label: "Islands" }] }
        SliderRow { title: "Height"; icon: "height"; target: page.b; key: "height"; from: 30; to: 56; stepSize: 1; suffix: "px" }
        ChoiceRow { title: "Workspace indicator"; icon: "view_week"; target: page.b; key: "workspaceStyle"; options: [{ value: "pills", label: "Pills" }, { value: "numbers", label: "Numbers" }, { value: "dots", label: "Dots" }] }
    }

    Repeater {
        model: [{ key: "left", label: "Left" }, { key: "center", label: "Center" }, { key: "right", label: "Right" }]

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
