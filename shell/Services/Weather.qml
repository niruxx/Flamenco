pragma Singleton

import QtQuick
import Quickshell
import qs.Commons

// Open-Meteo (no API key). Geocodes the configured city, then fetches forecast.
Singleton {
    id: root

    readonly property var cfg: Settings.data.weather
    property bool ready: false
    property string place: ""
    property real temp: 0
    property int code: 0
    property bool isDay: true
    property real wind: 0
    property int humidity: 0
    property var daily: []      // [{ date, code, max, min }]
    property real lat: NaN
    property real lon: NaN

    readonly property string unit: cfg.fahrenheit ? "°F" : "°C"
    readonly property string icon: iconFor(code, isDay)
    readonly property string description: describe(code)

    onCfgChanged: refresh()
    Connections {
        target: root.cfg
        function onCityChanged() { root.lat = NaN; root.refresh(); }
        function onFahrenheitChanged() { root.refresh(); }
        function onEnabledChanged() { root.refresh(); }
    }
    Component.onCompleted: refresh()

    function get(url, cb) {
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (xhr.status === 200) {
                try {
                    cb(JSON.parse(xhr.responseText));
                } catch (e) {}
            }
        };
        xhr.open("GET", url);
        xhr.send();
    }

    function refresh() {
        if (!cfg.enabled || !cfg.city)
            return;
        if (isNaN(lat)) {
            get("https://geocoding-api.open-meteo.com/v1/search?count=1&name=" + encodeURIComponent(cfg.city), d => {
                const r = d.results?.[0];
                if (!r)
                    return;
                root.lat = r.latitude;
                root.lon = r.longitude;
                root.place = r.name;
                root.fetch();
            });
        } else {
            fetch();
        }
    }

    function fetch() {
        const url = "https://api.open-meteo.com/v1/forecast?latitude=" + lat + "&longitude=" + lon + "&current=temperature_2m,weather_code,is_day,wind_speed_10m,relative_humidity_2m" + "&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=auto&forecast_days=5" + (cfg.fahrenheit ? "&temperature_unit=fahrenheit&wind_speed_unit=mph" : "");
        get(url, d => {
            root.temp = d.current.temperature_2m;
            root.code = d.current.weather_code;
            root.isDay = d.current.is_day === 1;
            root.wind = d.current.wind_speed_10m;
            root.humidity = d.current.relative_humidity_2m;
            root.daily = d.daily.time.map((t, i) => ({
                        date: t,
                        code: d.daily.weather_code[i],
                        max: d.daily.temperature_2m_max[i],
                        min: d.daily.temperature_2m_min[i]
                    }));
            root.ready = true;
        });
    }

    Timer {
        interval: 30 * 60000
        running: root.cfg.enabled
        repeat: true
        onTriggered: root.refresh()
    }

    function iconFor(c, day) {
        if (c === 0)
            return day ? "sunny" : "clear_night";
        if (c <= 2)
            return day ? "partly_cloudy_day" : "partly_cloudy_night";
        if (c === 3)
            return "cloud";
        if (c <= 48)
            return "foggy";
        if (c <= 67 || (c >= 80 && c <= 82))
            return "rainy";
        if (c <= 77 || c === 85 || c === 86)
            return "weather_snowy";
        return "thunderstorm";
    }

    function describe(c) {
        const m = { 0: "Clear", 1: "Mostly clear", 2: "Partly cloudy", 3: "Overcast", 45: "Fog", 48: "Rime fog", 51: "Light drizzle", 53: "Drizzle", 55: "Heavy drizzle", 61: "Light rain", 63: "Rain", 65: "Heavy rain", 71: "Light snow", 73: "Snow", 75: "Heavy snow", 80: "Showers", 81: "Showers", 82: "Violent showers", 95: "Thunderstorm", 96: "Thunderstorm", 99: "Thunderstorm" };
        return m[c] ?? "—";
    }
}
