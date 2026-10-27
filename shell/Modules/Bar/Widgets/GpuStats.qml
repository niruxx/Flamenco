import QtQuick
import qs.Commons
import qs.Services
import qs.Widgets

// The graphics card: how busy, and its temperature (AMD and Intel through the
// kernel; NVIDIA while "Watch the NVIDIA GPU" is on in the system hub).
BarChip {
    id: root
    property string screenName
    property int barLevel: 0
    property bool barVisible: SystemStats.gpuBusy >= 0 && barLevel < 2
    highlighted: Panels.current === "performance"
    onClicked: Panels.toggle("performance", screenName, root)
    Component.onCompleted: SystemStats.gpuUsers++
    Component.onDestruction: SystemStats.gpuUsers--

    BarFlow {
        spacing: Theme.barVertical ? 0 : 4
        FIcon { icon: "videogame_asset"; size: Theme.barIcon; color: SystemStats.colorFor("gpu", SystemStats.gpuBusy * 100, Theme.accent2) }
        FText { text: Math.round(SystemStats.gpuBusy * 100) + (Theme.barVertical ? "" : "%"); mono: true; font.pixelSize: Theme.barVertical ? Theme.fsXs : Theme.fsSm }
        FText {
            visible: SystemStats.gpuTemp > 0 && root.barLevel < 1
            text: Math.round(SystemStats.gpuTemp) + "°"
            mono: true
            color: SystemStats.colorFor("temp", SystemStats.gpuTemp, Theme.text)
            font.pixelSize: Theme.barVertical ? Theme.fsXs : Theme.fsSm
        }
    }
}
