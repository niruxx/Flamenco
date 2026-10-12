import QtQuick
import qs.Commons

Text {
    property bool dim: false
    property bool mono: false

    color: dim ? Theme.textDim : Theme.text
    font.family: mono ? Theme.monoFamily : Theme.fontFamily
    font.pixelSize: Theme.fsMd
    verticalAlignment: Text.AlignVCenter
    textFormat: Text.PlainText

    Behavior on color { CAnim {} }
}
