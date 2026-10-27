import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

// Control center → Night light: on / off, warmth, dimming and the schedule, at a glance.
DetailPage {
    id: page
    title: I18n.tr("Night light")
    readonly property var n: Settings.data.night
    headerExtra: FIconButton {
        icon: "tune"
        size: 30
        onClicked: Panels.openSettings("night")
    }

    // on / off, and what happens next
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 64
        radius: Theme.rLg
        color: Toggles.nightLight ? Theme.alpha(Theme.warning, 0.18) : Theme.alpha(Theme.text, 0.05)
        Behavior on color { CAnim {} }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.sp4
            anchors.rightMargin: Theme.sp3
            spacing: Theme.sp3
            FIcon { icon: "nightlight"; size: 26; fill: Toggles.nightLight ? 1 : 0; color: Toggles.nightLight ? Theme.warning : Theme.textDim }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                FText { text: Toggles.nightLight ? I18n.tr("On") : I18n.tr("Off"); font.weight: Font.Bold }
                FText { Layout.fillWidth: true; text: Toggles.status; dim: true; font.pixelSize: Theme.fsSm; elide: Text.ElideRight }
            }
            FSwitch {
                checked: Toggles.nightLight
                onToggled: c => Toggles.setNightLight(c)
            }
        }
    }

    FText { Layout.topMargin: Theme.sp2; text: I18n.tr("Warmth · ") + page.n.temperature + " K"; dim: true; font.pixelSize: Theme.fsSm; font.weight: Font.Bold }
    FPillSlider {
        Layout.fillWidth: true
        icon: "thermostat"
        // left warm, right neutral: the slider runs 2000 → 6000 K
        value: (page.n.temperature - 2000) / 4000
        from: "#ff8a3d"
        to: "#ffe0b8"
        onMoved: v => page.n.temperature = Math.round((2000 + v * 4000) / 100) * 100
    }
    FText { Layout.topMargin: Theme.sp2; text: I18n.tr("Dim · ") + Math.round((page.n.brightness ?? 1) * 100) + "%"; dim: true; font.pixelSize: Theme.fsSm; font.weight: Font.Bold }
    FPillSlider {
        Layout.fillWidth: true
        icon: "brightness_low"
        value: ((page.n.brightness ?? 1) - 0.5) / 0.5
        from: Theme.accent2
        to: Theme.accent
        onMoved: v => page.n.brightness = Math.round((0.5 + v * 0.5) * 20) / 20
    }

    FText { Layout.topMargin: Theme.sp2; text: I18n.tr("Schedule"); dim: true; font.pixelSize: Theme.fsSm; font.weight: Font.Bold }
    FSegmented {
        Layout.fillWidth: true
        options: [{ value: "off", label: I18n.tr("Manual") }, { value: "sun", label: I18n.tr("Sunset → sunrise") }, { value: "custom", label: page.n.from + " → " + page.n.to }]
        current: page.n.schedule || "off"
        onSelected: v => page.n.schedule = v
    }
}
