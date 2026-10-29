import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: I18n.tr("Clock & Weather")
    subtitle: I18n.tr("Also controls the dashboard that opens from the bar clock.")
    readonly property var w: Settings.data.weather
    readonly property var d: Settings.data.dashboard

    Group {
        title: I18n.tr("Clock")
        SwitchRow { title: I18n.tr("24-hour time"); icon: "schedule"; target: Settings.data.general; key: "use24h" }
        SwitchRow { title: I18n.tr("Show seconds"); icon: "timer"; target: Settings.data.general; key: "showSeconds" }
    }

    Group {
        id: barClock
        title: I18n.tr("Bar clock")
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
            title: I18n.tr("Layout")
            subtitle: I18n.tr("On a vertical bar it's always hours over minutes")
            icon: "schedule"
            target: barClock.b
            key: "clockLayout"
            segWidth: 120
            options: [{ value: "inline", label: I18n.tr("Time • date") }, { value: "stacked", label: I18n.tr("Time over date") }, { value: "time", label: I18n.tr("Time only") }]
        }
        ChoiceRow {
            visible: barClock.b.clockLayout === "stacked"
            title: I18n.tr("Line alignment")
            subtitle: I18n.tr("How the time and the date line up")
            icon: "format_align_center"
            target: barClock.b
            key: "clockAlign"
            options: [{ value: "left", label: I18n.tr("Left"), icon: "format_align_left" }, { value: "center", label: I18n.tr("Center"), icon: "format_align_center" }, { value: "right", label: I18n.tr("Right"), icon: "format_align_right" }]
        }
        SettingRow {
            title: I18n.tr("Position")
            subtitle: barClock.side === "" ? I18n.tr("The clock isn't in the bar: pick a side to add it") : I18n.tr("Where in the bar it sits (the shared layout; Bar settings has the rest)")
            icon: "align_horizontal_center"
            Row {
                spacing: 8
                FSegmented {
                    implicitWidth: 270
                    options: [{ value: "left", label: I18n.tr("Left") }, { value: "center", label: I18n.tr("Center") }, { value: "right", label: I18n.tr("Right") }]
                    current: barClock.side
                    onSelected: v => barClock.moveTo(v, barClock.place || (v === "left" ? "start" : "end"))
                }
                FSegmented {
                    visible: barClock.side !== ""
                    implicitWidth: 180
                    options: [{ value: "start", label: I18n.tr("First") }, { value: "end", label: I18n.tr("Last") }]
                    current: barClock.place
                    onSelected: v => barClock.moveTo(barClock.side, v)
                }
            }
        }
    }

    Group {
        title: I18n.tr("Panel position")
        DropdownRow {
            title: I18n.tr("Placement")
            icon: "align_horizontal_center"
            target: page.d
            key: "placement"
            options: [{ value: "bar", label: I18n.tr("By the bar button") }, { value: "center", label: I18n.tr("Screen center") }, { value: "top", label: I18n.tr("Top center") }, { value: "bottom", label: I18n.tr("Bottom center") }, { value: "top-left", label: I18n.tr("Top left") }, { value: "top-right", label: I18n.tr("Top right") }, { value: "bottom-left", label: I18n.tr("Bottom left") }, { value: "bottom-right", label: I18n.tr("Bottom right") }]
        }
        SliderRow { title: I18n.tr("Button spacing"); subtitle: I18n.tr("More space between controls and larger button targets"); icon: "space_bar"; target: page.d; key: "panelSpacing"; from: 1; to: 1.6; stepSize: 0.05; factor: 100; suffix: "%" }
        SliderRow { visible: page.d.style === "tabs"; title: I18n.tr("Compact panel width"); icon: "width"; target: page.d; key: "width"; from: 480; to: 960; stepSize: 20; suffix: " px" }

    }

    Group {
        id: cals
        title: I18n.tr("Calendars")
        readonly property var list: Settings.data.calendar.sources || []
        SettingRow {
            title: I18n.tr("Online accounts")
            subtitle: I18n.tr("Sign in to iCloud, Nextcloud, Fastmail or any CalDAV server, or add Google and Outlook calendars")
            icon: "cloud_sync"
            FButton {
                text: I18n.tr("Online Accounts")
                variant: "tonal"
                onClicked: Panels.settingsPage = "accounts"
            }
        }
        function setAt(i, changes) {
            Settings.data.calendar.sources = list.map((c, j) => j === i ? Object.assign({}, c, changes) : c);
        }

        SettingRow {
            title: cals.list.length ? cals.list.length + (cals.list.length === 1 ? " calendar" : " calendars") + " in the calendar panel" : I18n.tr("Events in the calendar panel")
            subtitle: I18n.tr("An ICS link (Google: Settings → your calendar → Secret address in iCal format; Outlook: Publish calendar → ICS), an .ics file, or a folder of .ics files (vdirsyncer / khal, for CalDAV).")
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
            title: I18n.tr("Add a calendar")
            icon: "add"
            Row {
                spacing: 8
                FTextField { id: calName; implicitWidth: 130; placeholder: I18n.tr("Name") }
                FTextField { id: calUrl; implicitWidth: 260; placeholder: I18n.tr("https://…/basic.ics  or  ~/.calendars/work") }
                FButton {
                    text: I18n.tr("Add")
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
        title: I18n.tr("Dashboard")
        ChoiceRow {
            title: I18n.tr("Dashboard layout")
            subtitle: page.d.style === "tabs" ? I18n.tr("Compact, with tabs along the top") : I18n.tr("Wide, with a rail on the left: Home (toggles, sliders, media, weather, system), Media, Calendar, Weather, Wallpaper")
            icon: "space_dashboard"
            target: page.d
            key: "style"
            segWidth: 110
            options: [{ value: "hub", label: I18n.tr("Hub"), icon: "view_quilt" }, { value: "tabs", label: I18n.tr("Tabs"), icon: "tab" }]
        }
        DropdownRow {
            visible: page.d.style === "tabs"
            title: I18n.tr("Opens on")
            subtitle: I18n.tr("Tab shown when you click the bar clock")
            icon: "dashboard"
            target: page.d
            key: "defaultTab"
            options: [{ value: "overview", label: I18n.tr("Overview") }, { value: "media", label: I18n.tr("Media") }, { value: "wallpapers", label: I18n.tr("Wallpapers") }, { value: "weather", label: I18n.tr("Weather") }, { value: "system", label: I18n.tr("System") }]
        }
        SwitchRow { visible: page.d.style === "tabs"; title: I18n.tr("User card"); subtitle: I18n.tr("Avatar, name and uptime on the Overview tab"); icon: "account_circle"; target: page.d; key: "showUser" }
        SwitchRow { visible: page.d.style === "tabs"; title: I18n.tr("Media card"); subtitle: I18n.tr("Now playing on the Overview tab"); icon: "music_note"; target: page.d; key: "showMedia" }
        SwitchRow { visible: page.d.style === "tabs"; title: I18n.tr("Weather card"); subtitle: I18n.tr("Current weather on the Overview tab"); icon: "partly_cloudy_day"; target: page.w; key: "showInOverview" }
    }

    Group {
        title: I18n.tr("Weather")
        SwitchRow { title: I18n.tr("Enable weather"); subtitle: I18n.tr("Data from open-meteo.com, no account needed"); icon: "partly_cloudy_day"; target: page.w; key: "enabled" }
        TextRow { title: I18n.tr("Location"); subtitle: I18n.tr("City name, press Enter to look it up"); icon: "location_on"; target: page.w; key: "city"; placeholder: I18n.tr("Seville") }
        SettingRow {
            visible: Weather.ready
            title: Weather.place + ": " + Math.round(Weather.temp) + Weather.unit + ", " + Weather.description
            icon: Weather.icon
            FIconButton { icon: "refresh"; onClicked: Weather.refresh() }
        }
        ChoiceRow { title: I18n.tr("Units"); icon: "thermostat"; target: page.w; key: "fahrenheit"; options: [{ value: false, label: I18n.tr("°C, km/h") }, { value: true, label: I18n.tr("°F, mph") }]; segWidth: 110 }
        SliderRow { title: I18n.tr("Forecast days"); icon: "date_range"; target: page.w; key: "forecastDays"; from: 1; to: 7; stepSize: 1; suffix: " days" }
    }

    Group {
        title: I18n.tr("Weather details")
        SwitchRow { title: I18n.tr("Feels like"); icon: "accessibility_new"; target: page.w; key: "showFeelsLike" }
        SwitchRow { title: I18n.tr("Wind"); icon: "air"; target: page.w; key: "showWind" }
        SwitchRow { title: I18n.tr("Humidity"); icon: "humidity_percentage"; target: page.w; key: "showHumidity" }
        SwitchRow { title: I18n.tr("Sunrise & sunset"); icon: "wb_twilight"; target: page.w; key: "showSunTimes" }
        SwitchRow { title: I18n.tr("Next 12 hours"); icon: "schedule"; target: page.w; key: "showHourly" }
    }
}
