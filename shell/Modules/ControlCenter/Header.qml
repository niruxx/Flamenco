import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.Commons
import qs.Services
import qs.Widgets

RowLayout {
    spacing: Theme.sp3

    ClippingRectangle {
        Layout.preferredWidth: Math.round(48 * Theme.scale)
        Layout.preferredHeight: Math.round(48 * Theme.scale)
        radius: Theme.rLg
        color: Theme.accent

        FText {
            anchors.centerIn: parent
            visible: avatar.status !== Image.Ready
            text: Paths.user.charAt(0).toUpperCase()
            color: Theme.onAccent
            font.pixelSize: Theme.fsXl
            font.weight: Font.Bold
        }
        Image {
            id: avatar
            anchors.fill: parent
            source: Paths.toUrl(Settings.data.general.avatar)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize: Qt.size(96, 96)
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        // the labels fill the column so it really takes the spare width; otherwise
        // the leftover space is spread out and the buttons drift to the middle
        FText {
            Layout.fillWidth: true
            text: I18n.tr("Quick settings")
            font.pixelSize: Theme.fsXl
            font.weight: Font.Bold
            elide: Text.ElideRight
        }
        FText {
            Layout.fillWidth: true
            elide: Text.ElideRight
            text: Paths.user + " · " + SystemStats.uptimeText + (Power.hasBattery ? "  ·  " + Power.percent + "%" + (Power.timeLeft ? " · " + Power.timeLeft : "") : "")
            dim: true
            font.pixelSize: Theme.fsSm
        }
    }

    // settings · lock · power, pinned to the top-right corner
    Row {
        Layout.alignment: Qt.AlignRight | Qt.AlignTop
        spacing: 6

        FIconButton {
            icon: "settings"
            accessibleName: I18n.tr("Settings")
            flat: false
            onClicked: Panels.openSettings("")
        }
        FIconButton {
            icon: "lock"
            accessibleName: I18n.tr("Lock")
            flat: false
            onClicked: {
                Panels.close();
                Quickshell.execDetached([Paths.bin, "lock"]);
            }
        }
        FIconButton {
            icon: "power_settings_new"
            accessibleName: I18n.tr("Power")
            flat: false
            iconColor: Theme.error
            onClicked: Panels.open("power", Panels.screen)
        }
    }
}
