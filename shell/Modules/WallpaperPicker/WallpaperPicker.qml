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
        // the grid switcher; the carousel one is WallpaperCarousel (Settings → Wallpaper → Switcher)
        name: Settings.data.wallpaper.picker === "grid" ? "wallpaper" : "wallpaper-grid"
        cardWidth: Math.min(980, modelData.width - 80)
        onOpened: Wallpapers.rescan()
        property string source: "folder"        // folder | wallhaven | live

        ColumnLayout {
            width: parent.width
            spacing: Theme.sp3

            RowLayout {
                Layout.fillWidth: true
                FSegmented {
                    implicitWidth: 300
                    implicitHeight: 34
                    options: [{ value: "folder", label: "Your folder" }, { value: "wallhaven", label: "Wallhaven" }, { value: "live", label: "Live" }]
                    current: panel.source
                    onSelected: v => panel.source = v
                }
                FText {
                    Layout.fillWidth: true
                    text: "Wallpapers"
                    font.pixelSize: Theme.fsXl
                    font.weight: Font.Bold
                }
                FText { text: Wallpapers.files.length + " wallpapers"; dim: true }
                // per screen, or every screen at once
                FSegmented {
                    visible: Quickshell.screens.length > 1
                    implicitWidth: 260
                    implicitHeight: 34
                    options: [{ value: false, label: "All screens" }, { value: true, label: "This screen (" + panel.modelData.name + ")" }]
                    current: Settings.data.wallpaper.perScreen
                    onSelected: v => Settings.data.wallpaper.perScreen = v
                }
                FIconButton { icon: "shuffle"; onClicked: Wallpapers.random(panel.modelData.name) }
                FIconButton { icon: "refresh"; onClicked: Wallpapers.rescan() }
                FIconButton { icon: "tune"; onClicked: Panels.openSettings("wallpaper") }
            }

            WallpaperGrid {
                visible: panel.source === "folder"
                Layout.fillWidth: true
                implicitHeight: 460
                screenName: panel.modelData.name
            }
            Loader {
                Layout.fillWidth: true
                active: panel.source === "wallhaven"
                visible: active
                sourceComponent: WallhavenGrid {
                    screenName: panel.modelData.name
                    minSize: Qt.size(panel.modelData.width, panel.modelData.height)
                }
            }
            Loader {
                Layout.fillWidth: true
                Layout.preferredHeight: 560
                active: panel.source === "live"
                visible: active
                sourceComponent: LiveGrid {
                    screenName: panel.modelData.name
                }
            }
        }
    }
}
