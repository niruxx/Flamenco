import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: "Power"
    subtitle: "Power profiles come from power-profiles-daemon. You can also switch them from the control center."

    Group {
        title: "Power profile"
        SettingRow {
            title: Power.profileName
            subtitle: Power.profileId === "power-saver" ? "Longer battery, lower performance" : Power.profileId === "performance" ? "Maximum performance, more power and heat" : "Balance performance and power use"
            icon: Power.profileIcon
            FSegmented {
                implicitWidth: Power.profileOptions.length * 130
                options: Power.profileOptions
                current: Power.profileId
                onSelected: v => Power.setProfile(v)
            }
        }
        SettingRow {
            visible: !Power.hasPerformance
            title: "Performance unavailable"
            subtitle: "This machine's power-profiles-daemon doesn't offer a performance profile."
            icon: "info"
        }
    }

    Group {
        visible: Power.hasBattery
        title: "Battery"
        SettingRow {
            title: Power.percent + "%" + (Power.charging ? ", charging" : "")
            subtitle: Power.timeLeft
            icon: Power.icon
        }
    }

    Group {
        title: "Session"
        SettingRow {
            title: "Lock, idle and screen off"
            subtitle: "Configured under Lock & Idle"
            icon: "lock_clock"
            FButton {
                text: "Open"
                variant: "tonal"
                onClicked: Panels.settingsPage = "lock"
            }
        }
    }
}
