pragma Singleton

import QtQuick
import Quickshell
import qs.Services as FS

// Flamenco shim for DMS's WeatherService, from Flamenco's weather.
Singleton {
    readonly property var weather: ({
            available: FS.Weather.ready,
            loading: !FS.Weather.ready,
            temp: FS.Weather.temp,
            tempF: FS.Weather.temp * 9 / 5 + 32,
            feelsLike: FS.Weather.feelsLike,
            city: FS.Weather.place,
            wCode: FS.Weather.code,
            humidity: FS.Weather.humidity,
            wind: String(FS.Weather.wind),
            isDay: FS.Weather.isDay,
            sunrise: FS.Weather.sunrise,
            sunset: FS.Weather.sunset,
            forecast: FS.Weather.daily.map(d => ({ day: d.date, wCode: d.code, tempMax: d.max, tempMin: d.min, precipitationProbability: d.rain }))
        })
    readonly property string currentTempText: Math.round(FS.Weather.temp) + FS.Weather.unit

    function addRef() {}
    function removeRef() {}
    function forceRefresh() {
        FS.Weather.refresh();
    }
    function getWeatherIcon(code, isDay) {
        return FS.Weather.iconFor(code, isDay ?? true);
    }
    function getWeatherCondition(code) {
        return FS.Weather.describe(code);
    }
    function formatTemp(t, withUnit = true) {
        return Math.round(t) + (withUnit ? FS.Weather.unit : "°");
    }
    function formatSpeed(s) {
        return Math.round(s) + " km/h";
    }
    function formatPercent(p) {
        return Math.round(p) + "%";
    }
}
