import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: "Clock & Weather"

    Group {
        title: "Clock"
        SwitchRow { title: "24-hour time"; icon: "schedule"; target: Settings.data.general; key: "use24h" }
        SwitchRow { title: "Show seconds"; icon: "timer"; target: Settings.data.general; key: "showSeconds" }
    }

    Group {
        title: "Weather"
        SwitchRow { title: "Enable weather"; subtitle: "Data from open-meteo.com"; icon: "partly_cloudy_day"; target: Settings.data.weather; key: "enabled" }
        TextRow { title: "City"; icon: "location_on"; target: Settings.data.weather; key: "city"; placeholder: "Seville" }
        SwitchRow { title: "Fahrenheit"; icon: "thermostat"; target: Settings.data.weather; key: "fahrenheit" }
        SettingRow {
            visible: Weather.ready
            title: Weather.place + ": " + Math.round(Weather.temp) + Weather.unit + ", " + Weather.description
            icon: Weather.icon
        }
    }
}
