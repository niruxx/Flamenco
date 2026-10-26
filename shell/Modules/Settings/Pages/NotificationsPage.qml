import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: "Notifications"
    readonly property var n: Settings.data.notifications

    Group {
        title: "Shown by"
        ChoiceRow {
            title: "Notification daemon"
            subtitle: page.n.backend === "mako"
                ? (Mako.found ? "mako, in your theme's colors, fonts and corners, at the position and timeout below. Do Not Disturb follows Flamenco's switch. There's no history panel with mako: the bell brings the last notification back (middle-click clears them)"
                    : "mako isn't installed, so Flamenco keeps showing notifications (Settings → System check)")
                : "Flamenco's own: popups, a history panel or shade, actions and images"
            icon: "notifications"
            target: page.n
            key: "backend"
            segWidth: 120
            options: [{ value: "flamenco", label: "Flamenco", icon: "local_fire_department" }, { value: "mako", label: "mako", icon: "chat_bubble" }]
        }
        SettingRow {
            visible: page.n.backend === "mako" && Mako.found
            title: "Send a test"
            subtitle: "Its config is " + Mako.path + "; your own ~/.config/mako is left alone"
            icon: "send"
            FButton {
                text: "Test notification"
                variant: "tonal"
                onClicked: Quickshell.execDetached(["notify-send", "-a", "Flamenco", "Hello from mako", "Themed to match " + (Palettes.labels[Settings.data.appearance.palette] ?? "your theme")])
            }
        }
    }

    Group {
        SwitchRow { title: "Show popups"; icon: "notifications_active"; target: page.n; key: "popups" }
        SwitchRow { title: "Do not disturb"; subtitle: "Only critical notifications pop up"; icon: "do_not_disturb_on"; target: page.n; key: "dnd" }
        ChoiceRow {
            title: "Position"
            icon: "picture_in_picture"
            target: page.n
            key: "position"
            segWidth: 76
            options: [{ value: "top-left", label: "↖" }, { value: "top-center", label: "↑" }, { value: "top-right", label: "↗" }, { value: "bottom-left", label: "↙" }, { value: "bottom-right", label: "↘" }]
        }
        SliderRow { title: "Popup timeout"; icon: "timer"; target: page.n; key: "timeout"; from: 2; to: 20; stepSize: 1; suffix: "s" }
    }

    Group {
        title: "Devices"
        SwitchRow {
            title: "Plugging in and taking out"
            subtitle: "A pop-up when a drive or an accessory is connected or disconnected, like GNOME's. Drives get Open and Eject"
            icon: "usb"
            target: Settings.data.devices
            key: "enabled"
        }
        ChoiceRow {
            visible: Settings.data.devices.enabled
            title: "Where"
            subtitle: "Its own spot, apart from other notifications"
            icon: "picture_in_picture"
            target: Settings.data.devices
            key: "position"
            segWidth: 64
            options: [{ value: "top-left", label: "↖" }, { value: "top-center", label: "↑" }, { value: "top-right", label: "↗" }, { value: "bottom-left", label: "↙" }, { value: "bottom-center", label: "↓" }, { value: "bottom-right", label: "↘" }]
        }
        SwitchRow { visible: Settings.data.devices.enabled; title: "Drives and memory cards"; subtitle: "USB sticks, external disks, SD cards"; icon: "hard_drive"; target: Settings.data.devices; key: "drives" }
        SwitchRow { visible: Settings.data.devices.enabled; title: "Accessories"; subtitle: "Keyboards, mice, phones, cameras, headsets and other USB devices"; icon: "devices"; target: Settings.data.devices; key: "accessories" }
        SwitchRow { visible: Settings.data.devices.enabled; title: "When they're taken out"; icon: "eject"; target: Settings.data.devices; key: "removals" }
        SwitchRow { visible: Settings.data.devices.enabled; title: "Sound"; subtitle: "The sound theme's device sounds"; icon: "volume_up"; target: Settings.data.devices; key: "sound" }
        SliderRow { visible: Settings.data.devices.enabled; title: "Stays for"; subtitle: "Drives twice as long (they have buttons); the pointer on one keeps it"; icon: "timer"; target: Settings.data.devices; key: "timeout"; from: 2; to: 20; stepSize: 1; suffix: "s" }
        SettingRow {
            visible: Settings.data.devices.enabled
            title: "Try it"
            subtitle: Settings.data.notifications.dnd ? "Do not disturb is on: device pop-ups wait until it's off" : "Shows a pop-up the way a USB drive would"
            icon: "science"
            FButton {
                text: "Show a test"
                variant: "tonal"
                onClicked: Devices.test()
            }
        }
    }

    Group {
        id: center
        title: "Notification center"
        readonly property var b: Settings.data.bar
        // which bar section has the bell (the shared layout)
        readonly property string bellSide: ["left", "center", "right"].find(k => (b[k] || []).includes("notifications")) ?? ""
        function moveBell(side) {
            for (const k of ["left", "center", "right"])
                b[k] = (b[k] || []).filter(x => x !== "notifications");
            const l = (b[side] || []).slice();
            if (side === "left")
                l.splice(Math.min(1, l.length), 0, "notifications");   // just after the start button
            else if (side === "right" && l.includes("clock"))
                l.splice(l.indexOf("clock"), 0, "notifications");
            else
                l.push("notifications");
            b[side] = l;
        }

        ChoiceRow {
            title: "Style"
            subtitle: page.n.style === "shade" ? "A full-height sheet from the side, with the date, the month and notifications grouped by app" : "A drop-down under the bar"
            icon: "view_sidebar"
            target: page.n
            key: "style"
            segWidth: 120
            options: [{ value: "panel", label: "Drop-down", icon: "arrow_drop_down_circle" }, { value: "shade", label: "Shade", icon: "view_sidebar" }]
        }
        ChoiceRow {
            visible: page.n.style === "shade"
            title: "Shade comes in from"
            subtitle: page.n.shadeSide === "auto" ? "The side of the bar the bell is on" : ""
            icon: "swap_horiz"
            target: page.n
            key: "shadeSide"
            options: [{ value: "auto", label: "The bell's side" }, { value: "left", label: "Left" }, { value: "right", label: "Right" }]
            segWidth: 120
        }
        SwitchRow { visible: page.n.style === "shade"; title: "Calendar in the shade"; subtitle: "The month above the notifications"; icon: "calendar_month"; target: page.n; key: "shadeCalendar" }
        SettingRow {
            title: "Bell in the bar"
            subtitle: center.bellSide === "" ? "Not in the bar: pick a side to add it" : "Click it to open the notification center; right-click for Do not disturb"
            icon: "notifications"
            FSegmented {
                implicitWidth: 270
                options: [{ value: "left", label: "Left" }, { value: "center", label: "Center" }, { value: "right", label: "Right" }]
                current: center.bellSide
                onSelected: v => center.moveBell(v)
            }
        }
        SettingRow {
            title: "Preview"
            icon: "visibility"
            FButton {
                text: "Open it"
                variant: "tonal"
                onClicked: {
                    Panels.settingsOpen = false;
                    Panels.open("notifications", "");
                }
            }
        }
    }

    Group {
        title: "On-screen display"
        SwitchRow { title: "Volume & brightness OSD"; icon: "tune"; target: Settings.data.osd; key: "enabled" }
        ChoiceRow { title: "Position"; icon: "vertical_align_bottom"; target: Settings.data.osd; key: "position"; options: [{ value: "top", label: "Top" }, { value: "bottom", label: "Bottom" }] }
    }

    Group {
        title: "History"
        SettingRow {
            title: Notifs.history.count + " notifications stored"
            icon: "history"
            FButton { text: "Clear"; variant: "tonal"; icon: "delete_sweep"; onClicked: Notifs.clearAll() }
        }
    }
}
