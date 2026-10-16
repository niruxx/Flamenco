import QtQuick
import qs.Commons

// Material Symbols Rounded glyph. `fill` animates between outlined and filled;
// the icon style setting (Theme.iconFill) fills every icon.
Text {
    id: root

    property string icon: ""
    property int size: Theme.iconSize
    property real fill: 0
    property int weight: Theme.iconWeight

    text: icon
    color: Theme.text
    font.family: Theme.iconFont
    font.pixelSize: size
    font.variableAxes: ({ "FILL": Math.max(fill, Theme.iconFill), "wght": weight, "opsz": Math.max(20, Math.min(48, size)) })
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    // Material Symbols' outlines overlap, and Qt's default (distance-field) text
    // renderer draws overlapping parts of a variable font as holes: speakers and
    // mics came out half dark. FreeType draws them whole.
    renderType: Text.NativeRendering

    Behavior on fill { Anim {} }
    Behavior on color { CAnim {} }
}
