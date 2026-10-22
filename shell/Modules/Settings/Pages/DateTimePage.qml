import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

// Settings → Date & Time: the time zone (by hand or following where you are),
// keeping the clock synced over the network and with which time servers, setting
// it by hand, and how the shell shows the time.
Page {
    id: page
    title: "Date & Time"
    subtitle: "The system's clock and time zone. Changes ask for your password in a terminal (it's a system setting)."
    readonly property var st: DateTime.st

    Component.onCompleted: {
        DateTime.refresh();
        DateTime.loadZones();
    }

    // now, large
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: nowCol.implicitHeight + Theme.sp5 * 2
        radius: Math.max(12, Theme.rLg)
        color: Theme.alpha(Theme.surface, Math.min(1, Theme.settingsOp + 0.04))
        border.width: 1
        border.color: Theme.alpha(Theme.text, 0.05)
        ColumnLayout {
            id: nowCol
            anchors.centerIn: parent
            spacing: 2
            FText {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDateTime(Time.now, Time.use24h ? "HH:mm" : "h:mm AP")
                font.pixelSize: Math.round(54 * Theme.scale)
                font.weight: Font.Light
            }
            FText { Layout.alignment: Qt.AlignHCenter; text: Qt.formatDate(Time.now, "dddd d MMMM yyyy"); dim: true }
            Row {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 6
                spacing: 6
                Repeater {
                    model: [
                        { icon: "public", text: page.st.timezone || "Time zone unknown", on: true },
                        { icon: page.st.synced ? "sync" : "sync_disabled", text: page.st.ntp ? (page.st.synced ? "Synced" + (page.st.server ? " with " + page.st.server : "") : "Syncing…") : "Not syncing", on: !!page.st.synced }
                    ]
                    Rectangle {
                        required property var modelData
                        width: chip.implicitWidth + 20
                        height: 26
                        radius: 13
                        color: modelData.on ? Theme.alpha(Theme.accent, 0.14) : Theme.alpha(Theme.text, 0.07)
                        Row {
                            id: chip
                            anchors.centerIn: parent
                            spacing: 5
                            FIcon { anchors.verticalCenter: parent.verticalCenter; icon: parent.parent.modelData.icon; size: 15; color: parent.parent.modelData.on ? Theme.accent : Theme.textDim }
                            FText { anchors.verticalCenter: parent.verticalCenter; text: parent.parent.modelData.text; font.pixelSize: Theme.fsXs }
                        }
                    }
                }
            }
        }
    }

    SettingRow {
        visible: DateTime.st.available === false
        title: "timedatectl isn't available"
        subtitle: "Date & Time works with systemd (timedatectl and systemd-timesyncd)"
        icon: "warning"
    }

    Group {
        title: "Time zone"
        SettingRow {
            title: "Automatic time zone"
            subtitle: (Settings.data.datetime.autoTimezone
                ? "Follows where you are (by your connection), checked at start and every few hours" + (DateTime.detected ? ": " + DateTime.detected : "")
                : "Set it below") + (Settings.data.datetime.autoTimezone && !page.st.autoRule ? ". Needs a one-time password to let it change the time zone by itself" : "")
            icon: "travel_explore"
            FSwitch {
                checked: Settings.data.datetime.autoTimezone
                onToggled: c => DateTime.setAuto(c)
            }
        }
        SettingRow {
            title: "Time zone"
            subtitle: "Search, e.g. london, tokyo, new_york"
            icon: "public"
            enabled: !Settings.data.datetime.autoTimezone
            opacity: enabled ? 1 : 0.5
            Row {
                spacing: 8
                FTextField {
                    id: zoneSearch
                    implicitWidth: 180
                    icon: "search"
                    placeholder: page.st.timezone || "Search"
                }
                FDropdown {
                    implicitWidth: 230
                    readonly property string q: zoneSearch.text.trim().toLowerCase().replace(/ /g, "_")
                    options: DateTime.zones.filter(z => !q || z.toLowerCase().includes(q)).slice(0, 200).map(z => ({ value: z, label: z.replace(/_/g, " ") }))
                    current: page.st.timezone ?? ""
                    placeholder: "Choose…"
                    onSelected: v => {
                        if (v !== page.st.timezone)
                            DateTime.setTimezone(v);
                    }
                }
            }
        }
        SettingRow {
            visible: !!page.st.autoRule
            title: "Changing the time zone without a password"
            subtitle: "Allowed for administrators at this computer (a polkit rule set up for automatic time zone). Only the time zone, nothing else"
            icon: "verified_user"
            FButton {
                text: "Remove"
                variant: "text"
                onClicked: DateTime.inTerminal(["auto-rule", "off"])
            }
        }
    }

    Group {
        title: "Clock"
        SettingRow {
            title: "Set the time automatically"
            subtitle: page.st.chrony ? "chrony keeps the time here (its own settings in /etc/chrony.conf)" : "Keeps the clock right over the network (systemd-timesyncd)"
            icon: "sync"
            FSwitch {
                checked: !!page.st.ntp
                enabled: !page.st.chrony && page.st.canNtp !== false
                onToggled: c => DateTime.setNtp(c)
            }
        }
        SettingRow {
            visible: !page.st.chrony
            title: "Time servers"
            subtitle: page.st.customServers ? "Using yours: " + page.st.customServers : "Your distribution's (" + (page.st.server || "default") + "). Or your own: host names or IPs, space-separated"
            icon: "dns"
            Row {
                spacing: 8
                FTextField {
                    id: servers
                    implicitWidth: 220
                    text: page.st.customServers ?? ""
                    placeholder: "pool.ntp.org 192.168.1.1"
                    onAccepted: DateTime.setServers(text)
                }
                FButton {
                    text: "Save"
                    variant: "tonal"
                    disabled: servers.text.trim() === (page.st.customServers ?? "")
                    onClicked: DateTime.setServers(servers.text)
                }
                FButton {
                    visible: !!page.st.customServers
                    text: "Default"
                    variant: "text"
                    onClicked: DateTime.setServers("")
                }
            }
        }
        SettingRow {
            visible: !page.st.ntp
            title: "Set the date and time"
            subtitle: "While automatic time is off"
            icon: "edit_calendar"
            Row {
                spacing: 8
                FTextField {
                    id: manual
                    implicitWidth: 180
                    text: Qt.formatDateTime(new Date(), "yyyy-MM-dd HH:mm")
                    placeholder: "YYYY-MM-DD HH:MM"
                }
                FButton {
                    text: "Set"
                    variant: "tonal"
                    disabled: !/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}(:\d{2})?$/.test(manual.text.trim())
                    onClicked: DateTime.setTime(manual.text.trim())
                }
            }
        }
    }

    Group {
        title: "Shown as"
        SwitchRow { title: "24-hour time"; icon: "schedule"; target: Settings.data.general; key: "use24h" }
        SettingRow {
            title: "The bar's clock"
            subtitle: "Its layout, alignment and seconds are in Clock & Weather"
            icon: "toolbar"
            FButton {
                text: "Clock & Weather"
                variant: "text"
                onClicked: Panels.settingsPage = "clock"
            }
        }
    }
}
