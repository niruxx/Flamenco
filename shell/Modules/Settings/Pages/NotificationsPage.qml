import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: I18n.tr("Notifications")
    readonly property var n: Settings.data.notifications

    Group {
        title: I18n.tr("Shown by")
        ChoiceRow {
            title: I18n.tr("Notification daemon")
            subtitle: page.n.backend === "mako"
                ? (Mako.found ? "mako, in your theme's colors, fonts and corners, at the position and timeout below. Do Not Disturb follows Flamenco's switch. There's no history panel with mako: the bell brings the last notification back (middle-click clears them)"
                    : "mako isn't installed, so Flamenco keeps showing notifications (Settings → System check)")
                : "Flamenco's own: popups, a history panel or shade, actions and images"
            icon: "notifications"
            target: page.n
            key: "backend"
            segWidth: 120
            options: [{ value: "flamenco", label: I18n.tr("Flamenco"), icon: "local_fire_department" }, { value: "mako", label: I18n.tr("mako"), icon: "chat_bubble" }]
        }
        SettingRow {
            visible: page.n.backend === "mako" && Mako.found
            title: I18n.tr("Send a test")
            subtitle: I18n.tr("Its config is ") + Mako.path + "; your own ~/.config/mako is left alone"
            icon: "send"
            FButton {
                text: I18n.tr("Test notification")
                variant: "tonal"
                onClicked: Quickshell.execDetached(["notify-send", "-a", "Flamenco", "Hello from mako", "Themed to match " + (Palettes.labels[Settings.data.appearance.palette] ?? "your theme")])
            }
        }
    }

    Group {
        SwitchRow { title: I18n.tr("Show popups"); icon: "notifications_active"; target: page.n; key: "popups" }
        SwitchRow { title: I18n.tr("Do not disturb"); subtitle: I18n.tr("Only critical notifications pop up"); icon: "do_not_disturb_on"; target: page.n; key: "dnd" }
        ChoiceRow {
            title: I18n.tr("Position")
            icon: "picture_in_picture"
            target: page.n
            key: "position"
            segWidth: 76
            options: [{ value: "top-left", label: "↖" }, { value: "top-center", label: "↑" }, { value: "top-right", label: "↗" }, { value: "bottom-left", label: "↙" }, { value: "bottom-right", label: "↘" }]
        }
        SliderRow { title: I18n.tr("Popup timeout"); icon: "timer"; target: page.n; key: "timeout"; from: 2; to: 20; stepSize: 1; suffix: "s" }
    }

    NotificationRulesSection {}

    Group {
        title: I18n.tr("Toasts")
        SwitchRow {
            title: I18n.tr("Show what changed")
            subtitle: I18n.tr("A small pop-up for a moment when Caps Lock, the keyboard layout, the power profile, Wi-Fi, Bluetooth, Do Not Disturb, night light or keep awake change. Clicks go through it")
            icon: "chat_bubble"
            target: Settings.data.toasts
            key: "enabled"
        }
        ChoiceRow {
            visible: Settings.data.toasts.enabled
            title: I18n.tr("Where")
            icon: "picture_in_picture"
            target: Settings.data.toasts
            key: "position"
            segWidth: 96
            options: [{ value: "top-center", label: I18n.tr("Top") }, { value: "center", label: I18n.tr("Middle") }, { value: "bottom-center", label: I18n.tr("Bottom") }]
        }
        SwitchRow { visible: Settings.data.toasts.enabled; title: I18n.tr("Caps Lock and Num Lock"); icon: "keyboard_capslock"; target: Settings.data.toasts; key: "lockKeys" }
        SwitchRow { visible: Settings.data.toasts.enabled; title: I18n.tr("Keyboard layout"); icon: "keyboard"; target: Settings.data.toasts; key: "layout" }
        SwitchRow { visible: Settings.data.toasts.enabled; title: I18n.tr("Power profile"); icon: "bolt"; target: Settings.data.toasts; key: "powerProfile" }
        SwitchRow { visible: Settings.data.toasts.enabled; title: I18n.tr("Wi-Fi and Bluetooth"); icon: "wifi"; target: Settings.data.toasts; key: "connections" }
        SwitchRow { visible: Settings.data.toasts.enabled; title: I18n.tr("Do Not Disturb, night light, keep awake, dark mode"); icon: "do_not_disturb_on"; target: Settings.data.toasts; key: "modes" }
        SettingRow {
            visible: Settings.data.toasts.enabled
            title: I18n.tr("Try it")
            icon: "science"
            FButton { text: I18n.tr("Show a toast"); variant: "tonal"; onClicked: Toasts.test() }
        }
    }

    Group {
        title: I18n.tr("Devices")
        SwitchRow {
            title: I18n.tr("Plugging in and taking out")
            subtitle: I18n.tr("A pop-up when a drive or an accessory is connected or disconnected, like GNOME's. Drives get Open and Eject")
            icon: "usb"
            target: Settings.data.devices
            key: "enabled"
        }
        ChoiceRow {
            visible: Settings.data.devices.enabled
            title: I18n.tr("Where")
            subtitle: I18n.tr("Its own spot, apart from other notifications")
            icon: "picture_in_picture"
            target: Settings.data.devices
            key: "position"
            segWidth: 64
            options: [{ value: "top-left", label: "↖" }, { value: "top-center", label: "↑" }, { value: "top-right", label: "↗" }, { value: "bottom-left", label: "↙" }, { value: "bottom-center", label: "↓" }, { value: "bottom-right", label: "↘" }]
        }
        SwitchRow { visible: Settings.data.devices.enabled; title: I18n.tr("Drives and memory cards"); subtitle: I18n.tr("USB sticks, external disks, SD cards"); icon: "hard_drive"; target: Settings.data.devices; key: "drives" }
        SwitchRow { visible: Settings.data.devices.enabled; title: I18n.tr("Accessories"); subtitle: I18n.tr("Keyboards, mice, phones, cameras, headsets and other USB devices"); icon: "devices"; target: Settings.data.devices; key: "accessories" }
        SwitchRow { visible: Settings.data.devices.enabled; title: I18n.tr("When they're taken out"); icon: "eject"; target: Settings.data.devices; key: "removals" }
        SwitchRow { visible: Settings.data.devices.enabled; title: I18n.tr("Sound"); subtitle: I18n.tr("The sound theme's device sounds"); icon: "volume_up"; target: Settings.data.devices; key: "sound" }
        SliderRow { visible: Settings.data.devices.enabled; title: I18n.tr("Stays for"); subtitle: I18n.tr("Drives twice as long (they have buttons); the pointer on one keeps it"); icon: "timer"; target: Settings.data.devices; key: "timeout"; from: 2; to: 20; stepSize: 1; suffix: "s" }
        SettingRow {
            visible: Settings.data.devices.enabled
            title: I18n.tr("Try it")
            subtitle: Settings.data.notifications.dnd ? I18n.tr("Do not disturb is on: device pop-ups wait until it's off") : I18n.tr("Shows a pop-up the way a USB drive would")
            icon: "science"
            FButton {
                text: I18n.tr("Show a test")
                variant: "tonal"
                onClicked: Devices.test()
            }
        }
    }

    Group {
        id: center
        title: I18n.tr("Notification center")
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
            title: I18n.tr("Style")
            subtitle: page.n.style === "shade" ? I18n.tr("A full-height sheet from the side, with the date, the month and notifications grouped by app") : I18n.tr("A drop-down under the bar")
            icon: "view_sidebar"
            target: page.n
            key: "style"
            segWidth: 120
            options: [{ value: "panel", label: I18n.tr("Drop-down"), icon: "arrow_drop_down_circle" }, { value: "shade", label: I18n.tr("Shade"), icon: "view_sidebar" }]
        }
        ChoiceRow {
            visible: page.n.style === "shade"
            title: I18n.tr("Shade comes in from")
            subtitle: page.n.shadeSide === "auto" ? I18n.tr("The side of the bar the bell is on") : ""
            icon: "swap_horiz"
            target: page.n
            key: "shadeSide"
            options: [{ value: "auto", label: I18n.tr("The bell's side") }, { value: "left", label: I18n.tr("Left") }, { value: "right", label: I18n.tr("Right") }]
            segWidth: 120
        }
        SwitchRow { visible: page.n.style === "shade"; title: I18n.tr("Calendar in the shade"); subtitle: I18n.tr("The month above the notifications"); icon: "calendar_month"; target: page.n; key: "shadeCalendar" }
        SettingRow {
            title: I18n.tr("Bell in the bar")
            subtitle: center.bellSide === "" ? I18n.tr("Not in the bar: pick a side to add it") : I18n.tr("Click it to open the notification center; right-click for Do not disturb")
            icon: "notifications"
            FSegmented {
                implicitWidth: 270
                options: [{ value: "left", label: I18n.tr("Left") }, { value: "center", label: I18n.tr("Center") }, { value: "right", label: I18n.tr("Right") }]
                current: center.bellSide
                onSelected: v => center.moveBell(v)
            }
        }
        SettingRow {
            title: I18n.tr("Preview")
            icon: "visibility"
            FButton {
                text: I18n.tr("Open it")
                variant: "tonal"
                onClicked: {
                    Panels.settingsOpen = false;
                    Panels.open("notifications", "");
                }
            }
        }
    }

    Group {
        title: I18n.tr("On-screen display")
        SwitchRow { title: I18n.tr("Volume & brightness OSD"); icon: "tune"; target: Settings.data.osd; key: "enabled" }
        ChoiceRow { title: I18n.tr("Position"); icon: "vertical_align_bottom"; target: Settings.data.osd; key: "position"; options: [{ value: "top", label: I18n.tr("Top") }, { value: "bottom", label: I18n.tr("Bottom") }] }
    }

    Group {
        title: I18n.tr("History")
        SettingRow {
            title: Notifs.history.count + " notifications stored"
            icon: "history"
            FButton { text: I18n.tr("Clear"); variant: "tonal"; icon: "delete_sweep"; onClicked: Notifs.clearAll() }
        }
    }
}
