import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: "Clock & Weather"
    subtitle: "Also controls the dashboard that opens from the bar clock."
    readonly property var w: Settings.data.weather
    readonly property var d: Settings.data.dashboard

    Group {
        title: "Clock"
        SwitchRow { title: "24-hour time"; icon: "schedule"; target: Settings.data.general; key: "use24h" }
        SwitchRow { title: "Show seconds"; icon: "timer"; target: Settings.data.general; key: "showSeconds" }
    }

    Group {
        title: "Dashboard"
        DropdownRow {
            title: "Opens on"
            subtitle: "Tab shown when you click the bar clock"
            icon: "dashboard"
            target: page.d
            key: "defaultTab"
            options: [{ value: "overview", label: "Overview" }, { value: "media", label: "Media" }, { value: "wallpapers", label: "Wallpapers" }, { value: "weather", label: "Weather" }]
        }
        SwitchRow { title: "User card"; subtitle: "Avatar, name and uptime on the Overview tab"; icon: "account_circle"; target: page.d; key: "showUser" }
        SwitchRow { title: "Media card"; subtitle: "Now playing on the Overview tab"; icon: "music_note"; target: page.d; key: "showMedia" }
        SwitchRow { title: "Weather card"; subtitle: "Current weather on the Overview tab"; icon: "partly_cloudy_day"; target: page.w; key: "showInOverview" }
    }

    Group {
        title: "Weather"
        SwitchRow { title: "Enable weather"; subtitle: "Data from open-meteo.com, no account needed"; icon: "partly_cloudy_day"; target: page.w; key: "enabled" }
        TextRow { title: "Location"; subtitle: "City name, press Enter to look it up"; icon: "location_on"; target: page.w; key: "city"; placeholder: "Seville" }
        SettingRow {
            visible: Weather.ready
            title: Weather.place + ": " + Math.round(Weather.temp) + Weather.unit + ", " + Weather.description
            icon: Weather.icon
            FIconButton { icon: "refresh"; onClicked: Weather.refresh() }
        }
        ChoiceRow { title: "Units"; icon: "thermostat"; target: page.w; key: "fahrenheit"; options: [{ value: false, label: "°C, km/h" }, { value: true, label: "°F, mph" }]; segWidth: 110 }
        SliderRow { title: "Forecast days"; icon: "date_range"; target: page.w; key: "forecastDays"; from: 1; to: 7; stepSize: 1; suffix: " days" }
    }

    Group {
        title: "Weather details"
        SwitchRow { title: "Feels like"; icon: "accessibility_new"; target: page.w; key: "showFeelsLike" }
        SwitchRow { title: "Wind"; icon: "air"; target: page.w; key: "showWind" }
        SwitchRow { title: "Humidity"; icon: "humidity_percentage"; target: page.w; key: "showHumidity" }
        SwitchRow { title: "Sunrise & sunset"; icon: "wb_twilight"; target: page.w; key: "showSunTimes" }
        SwitchRow { title: "Next 12 hours"; icon: "schedule"; target: page.w; key: "showHourly" }
    }
}
