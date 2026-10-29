import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import qs.Commons
import qs.Services

// A cropped, frosted wallpaper backing for compositors without behind-window blur.
// All coordinates are logical screen coordinates; textures only cover the surface.
ClippingRectangle {
    id: root
    property string screenName: ""
    property real screenWidth: width
    property real screenHeight: height
    property real sampleX: 0
    property real sampleY: 0
    property real cornerRadius: Theme.rXl
    property real tintOpacity: Theme.panelOp
    radius: cornerRadius
    color: "transparent"

    Image {
        id: wallpaper
        width: Math.max(1, root.screenWidth)
        height: Math.max(1, root.screenHeight)
        source: root.visible && !Settings.data.wallpaper.solid ? Wallpapers.stillUrl(Wallpapers.forScreen(root.screenName)) : ""
        sourceSize: Qt.size(Math.max(1, root.screenWidth / 2), Math.max(1, root.screenHeight / 2))
        fillMode: ({ fit: Image.PreserveAspectFit, stretch: Image.Stretch, center: Image.Pad, tile: Image.Tile })[Settings.data.wallpaper.fillMode] ?? Image.PreserveAspectCrop
        asynchronous: true
        visible: false
    }
    ShaderEffectSource {
        id: crop
        anchors.fill: parent
        sourceItem: wallpaper
        sourceRect: Qt.rect(root.sampleX, root.sampleY, Math.max(1, root.width), Math.max(1, root.height))
        textureSize: Qt.size(Math.max(1, root.width), Math.max(1, root.height))
        hideSource: true
        live: root.visible
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: crop
        visible: wallpaper.status === Image.Ready
        blurEnabled: true
        blur: Theme.glassFrost
        blurMax: 48
        saturation: Theme.aeroGlass ? 0.18 : -0.25
        brightness: Theme.dark ? -0.08 : 0.04
    }
    Rectangle {
        anchors.fill: parent
        radius: root.cornerRadius
        color: Theme.alpha(Theme.surface, root.tintOpacity)
    }
}
