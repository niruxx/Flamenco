import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

Page {
    id: page
    title: "Lock & Idle"
    readonly property var l: Settings.data.lock

    Group {
        SwitchRow { title: "Lock when idle"; icon: "lock_clock"; target: page.l; key: "autoLock" }
        SliderRow { title: "Lock after"; icon: "timer"; target: page.l; key: "idleMinutes"; from: 1; to: 60; stepSize: 1; suffix: " min" }
        SliderRow { title: "Turn screens off after"; subtitle: "0 disables"; icon: "monitor"; target: page.l; key: "screenOffMinutes"; from: 0; to: 90; stepSize: 1; suffix: " min" }
        SwitchRow { title: "Media controls on lock screen"; icon: "music_note"; target: page.l; key: "showMedia" }
        TextRow { title: "Avatar image"; icon: "account_circle"; target: Settings.data.general; key: "avatar"; placeholder: "~/.face" }
    }

    Group {
        title: "Night light"
        SwitchRow { title: "Night light"; subtitle: "Uses gammastep"; icon: "nightlight"; target: Settings.data.night; key: "enabled" }
        SliderRow { title: "Temperature"; icon: "thermostat"; target: Settings.data.night; key: "temperature"; from: 2500; to: 6000; stepSize: 100; suffix: "K" }
    }

    FButton {
        text: "Lock now"
        icon: "lock"
        onClicked: Quickshell.execDetached([Paths.bin, "lock"])
    }
}
