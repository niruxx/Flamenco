import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services
import qs.Widgets

// Settings → Region & Language: the system's language and the formats apps use
// (localectl; apps follow after logging in again), adding a language, and how the
// shell writes dates and which day starts its weeks.
Page {
    id: page
    title: "Region & Language"
    subtitle: "The language and formats your apps use, and how Flamenco writes dates. Flamenco's own text is in English for now."
    readonly property var g: Settings.data.general
    property var state: ({ lang: "", formats: "", available: [], installable: [] })
    property string status: ""

    function refresh() {
        if (!reader.running)
            reader.running = true;
    }
    Component.onCompleted: refresh()
    function label(loc) {
        if (!loc)
            return "";
        const l = Qt.locale(loc.replace(/\..*$/, ""));
        const name = l.nativeLanguageName ? l.nativeLanguageName + (l.nativeTerritoryName ? " (" + l.nativeTerritoryName + ")" : "") : loc;
        return name + " · " + loc;
    }
    function run(args, done) {
        status = "Asking for your password…";
        runner.createObject(page, { command: [Paths.bin, "region"].concat(args), done: done }).running = true;
    }

    Process {
        id: reader
        command: [Paths.bin, "region"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    page.state = JSON.parse(text);
                } catch (e) {}
            }
        }
    }
    Component {
        id: runner
        Process {
            id: rp
            property string done
            stderr: StdioCollector { id: rerr }
            onExited: code => {
                page.status = code === 0 ? rp.done : (rerr.text.trim().split("\n").pop() || "It didn't work").replace(/^flamenco: /, "");
                page.refresh();
                rp.destroy();
            }
        }
    }

    Group {
        title: "Language"
        DropdownRow {
            title: "Language"
            subtitle: page.state.lang ? "Now: " + page.label(page.state.lang) + ". Apps change after you log in again" : "Reading the system's language…"
            icon: "language"
            options: page.state.available.map(l => ({ value: l, label: page.label(l) }))
            target: page.state
            key: "lang"
            onEdited: page.run(["set", page.state.lang, page.state.formats || ""], "Language set: log out and in again for apps to follow")
        }
        DropdownRow {
            title: "Formats"
            subtitle: "Dates, numbers, measurements, paper and money, from another region if you like (e.g. English text with German formats)"
            icon: "public"
            options: [{ value: "", label: "Same as the language" }].concat(page.state.available.map(l => ({ value: l, label: page.label(l) })))
            target: page.state
            key: "formats"
            onEdited: page.run(["set", page.state.lang || "en_US.UTF-8", page.state.formats || ""], "Formats set: log out and in again for apps to follow")
        }
        SettingRow {
            title: "Add a language"
            subtitle: page.state.installable.length ? "Languages not set up yet: pick one to generate it (it asks for your password)" : "Every language this system knows is set up"
            icon: "add"
            FDropdown {
                visible: page.state.installable.length > 0
                implicitWidth: 260
                placeholder: "Choose…"
                options: page.state.installable.map(l => ({ value: l, label: page.label(l) }))
                onSelected: v => page.run(["enable", v], page.label(v) + " is set up: choose it above")
            }
        }
        FText {
            Layout.fillWidth: true
            Layout.margins: Theme.sp3
            visible: page.status !== ""
            text: page.status
            dim: true
            font.pixelSize: Theme.fsSm
            wrapMode: Text.Wrap
        }
    }

    Group {
        title: "In Flamenco"
        ChoiceRow {
            title: "Dates"
            subtitle: "In the bar, the lock screen and panels"
            icon: "calendar_month"
            target: page.g
            key: "dateStyle"
            segWidth: 150
            options: [{ value: "dmy", label: "28 October" }, { value: "mdy", label: "October 28" }, { value: "iso", label: "2026-10-28" }]
        }
        ChoiceRow {
            title: "Weeks start on"
            subtitle: "In the calendars"
            icon: "date_range"
            target: page.g
            key: "firstDay"
            segWidth: 110
            options: [{ value: -1, label: "Language's" }, { value: 1, label: "Monday" }, { value: 0, label: "Sunday" }, { value: 6, label: "Saturday" }]
        }
        SwitchRow { title: "24-hour time"; icon: "schedule"; target: page.g; key: "use24h" }
        SwitchRow { title: "Fahrenheit"; subtitle: "For the weather"; icon: "thermostat"; target: Settings.data.weather; key: "fahrenheit" }
    }
}
