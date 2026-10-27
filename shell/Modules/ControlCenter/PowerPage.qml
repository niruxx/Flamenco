import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

DetailPage {
    title: I18n.tr("Power")

    FText { text: I18n.tr("Power profile"); font.weight: Font.Bold; Layout.topMargin: 4 }

    Repeater {
        model: Power.profileOptions
        ListRow {
            required property var modelData
            icon: modelData.icon
            title: modelData.label
            subtitle: modelData.value === "power-saver" ? I18n.tr("Longer battery, lower performance") : modelData.value === "performance" ? I18n.tr("Maximum performance, more power and heat") : I18n.tr("Balance performance and power use")
            selected: Power.profileId === modelData.value
            onClicked: Power.setProfile(modelData.value)
            FIcon {
                visible: Power.profileId === modelData.value
                icon: "check"
                color: Theme.accent
            }
        }
    }

    FText {
        visible: !Power.hasPerformance
        Layout.fillWidth: true
        text: I18n.tr("Performance isn't offered by this machine's power-profiles-daemon.")
        dim: true
        wrapMode: Text.Wrap
        font.pixelSize: Theme.fsSm
    }

    ColumnLayout {
        visible: Power.hasBattery
        Layout.fillWidth: true
        Layout.topMargin: Theme.sp3
        spacing: 6
        FText { text: I18n.tr("Battery"); font.weight: Font.Bold }
        RowLayout {
            spacing: 10
            FIcon { icon: Power.icon; rotation: 90; fill: 1; color: Power.charging ? Theme.success : Theme.text }
            FText { text: Power.percent + "%" + (Power.charging ? " · charging" : "") + (Power.timeLeft ? " · " + Power.timeLeft : "") }
        }
    }
}
