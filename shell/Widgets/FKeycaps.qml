import QtQuick
import qs.Commons

// Renders "Mod+Shift+S" as a row of keycaps.
Row {
    id: root
    property string combo: ""
    property bool accent: false
    spacing: 4

    readonly property var pretty: ({
            "Mod": "Super", "Ctrl": "Ctrl", "Alt": "Alt", "Shift": "Shift", "Super": "Super",
            "Comma": ",", "Period": ".", "Slash": "/", "BackSlash": "\\", "Minus": "-", "Equal": "=",
            "BracketLeft": "[", "BracketRight": "]", "Semicolon": ";", "Apostrophe": "'", "Grave": "`",
            "Return": "Enter", "Escape": "Esc", "Page_Up": "PgUp", "Page_Down": "PgDn", "BackSpace": "⌫",
            "Left": "←", "Right": "→", "Up": "↑", "Down": "↓", "Space": "Space",
            "XF86AudioRaiseVolume": "Vol+", "XF86AudioLowerVolume": "Vol−", "XF86AudioMute": "Mute",
            "XF86AudioMicMute": "Mic mute", "XF86AudioPlay": "Play", "XF86AudioNext": "Next", "XF86AudioPrev": "Prev",
            "XF86MonBrightnessUp": "Bright+", "XF86MonBrightnessDown": "Bright−"
        })

    Repeater {
        model: root.combo ? root.combo.split("+") : []
        Rectangle {
            required property string modelData
            width: Math.max(26, label.implicitWidth + 14)
            height: 26
            radius: Theme.rXs
            color: root.accent ? Theme.alpha(Theme.accent, 0.2) : Theme.surfaceHighest
            border.width: 1
            border.color: root.accent ? Theme.accent : Theme.border

            // keycap "lip"
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 4
                height: 2
                radius: 1
                color: Theme.alpha(Theme.shadow, 0.25)
            }
            FText {
                id: label
                anchors.centerIn: parent
                text: root.pretty[modelData] ?? modelData
                font.pixelSize: Theme.fsXs
                font.weight: Font.DemiBold
                mono: true
            }
        }
    }
}
