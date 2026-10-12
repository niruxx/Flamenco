import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets
import qs.Modules.WallpaperPicker

ColumnLayout {
    id: root
    signal openSettings(string page)
    spacing: Theme.sp3

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.sp2
        FTextField {
            Layout.fillWidth: true
            icon: "folder"
            placeholder: "~/Pictures/Wallpapers"
            text: Settings.data.wallpaper.dir
            onAccepted: Settings.data.wallpaper.dir = text
            onEditingFinished: Settings.data.wallpaper.dir = text
        }
        FIconButton { icon: "shuffle"; flat: false; onClicked: Wallpapers.random() }
        FIconButton { icon: "refresh"; flat: false; onClicked: Wallpapers.rescan() }
        FIconButton { icon: "tune"; flat: false; onClicked: root.openSettings("wallpaper") }
    }

    FText {
        text: Wallpapers.files.length + " images · current: " + (Paths.fileName(Wallpapers.current) || "none")
        dim: true
        font.pixelSize: Theme.fsSm
        Layout.fillWidth: true
        elide: Text.ElideMiddle
    }

    WallpaperGrid {
        Layout.fillWidth: true
        implicitHeight: 360
    }
}
