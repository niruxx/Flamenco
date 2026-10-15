pragma Singleton

import QtQuick
import Quickshell
import qs.Services as FS

// Flamenco shim for Noctalia's LocationService: Flamenco's weather in the shape
// Noctalia keeps (open-meteo's current_weather and daily blocks).
Singleton {
    id: root

    readonly property bool locationConfigured: FS.Weather.ready
    readonly property bool coordinatesReady: !isNaN(FS.Weather.lat)
    readonly property string stableName: FS.Weather.place
    readonly property var data: ({
            latitude: String(FS.Weather.lat),
            longitude: String(FS.Weather.lon),
            name: FS.Weather.place,
            weatherLastFetch: Math.floor(new Date(FS.Weather.updated).getTime() / 1000) || 0,
            weather: FS.Weather.ready ? {
                current_weather: { temperature: FS.Weather.temp, weathercode: FS.Weather.code, is_day: FS.Weather.isDay ? 1 : 0, windspeed: FS.Weather.wind },
                daily: {
                    time: FS.Weather.daily.map(d => d.date),
                    weathercode: FS.Weather.daily.map(d => d.code),
                    temperature_2m_max: FS.Weather.daily.map(d => d.max),
                    temperature_2m_min: FS.Weather.daily.map(d => d.min),
                    sunrise: [FS.Weather.sunrise],
                    sunset: [FS.Weather.sunset]
                },
                timezone_abbreviation: ""
            } : null
        })

    function updateWeather() {
        FS.Weather.refresh();
    }
    function weatherSymbolFromCode(code) {
        const isDay = data.weather ? data.weather.current_weather.is_day : true;
        if (code === 0) return isDay ? "weather-sun" : "weather-moon";
        if (code === 1 || code === 2) return isDay ? "weather-cloud-sun" : "weather-moon-stars";
        if (code === 3) return "weather-cloud";
        if (code >= 45 && code <= 48) return "weather-cloud-haze";
        if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) return "weather-cloud-rain";
        if ((code >= 71 && code <= 77) || (code >= 85 && code <= 86)) return "weather-cloud-snow";
        if (code >= 95 && code <= 99) return "weather-cloud-lightning";
        return "weather-cloud";
    }
    function weatherDescriptionFromCode(code) {
        return FS.Weather.describe(code);
    }
    function celsiusToFahrenheit(c) {
        return c * 9 / 5 + 32;
    }
}
