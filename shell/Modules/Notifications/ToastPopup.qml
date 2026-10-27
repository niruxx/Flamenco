import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services
import qs.Widgets

// The toast (Services/Toasts): a small pill with an icon and a line or two, on
// the screen you're using, at the top, the bottom or the middle. It never takes
// clicks: the pointer goes through it.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win

        required property ShellScreen modelData
        readonly property string pos: Settings.data.toasts.position || "bottom-center"
        readonly property var t: Toasts.current
        readonly property bool here: modelData.name === Panels.targetScreen("")
        // kept a moment after it goes, for the fade out
        property var shown: null
        onTChanged: if (t) shown = t

        screen: modelData
        visible: here && (t !== null || fade.running)
        color: "transparent"
        anchors {
            top: win.pos === "top-center"
            bottom: win.pos === "bottom-center"
        }
        margins.top: Theme.edge * 3
        margins.bottom: Theme.edge * 3
        implicitWidth: pill.width + 40
        implicitHeight: pill.height + 40
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "flamenco-toast"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        mask: Region {}

        Rectangle {
            id: pill
            anchors.centerIn: parent
            height: row.implicitHeight + 20
            width: row.implicitWidth + 36
            radius: height / 2
            color: Theme.popupBg
            border.width: 1
            border.color: Theme.alpha(Theme.border, 0.6)
            opacity: win.t ? 1 : 0
            scale: win.t ? 1 : 0.85
            Behavior on opacity { Anim { id: fade; duration: Theme.durMed } }
            Behavior on scale { Anim { easing.bezierCurve: Theme.curves.spring } }
            Behavior on width { Anim { easing.bezierCurve: Theme.curves.emphasizedDecel } }

            Finish {}

            RowLayout {
                id: row
                anchors.centerIn: parent
                spacing: 12
                FIcon {
                    icon: win.shown?.icon ?? ""
                    size: 22
                    fill: 1
                    color: Theme.accent
                }
                ColumnLayout {
                    spacing: 0
                    FText {
                        text: win.shown?.text ?? ""
                        font.weight: Font.DemiBold
                    }
                    FText {
                        visible: text !== ""
                        text: win.shown?.sub ?? ""
                        dim: true
                        font.pixelSize: Theme.fsXs
                    }
                }
            }
        }
    }
}
