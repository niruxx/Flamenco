import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

// A color setting: a few named choices ("" / "accent" / "text"…), some swatches and
// any hex color. `target[key]` holds the value: a choice's value, or "#rrggbb".
SettingRow {
    id: root
    property var target
    property string key
    property var choices: []                  // [{ value, label }]
    property var swatches: ["#ff5d73", "#ff8a4c", "#f5c542", "#7bd88f", "#3ec7c2", "#5b9cff", "#9b7bff", "#ffffff"]
    readonly property string value: String(target[key] ?? "")
    signal edited

    function set(v) {
        target[key] = v;
        edited();
    }
    function setHex(t) {
        t = t.trim();
        if (/^#?[0-9a-fA-F]{6}$/.test(t))
            set((t.startsWith("#") ? t : "#" + t).toLowerCase());
    }

    RowLayout {
        spacing: 6
        Repeater {
            model: root.choices
            Rectangle {
                id: chip
                required property var modelData
                readonly property bool sel: root.value === modelData.value
                implicitWidth: chipText.implicitWidth + 22
                implicitHeight: 28
                radius: 14
                color: sel ? Theme.accent : Theme.surfaceHighest
                FText {
                    id: chipText
                    anchors.centerIn: parent
                    text: chip.modelData.label
                    font.pixelSize: Theme.fsSm
                    font.weight: Font.DemiBold
                    color: chip.sel ? Theme.onAccent : Theme.text
                }
                StateLayer {
                    tint: chip.sel ? Theme.onAccent : Theme.text
                    onClicked: root.set(chip.modelData.value)
                }
            }
        }
        Repeater {
            model: root.swatches
            Rectangle {
                required property string modelData
                readonly property bool sel: root.value.toLowerCase() === modelData
                implicitWidth: 22
                implicitHeight: 22
                radius: 11
                color: modelData
                border.width: sel ? 3 : 1
                border.color: sel ? Theme.text : Theme.alpha(Theme.text, 0.2)
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.set(parent.modelData)
                }
            }
        }
        FTextField {
            implicitWidth: 104
            implicitHeight: 32
            text: root.value.startsWith("#") ? root.value : ""
            placeholder: "#rrggbb"
            onAccepted: root.setHex(text)
            onEditingFinished: root.setHex(text)
        }
    }
}
