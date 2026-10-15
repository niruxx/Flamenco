// Vendored from https://github.com/AvengeMedia/DankMaterialShell (v1.6) and dank-qml-common (stable-1.6) (MIT) by tools/compat-vendor.py.
// Don't edit: change the vendoring tool or a Flamenco shim next to it.
import QtQuick
import qs.Compat.Dms.DankCommon.Common
import qs.Compat.Dms.DankCommon.Widgets

Rectangle {
    id: root

    property bool showHints: false

    height: 80
    radius: Style.cornerRadius
    color: Style.withAlpha(Style.surfaceContainer, 0.95)
    border.color: Style.primary
    border.width: 2
    opacity: showHints ? 1 : 0
    z: 100

    Column {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Style.spacingS
        spacing: Style.spacingXXS

        StyledText {
            text: I18n.tr("Tab/Shift+Tab: Nav • ←→↑↓: Grid Nav • Enter/Space: Select", "file browser keyboard shortcuts hint line")
            font.pixelSize: Style.fontSizeSmall
            color: Style.surfaceText
            width: parent.width
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }

        StyledText {
            text: I18n.tr("Alt+←/Backspace: Back • F1/I: File Info • F10: Help • Esc: Close", "file browser keyboard shortcuts hint line")
            font.pixelSize: Style.fontSizeSmall
            color: Style.surfaceText
            width: parent.width
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: Style.shortDuration
            easing.type: Style.standardEasing
        }
    }
}
