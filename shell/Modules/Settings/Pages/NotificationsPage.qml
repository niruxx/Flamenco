import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: "Notifications"
    readonly property var n: Settings.data.notifications

    Group {
        SwitchRow { title: "Show popups"; icon: "notifications_active"; target: page.n; key: "popups" }
        SwitchRow { title: "Do not disturb"; subtitle: "Only critical notifications pop up"; icon: "do_not_disturb_on"; target: page.n; key: "dnd" }
        ChoiceRow {
            title: "Position"
            icon: "picture_in_picture"
            target: page.n
            key: "position"
            segWidth: 76
            options: [{ value: "top-left", label: "↖" }, { value: "top-center", label: "↑" }, { value: "top-right", label: "↗" }, { value: "bottom-left", label: "↙" }, { value: "bottom-right", label: "↘" }]
        }
        SliderRow { title: "Popup timeout"; icon: "timer"; target: page.n; key: "timeout"; from: 2; to: 20; stepSize: 1; suffix: "s" }
    }

    Group {
        title: "On-screen display"
        SwitchRow { title: "Volume & brightness OSD"; icon: "tune"; target: Settings.data.osd; key: "enabled" }
        ChoiceRow { title: "Position"; icon: "vertical_align_bottom"; target: Settings.data.osd; key: "position"; options: [{ value: "top", label: "Top" }, { value: "bottom", label: "Bottom" }] }
    }

    Group {
        title: "History"
        SettingRow {
            title: Notifs.history.count + " notifications stored"
            icon: "history"
            FButton { text: "Clear"; variant: "tonal"; icon: "delete_sweep"; onClicked: Notifs.clearAll() }
        }
    }
}
