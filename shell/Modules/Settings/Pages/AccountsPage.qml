import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services
import qs.Widgets

// Settings → Online Accounts: calendars from the web in the calendar panel and
// widgets. CalDAV services (iCloud, Nextcloud, Fastmail, any other) sign in with
// a user name and an app password and list their calendars to pick from;
// Google and Outlook share a private ICS address instead (Flamenco has no
// Google / Microsoft sign-in of its own), as does any other calendar link.
Page {
    id: page
    title: "Online Accounts"
    subtitle: "Calendars from iCloud, Nextcloud, Google, Outlook and others, shown in the calendar and the desktop calendar widget."
    readonly property var cal: Settings.data.calendar
    readonly property var accounts: cal.accounts || []

    readonly property var providers: [
        { kind: "icloud", label: "iCloud", icon: "cloud", tint: "#4a90e2", server: "https://caldav.icloud.com/", userHint: "Apple ID email",
          help: "Use an app-specific password: appleid.apple.com → Sign-In and Security → App-Specific Passwords", helpUrl: "https://appleid.apple.com/account/manage" },
        { kind: "nextcloud", label: "Nextcloud", icon: "cloud_circle", tint: "#0082c9", server: "", serverHint: "https://cloud.example.com", userHint: "User name",
          help: "Create an app password in Nextcloud: Settings → Security → Devices & sessions" },
        { kind: "fastmail", label: "Fastmail", icon: "mail", tint: "#2c6ce0", server: "https://caldav.fastmail.com/dav/", userHint: "Fastmail email",
          help: "Create an app password with CalDAV access: Settings → Privacy & Security → App passwords", helpUrl: "https://app.fastmail.com/settings/security/apps" },
        { kind: "caldav", label: "Other CalDAV", icon: "dns", tint: "#6b7380", server: "", serverHint: "https://dav.example.com (or just the host)", userHint: "User name",
          help: "Radicale, Baïkal, mailbox.org, Zoho, Yahoo, Synology… the server's address and your sign-in" },
        { kind: "google", label: "Google", icon: "event", tint: "#34a853", ics: true,
          help: "Google Calendar on the web → Settings → pick a calendar → Integrate calendar → copy \"Secret address in iCal format\" and paste it below. One link per calendar.",
          helpUrl: "https://calendar.google.com/calendar/r/settings" },
        { kind: "outlook", label: "Outlook", icon: "calendar_month", tint: "#0f6cbd", ics: true,
          help: "Outlook on the web → Settings → Calendar → Shared calendars → Publish a calendar (Can view all details) → copy the ICS link and paste it below.",
          helpUrl: "https://outlook.live.com/calendar/0/options/calendar/SharedCalendars" },
        { kind: "ics", label: "Calendar link", icon: "link", tint: "#8e6cf0", ics: true,
          help: "Any ICS or webcal:// address: a team calendar, holidays, sports fixtures…" }
    ]
    property var adding: null                 // the provider being set up
    property string step: "form"              // form | signing | pick
    property string error: ""
    property var found: []                    // calendars found when signing in: [{url, name, color, on}]

    function providerOf(kind) {
        return providers.find(p => p.kind === kind) ?? providers[3];
    }
    function start(p) {
        adding = p;
        step = "form";
        error = "";
        found = [];
        server.text = p.server ?? "";
        user.text = "";
        pass.text = "";
        icsUrl.text = "";
        icsName.text = p.kind === "google" ? "Google" : p.kind === "outlook" ? "Outlook" : "";
    }
    function cancel() {
        adding = null;
        error = "";
    }
    readonly property var palette: [Theme.accent, Theme.accent2, Theme.accent3, "#5b9cff", "#7bd88f", "#f5c542", "#ff8a4c", "#f272c8"]
    function nextColor(i) {
        return String(palette[i % palette.length]).slice(0, 7);
    }

    // CalDAV: sign in and list the calendars (the password goes on stdin)
    function signIn() {
        error = "";
        step = "signing";
        discover.command = [Paths.bin, "accounts", "discover", server.text.trim(), user.text.trim()];
        discover.running = true;
    }
    Process {
        id: discover
        stdinEnabled: true
        onStarted: write(pass.text + "\n")
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    if (d.error) {
                        page.error = d.error;
                        page.step = "form";
                        return;
                    }
                    page.found = (d.calendars ?? []).map((c, i) => ({ url: c.url, name: c.name, color: c.color || page.nextColor((page.cal.sources || []).length + i), on: true }));
                    page.step = "pick";
                } catch (e) {
                    page.error = "Couldn't sign in (is `flamenco` up to date?)";
                    page.step = "form";
                }
            }
        }
    }
    // keep the account (its password into the keyring) and the calendars picked
    function addAccount() {
        const id = "acc" + Date.now().toString(36);
        const p = adding;
        const name = p.label + (user.text.trim() ? " · " + user.text.trim() : "");
        saver.createObject(page, { aid: id, secret: pass.text }).running = true;
        cal.accounts = accounts.concat([{ id, kind: p.kind, name, server: server.text.trim(), user: user.text.trim() }]);
        cal.sources = (cal.sources || []).concat(found.filter(c => c.on).map(c => ({ name: c.name, url: c.url, color: c.color, enabled: true, type: "caldav", account: id })));
        adding = null;
        pass.text = "";
    }
    Component {
        id: saver
        Process {
            id: sp
            property string aid
            property string secret
            command: [Paths.bin, "accounts", "secret", aid]
            stdinEnabled: true
            onStarted: write(secret + "\n")
            onExited: sp.destroy()
        }
    }
    function addLink() {
        const url = icsUrl.text.trim();
        if (!url)
            return;
        cal.sources = (cal.sources || []).concat([{ name: icsName.text.trim() || adding.label, url, color: nextColor((cal.sources || []).length), enabled: true }]);
        adding = null;
    }
    function removeAccount(a) {
        cal.sources = (cal.sources || []).filter(s => s.account !== a.id);
        cal.accounts = accounts.filter(x => x.id !== a.id);
        Quickshell.execDetached([Paths.bin, "accounts", "secret", a.id, "--clear"]);
    }

    // ── accounts you've added ──
    Group {
        title: "Accounts"
        SettingRow {
            visible: page.accounts.length === 0
            title: "No accounts yet"
            subtitle: "Add one below; its calendars join the ones in Clock & Weather → Calendars"
            icon: "person_add"
        }
        Repeater {
            model: page.accounts
            SettingRow {
                id: arow
                required property var modelData
                readonly property var prov: page.providerOf(modelData.kind)
                readonly property var mine: (page.cal.sources || []).filter(s => s.account === modelData.id)
                property bool asking: false
                title: modelData.name
                subtitle: modelData.server + " · " + mine.length + (mine.length === 1 ? " calendar" : " calendars") + (Events.errors?.[mine[0]?.name] ? " · " + Events.errors[mine[0].name] : "")
                icon: prov.icon
                Row {
                    spacing: 6
                    FButton {
                        visible: !arow.asking
                        text: "Remove"
                        variant: "text"
                        onClicked: arow.asking = true
                    }
                    FButton {
                        visible: arow.asking
                        text: "Remove account and its calendars"
                        onClicked: page.removeAccount(arow.modelData)
                    }
                    FIconButton {
                        visible: arow.asking
                        anchors.verticalCenter: parent.verticalCenter
                        icon: "close"
                        size: 32
                        iconSize: 17
                        onClicked: arow.asking = false
                    }
                }
            }
        }
        SettingRow {
            visible: (page.cal.sources || []).some(s => !s.account)
            title: "Calendar links"
            subtitle: (page.cal.sources || []).filter(s => !s.account).map(s => s.name).join(", ")
            icon: "link"
            FButton {
                text: "Manage"
                variant: "text"
                onClicked: Panels.findSetting("clock", "Calendars")
            }
        }
    }

    // ── add one: the services as tiles ──
    Group {
        title: "Add an account"
        visible: page.adding === null
        Item {
            Layout.fillWidth: true
            Layout.margins: Theme.sp3
            implicitHeight: tiles.implicitHeight
            Flow {
                id: tiles
                width: parent.width
                spacing: Theme.sp2
                readonly property int cols: Math.max(2, Math.floor((width + spacing) / (150 + spacing)))
                readonly property real tileW: (width - spacing * (cols - 1)) / cols
                Repeater {
                    model: page.providers
                    Rectangle {
                        id: ptile
                        required property var modelData
                        width: tiles.tileW
                        height: 64
                        radius: Theme.rLg
                        color: Theme.alpha(Theme.text, 0.04)
                        border.width: 1
                        border.color: Theme.alpha(Theme.text, 0.08)
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 10
                            spacing: 10
                            Rectangle {
                                Layout.preferredWidth: 34
                                Layout.preferredHeight: 34
                                radius: 10
                                color: ptile.modelData.tint
                                FIcon { anchors.centerIn: parent; icon: ptile.modelData.icon; size: 20; fill: 1; color: "#ffffff" }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                FText { Layout.fillWidth: true; text: ptile.modelData.label; font.weight: Font.DemiBold; elide: Text.ElideRight }
                                FText { Layout.fillWidth: true; text: ptile.modelData.ics ? "Calendar link" : "Sign in (CalDAV)"; dim: true; font.pixelSize: Theme.fsXs; elide: Text.ElideRight }
                            }
                        }
                        StateLayer {
                            radius: parent.radius
                            onClicked: page.start(ptile.modelData)
                        }
                    }
                }
            }
        }
    }

    // ── setting one up ──
    Group {
        visible: page.adding !== null
        title: page.adding ? "Add " + page.adding.label : ""

        SettingRow {
            title: page.adding?.ics ? "How to get the link" : "Before you sign in"
            subtitle: page.adding?.help ?? ""
            icon: "help"
            FButton {
                visible: !!page.adding?.helpUrl
                text: "Open"
                icon: "open_in_new"
                variant: "text"
                onClicked: Qt.openUrlExternally(page.adding.helpUrl)
            }
        }

        // a link (Google, Outlook, any ICS)
        SettingRow {
            visible: !!page.adding?.ics
            title: "Calendar address"
            icon: "link"
            FTextField { id: icsUrl; implicitWidth: 300; placeholder: "https://… or webcal://…" }
        }
        SettingRow {
            visible: !!page.adding?.ics
            title: "Name"
            icon: "label"
            FTextField { id: icsName; implicitWidth: 300; placeholder: "Calendar" }
        }

        // CalDAV
        SettingRow {
            visible: !page.adding?.ics && page.step !== "pick"
            title: "Server"
            icon: "dns"
            FTextField { id: server; implicitWidth: 300; placeholder: page.adding?.serverHint ?? "https://" }
        }
        SettingRow {
            visible: !page.adding?.ics && page.step !== "pick"
            title: page.adding?.userHint ?? "User name"
            icon: "person"
            FTextField { id: user; implicitWidth: 300 }
        }
        SettingRow {
            visible: !page.adding?.ics && page.step !== "pick"
            title: "App password"
            subtitle: "Kept in your keyring (or a file only you can read), never in the settings file"
            icon: "key"
            FTextField { id: pass; implicitWidth: 300; password: true; onAccepted: page.signIn() }
        }

        // the calendars found: tick the ones to show
        Repeater {
            model: page.step === "pick" ? page.found : []
            SettingRow {
                id: crow
                required property var modelData
                required property int index
                title: modelData.name
                subtitle: modelData.url
                icon: ""
                Row {
                    spacing: 10
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16
                        height: 16
                        radius: 8
                        color: crow.modelData.color
                    }
                    FSwitch {
                        checked: crow.modelData.on
                        onToggled: c => page.found = page.found.map((x, i) => i === crow.index ? Object.assign({}, x, { on: c }) : x)
                    }
                }
            }
        }

        FText {
            visible: page.error !== ""
            Layout.fillWidth: true
            Layout.margins: Theme.sp3
            text: page.error
            color: Theme.error
            wrapMode: Text.Wrap
        }

        SettingRow {
            title: page.step === "signing" ? "Signing in…" : page.step === "pick" ? page.found.filter(c => c.on).length + " of " + page.found.length + " calendars" : ""
            icon: ""
            Row {
                spacing: 8
                FButton {
                    text: "Cancel"
                    variant: "text"
                    onClicked: page.cancel()
                }
                FButton {
                    visible: !!page.adding?.ics
                    text: "Add calendar"
                    disabled: icsUrl.text.trim() === ""
                    onClicked: page.addLink()
                }
                FButton {
                    visible: !page.adding?.ics && page.step !== "pick"
                    text: page.step === "signing" ? "Signing in…" : "Sign in"
                    disabled: page.step === "signing" || server.text.trim() === "" || user.text.trim() === "" || pass.text === ""
                    onClicked: page.signIn()
                }
                FButton {
                    visible: page.step === "pick"
                    text: "Add account"
                    disabled: !page.found.some(c => c.on)
                    onClicked: page.addAccount()
                }
            }
        }
    }
}
