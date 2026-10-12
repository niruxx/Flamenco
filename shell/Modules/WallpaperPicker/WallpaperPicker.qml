import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.Commons
import qs.Services
import qs.Widgets

Variants {
    model: Quickshell.screens

    OverlayPanel {
        id: panel
        name: "wallpaper"
        cardWidth: Math.min(980, modelData.width - 80)
        onOpened: Wallpapers.rescan()

        ColumnLayout {
            width: parent.width
            spacing: Theme.sp3

            RowLayout {
                Layout.fillWidth: true
                FText {
                    Layout.fillWidth: true
                    text: "Wallpapers"
                    font.pixelSize: Theme.fsXl
                    font.weight: Font.Bold
                }
                FText { text: Wallpapers.files.length + " images"; dim: true }
                FIconButton { icon: "shuffle"; onClicked: Wallpapers.random() }
                FIconButton { icon: "refresh"; onClicked: Wallpapers.rescan() }
                FIconButton { icon: "tune"; onClicked: Panels.openSettings("wallpaper") }
            }

            WallpaperGrid {
                Layout.fillWidth: true
                implicitHeight: 460
            }
        }
    }
}
