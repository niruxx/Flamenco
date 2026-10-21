import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

// Settings → Night light: warmer (and optionally dimmer) colors in the evening,
// by hand or on a schedule that fades in and out (gammastep).
Page {
    id: page
    title: "Night light"
    subtitle: "Warmer colors that are easier on the eyes at night. The quick settings tile turns it on or off; its arrow has these controls too."
    readonly property var n: Settings.data.night

    Group {
        title: "Night light"
        SettingRow {
            title: Toggles.nightLight ? "On" : "Off"
            subtitle: Toggles.status
            icon: "nightlight"
            FSwitch {
                checked: Toggles.nightLight
                onToggled: c => Toggles.setNightLight(c)
            }
        }
        SliderRow { title: "Warmth"; subtitle: "Lower is warmer and more orange (6500 K is neutral)"; icon: "thermostat"; target: page.n; key: "temperature"; from: 2000; to: 6000; stepSize: 100; suffix: " K" }
        SliderRow { title: "Dim the screen"; subtitle: "A little darker at night, on top of your brightness"; icon: "brightness_low"; target: page.n; key: "brightness"; from: 0.5; to: 1; stepSize: 0.05; factor: 100; suffix: "%" }
    }

    Group {
        title: "Schedule"
        ChoiceRow {
            title: "Turn on by itself"
            subtitle: page.n.schedule === "sun" ? (Toggles.sunKnown ? "Sunset to sunrise where you are (from the weather's location)" : "Sunset and sunrise need weather on, which knows your location")
                : page.n.schedule === "custom" ? "Between the times below" : "Only when you turn it on"
            icon: "schedule"
            target: page.n
            key: "schedule"
            segWidth: 140
            options: [{ value: "off", label: "Manually" }, { value: "sun", label: "Sunset to sunrise" }, { value: "custom", label: "Set times" }]
        }
        TextRow { visible: page.n.schedule === "custom"; title: "From"; subtitle: "24-hour time"; icon: "bedtime"; target: page.n; key: "from"; placeholder: "21:00" }
        TextRow { visible: page.n.schedule === "custom"; title: "To"; subtitle: "24-hour time"; icon: "wb_sunny"; target: page.n; key: "to"; placeholder: "07:00" }
        SliderRow { visible: page.n.schedule !== "off"; title: "Fade"; subtitle: "How long it takes to warm up after the start, and to cool down before the end"; icon: "gradient"; target: page.n; key: "fade"; from: 0; to: 120; stepSize: 5; suffix: " min" }
        SettingRow {
            visible: page.n.schedule !== "off"
            title: "Turning it on or off by hand"
            subtitle: "Holds until the next scheduled change, then the schedule takes over again"
            icon: "info"
        }
    }
}
