import QtQuick
import qs.Commons

// Material Symbols Rounded glyph. `fill` animates between outlined and filled.
Text {
    id: root

    property string icon: ""
    property int size: Theme.iconSize
    property real fill: 0
    property int weight: 400

    text: icon
    color: Theme.text
    font.family: Theme.iconFont
    font.pixelSize: size
    font.variableAxes: ({ "FILL": fill, "wght": weight, "opsz": Math.max(20, Math.min(48, size)) })
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter

    Behavior on fill { Anim {} }
    Behavior on color { CAnim {} }
}
