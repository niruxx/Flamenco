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
        id: barClock
        title: "Bar clock"
        readonly property var b: Settings.data.bar
        // which bar section has the clock (the shared layout), and where in it
        readonly property string side: ["left", "center", "right"].find(k => (b[k] || []).includes("clock")) ?? ""
        readonly property string place: {
            const l = b[side] || [];
            const i = l.indexOf("clock");
            return i < 0 ? "" : i === 0 && l.length > 1 ? "start" : "end";
        }
        function moveTo(side, place) {
            for (const k of ["left", "center", "right"])
                b[k] = (b[k] || []).filter(x => x !== "clock");
            const l = (b[side] || []).slice();
            if (place === "start")
                l.unshift("clock");
            else if (side === "right" && l.includes("power"))
                l.splice(l.indexOf("power"), 0, "clock");    // stays before the power button
            else
                l.push("clock");
            b[side] = l;
        }

        ChoiceRow {
            title: "Layout"
            subtitle: "On a vertical bar it's always hours over minutes"
            icon: "schedule"
            target: barClock.b
            key: "clockLayout"
            segWidth: 120
            options: [{ value: "inline", label: "Time • date" }, { value: "stacked", label: "Time over date" }, { value: "time", label: "Time only" }]
        }
        ChoiceRow {
            visible: barClock.b.clockLayout === "stacked"
            title: "Line alignment"
            subtitle: "How the time and the date line up"
            icon: "format_align_center"
            target: barClock.b
            key: "clockAlign"
            options: [{ value: "left", label: "Left", icon: "format_align_left" }, { value: "center", label: "Center", icon: "format_align_center" }, { value: "right", label: "Right", icon: "format_align_right" }]
        }
        SettingRow {
            title: "Position"
            subtitle: barClock.side === "" ? "The clock isn't in the bar: pick a side to add it" : "Where in the bar it sits (the shared layout; Bar settings has the rest)"
            icon: "align_horizontal_center"
            Row {
                spacing: 8
                FSegmented {
                    implicitWidth: 270
                    options: [{ value: "left", label: "Left" }, { value: "center", label: "Center" }, { value: "right", label: "Right" }]
                    current: barClock.side
                    onSelected: v => barClock.moveTo(v, barClock.place || (v === "left" ? "start" : "end"))
                }
                FSegmented {
                    visible: barClock.side !== ""
                    implicitWidth: 180
                    options: [{ value: "start", label: "First" }, { value: "end", label: "Last" }]
                    current: barClock.place
                    onSelected: v => barClock.moveTo(barClock.side, v)
                }
            }
        }
    }

    Group {
        id: cals
        title: "Calendars"
        readonly property var list: Settings.data.calendar.sources || []
        function setAt(i, changes) {
            Settings.data.calendar.sources = list.map((c, j) => j === i ? Object.assign({}, c, changes) : c);
        }

        SettingRow {
            title: cals.list.length ? cals.list.length + (cals.list.length === 1 ? " calendar" : " calendars") + " in the calendar panel" : "Events in the calendar panel"
            subtitle: "An ICS link (Google: Settings → your calendar → Secret address in iCal format; Outlook: Publish calendar → ICS), an .ics file, or a folder of .ics files (vdirsyncer / khal, for CalDAV)."
            icon: "event"
            FIconButton {
                icon: Events.loading ? "progress_activity" : "refresh"
                size: 32
                onClicked: Events.refresh(true)
            }
        }
        Repeater {
            model: cals.list
            SettingRow {
                required property var modelData
                required property int index
                title: modelData.name || "Calendar"
                subtitle: (Events.errors[modelData.name || modelData.url] ? "⚠ " + Events.errors[modelData.name || modelData.url] + " · " : "") + modelData.url
                icon: "calendar_month"
                Row {
                    spacing: 8
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16; height: 16; radius: 8
                        color: modelData.color || Theme.accent
                    }
                    FSwitch {
                        anchors.verticalCenter: parent.verticalCenter
                        checked: modelData.enabled !== false
                        onToggled: c => cals.setAt(index, { enabled: c })
                    }
                    FIconButton {
                        icon: "delete"
                        size: 32
                        iconColor: Theme.error
                        onClicked: Settings.data.calendar.sources = cals.list.filter((_, j) => j !== index)
                    }
                }
            }
        }
        SettingRow {
            title: "Add a calendar"
            icon: "add"
            Row {
                spacing: 8
                FTextField { id: calName; implicitWidth: 130; placeholder: "Name" }
                FTextField { id: calUrl; implicitWidth: 260; placeholder: "https://…/basic.ics  or  ~/.calendars/work" }
                FButton {
                    text: "Add"
                    disabled: calUrl.text.trim() === ""
                    onClicked: {
                        const colors = [Theme.palette.accent, Theme.palette.accent2, Theme.palette.accent3, Theme.palette.success, Theme.palette.warning];
                        const c = colors[cals.list.length % colors.length];
                        Settings.data.calendar.sources = cals.list.concat([{ name: calName.text.trim() || "Calendar " + (cals.list.length + 1), url: calUrl.text.trim(), color: String(c).slice(0, 7), enabled: true }]);
                        calName.text = "";
                        calUrl.text = "";
                    }
                }
            }
        }
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
