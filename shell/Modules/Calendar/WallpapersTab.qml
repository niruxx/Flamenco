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
        FFolderField {
            Layout.fillWidth: true
            path: Settings.data.wallpaper.dir
            status: Wallpapers.status
            busy: Wallpapers.scanning
            onChanged: p => Wallpapers.setDir(p)
        }
        FIconButton { icon: "shuffle"; flat: false; onClicked: Wallpapers.random() }
        FIconButton { icon: "refresh"; flat: false; onClicked: Wallpapers.rescan() }
        FIconButton { icon: "tune"; flat: false; onClicked: root.openSettings("wallpaper") }
    }

    FText {
        text: Wallpapers.status === "missing" ? "Folder not found: " + Wallpapers.dir
            : Wallpapers.scanning ? "Scanning " + Wallpapers.dir + "…"
            : Wallpapers.files.length + " images in " + Wallpapers.dir + " · current: " + (Paths.fileName(Wallpapers.current) || "none")
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
