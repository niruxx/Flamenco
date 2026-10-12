import QtQuick
import QtQuick.Effects
import qs.Commons
import qs.Widgets

// One blurred, dimmed wallpaper image for niri's backdrop; cross-fades via `shown`.
Item {
    id: layer
    property alias source: img.source
    property bool shown: false
    property int fillMode: Image.PreserveAspectCrop

    anchors.fill: parent
    opacity: shown && img.status === Image.Ready ? 1 : 0
    Behavior on opacity { Anim { duration: Theme.durXl } }

    Image {
        id: img
        anchors.fill: parent
        fillMode: layer.fillMode
        asynchronous: true
        // it's blurred anyway, so half resolution is plenty
        sourceSize: Qt.size(Math.max(1, layer.width / 2), Math.max(1, layer.height / 2))
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: img
        blurEnabled: true
        blur: 1
        blurMax: 48
        brightness: -0.25
        saturation: -0.15
    }
}
