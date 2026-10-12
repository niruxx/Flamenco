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
        Layout.preferredWidth: 48
        Layout.preferredHeight: 48
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
        FText {
            text: Paths.user
            font.pixelSize: Theme.fsLg
            font.weight: Font.Bold
        }
        FText {
            text: "up " + SystemStats.uptimeText + (Power.hasBattery ? "  ·  " + Power.percent + "%" + (Power.timeLeft ? " · " + Power.timeLeft : "") : "")
            dim: true
            font.pixelSize: Theme.fsSm
        }
    }

    FIconButton {
        icon: "settings"
        flat: false
        onClicked: Panels.openSettings("")
    }
    FIconButton {
        icon: "lock"
        flat: false
        onClicked: {
            Panels.close();
            Quickshell.execDetached([Paths.bin, "lock"]);
        }
    }
    FIconButton {
        icon: "power_settings_new"
        flat: false
        iconColor: Theme.error
        onClicked: Panels.open("power", Panels.screen)
    }
}
