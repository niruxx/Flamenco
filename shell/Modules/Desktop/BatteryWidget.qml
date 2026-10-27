import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

// Battery: a ring with the charge, how long it lasts (or until full), and the
// power profile (click it to switch). On a desktop: just the power profile.
RowLayout {
    id: root
    property real k: 1
    property var spec
    property bool editing: false
    spacing: Math.round(Theme.sp4 * k)

    FRing {
        visible: Power.hasBattery
        size: Math.round(92 * root.k)
        value: Power.percent / 100
        text: Power.percent + "%"
        label: ""
        color: Power.charging ? Theme.success : Power.percent <= (Settings.data.bar.batteryLow || 15) ? Theme.error : Theme.accent
    }
    FIcon {
        visible: !Power.hasBattery
        icon: "power"
        size: Math.round(48 * root.k)
        color: Theme.accent
    }
    ColumnLayout {
        spacing: Math.round(2 * root.k)
        FText {
            text: !Power.hasBattery ? I18n.tr("On mains power") : Power.charging ? (Power.percent >= 99 ? I18n.tr("Fully charged") : I18n.tr("Charging")) : I18n.tr("On battery")
            font.weight: Font.DemiBold
            font.pixelSize: Math.round(Theme.fsLg * root.k)
        }
        FText {
            visible: text !== ""
            text: Power.hasBattery ? Power.timeLeft : ""
            dim: true
            font.pixelSize: Math.round(Theme.fsSm * root.k)
        }
        // the power profile, as a chip
        Rectangle {
            Layout.topMargin: Math.round(6 * root.k)
            implicitWidth: prow.implicitWidth + Math.round(20 * root.k)
            implicitHeight: Math.round(30 * root.k)
            radius: height / 2
            color: Theme.alpha(Theme.accent, 0.16)
            Row {
                id: prow
                anchors.centerIn: parent
                spacing: Math.round(6 * root.k)
                FIcon { anchors.verticalCenter: parent.verticalCenter; icon: Power.profileIcon; size: Math.round(16 * root.k); fill: 1; color: Theme.accent }
                FText { anchors.verticalCenter: parent.verticalCenter; text: Power.profileName; font.pixelSize: Math.round(Theme.fsSm * root.k); color: Theme.accent; font.weight: Font.DemiBold }
            }
            MouseArea {
                anchors.fill: parent
                enabled: !root.editing
                cursorShape: Qt.PointingHandCursor
                onClicked: Power.cycleProfile()
            }
        }
    }
}
