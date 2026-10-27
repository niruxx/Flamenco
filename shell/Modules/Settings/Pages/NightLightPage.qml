import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

// Settings → Night light: warmer (and optionally dimmer) colors in the evening,
// by hand or on a schedule that fades in and out (gammastep).
Page {
    id: page
    title: I18n.tr("Night light")
    subtitle: I18n.tr("Warmer colors that are easier on the eyes at night. The quick settings tile turns it on or off; its arrow has these controls too.")
    readonly property var n: Settings.data.night

    Group {
        title: I18n.tr("Night light")
        SettingRow {
            title: Toggles.nightLight ? I18n.tr("On") : I18n.tr("Off")
            subtitle: Toggles.status
            icon: "nightlight"
            FSwitch {
                checked: Toggles.nightLight
                onToggled: c => Toggles.setNightLight(c)
            }
        }
        SliderRow { title: I18n.tr("Warmth"); subtitle: I18n.tr("Lower is warmer and more orange (6500 K is neutral)"); icon: "thermostat"; target: page.n; key: "temperature"; from: 2000; to: 6000; stepSize: 100; suffix: " K" }
        SliderRow { title: I18n.tr("Dim the screen"); subtitle: I18n.tr("A little darker at night, on top of your brightness"); icon: "brightness_low"; target: page.n; key: "brightness"; from: 0.5; to: 1; stepSize: 0.05; factor: 100; suffix: "%" }
    }

    Group {
        title: I18n.tr("Schedule")
        ChoiceRow {
            title: I18n.tr("Turn on by itself")
            subtitle: page.n.schedule === "sun" ? (Toggles.sunKnown ? I18n.tr("Sunset to sunrise where you are (from the weather's location)") : I18n.tr("Sunset and sunrise need weather on, which knows your location"))
                : page.n.schedule === "custom" ? "Between the times below" : "Only when you turn it on"
            icon: "schedule"
            target: page.n
            key: "schedule"
            segWidth: 140
            options: [{ value: "off", label: I18n.tr("Manually") }, { value: "sun", label: I18n.tr("Sunset to sunrise") }, { value: "custom", label: I18n.tr("Set times") }]
        }
        TextRow { visible: page.n.schedule === "custom"; title: I18n.tr("From"); subtitle: I18n.tr("24-hour time"); icon: "bedtime"; target: page.n; key: "from"; placeholder: "21:00" }
        TextRow { visible: page.n.schedule === "custom"; title: I18n.tr("To"); subtitle: I18n.tr("24-hour time"); icon: "wb_sunny"; target: page.n; key: "to"; placeholder: "07:00" }
        SliderRow { visible: page.n.schedule !== "off"; title: I18n.tr("Fade"); subtitle: I18n.tr("How long it takes to warm up after the start, and to cool down before the end"); icon: "gradient"; target: page.n; key: "fade"; from: 0; to: 120; stepSize: 5; suffix: " min" }
        SettingRow {
            visible: page.n.schedule !== "off"
            title: I18n.tr("Turning it on or off by hand")
            subtitle: I18n.tr("Holds until the next scheduled change, then the schedule takes over again")
            icon: "info"
        }
    }
}
