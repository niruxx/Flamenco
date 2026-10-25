import QtQuick
import QtQuick.Effects
import qs.Commons

// Material Symbols Rounded glyph. `fill` animates between outlined and filled;
// the icon style setting (Theme.iconFill) fills every icon.
//
// With an icon theme chosen for the UI (Settings → Appearance → UI icons) the
// theme's icon is drawn instead, in the same spot and size: a symbolic (one-color)
// icon filled with this icon's color, so accents and dimmed icons still read; a
// full-color one as it is. Names the theme lacks stay Material Symbols.
Text {
    id: root

    property string icon: ""
    property int size: Theme.iconSize
    property real fill: 0
    property int weight: Theme.iconWeight
    readonly property var themed: UiIcons.active && icon ? (UiIcons.map[icon] ?? null) : null

    // themed: an em space keeps the glyph's size in layouts, the picture goes over it
    text: themed ? " " : icon
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

    Loader {
        active: root.themed !== null
        anchors.centerIn: parent
        width: Math.round(root.size * 0.92)
        height: width
        sourceComponent: root.themed?.s ? symbolicC : colorC
    }
    // one color: the icon is a mask over this icon's color
    Component {
        id: symbolicC
        Item {
            Image {
                id: shape
                anchors.fill: parent
                source: Paths.toUrl(root.themed.p)
                sourceSize: Qt.size(width * 2, height * 2)
                asynchronous: true
                smooth: true
                visible: false
                layer.enabled: true
            }
            Rectangle {
                anchors.fill: parent
                color: root.color
                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: shape
                    // the mask's 0 → 1 alpha maps to hidden → shown, smoothly
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1.0
                }
            }
        }
    }
    Component {
        id: colorC
        Image {
            source: Paths.toUrl(root.themed.p)
            sourceSize: Qt.size(width * 2, height * 2)
            asynchronous: true
            smooth: true
        }
    }
}
