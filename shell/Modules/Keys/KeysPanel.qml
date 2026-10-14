import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services
import qs.Widgets

// Keyboard cheat sheet: every binding in the compositor config, named and
// grouped (`flamenco keys`). Type to filter.
Variants {
    model: Quickshell.screens

    OverlayPanel {
        id: panel
        name: "keys"
        placement: "center"
        cardWidth: Math.min(1100, modelData.width - 80)
        exclusiveKeyboard: true

        property var keys: []
        property string filter: ""
        readonly property var order: ["Flamenco", "Apps", "Windows & columns", "Workspaces", "Monitors", "Screenshots", "Media & hardware", "Session", "Other"]
        readonly property var groups: {
            const f = filter.trim().toLowerCase();
            const out = [];
            for (const g of order) {
                const items = keys.filter(k => k.group === g && (!f || k.title.toLowerCase().includes(f) || k.key.toLowerCase().includes(f)));
                if (items.length)
                    out.push({ name: g, items });
            }
            return out;
        }

        onOpened: {
            filter = "";
            search.text = "";
            loader.running = true;
            search.input.forceActiveFocus();
        }

        Process {
            id: loader
            command: [Paths.bin, "keys", "--json"]
            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        panel.keys = JSON.parse(text);
                    } catch (e) {}
                }
            }
        }

        ColumnLayout {
            width: parent.width
            spacing: Theme.sp4

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.sp3
                FIcon { icon: "keyboard"; size: 26; fill: 1; color: Theme.accent }
                FText {
                    Layout.fillWidth: true
                    text: "Keyboard shortcuts"
                    font.pixelSize: Theme.fsXl
                    font.weight: Font.Bold
                }
                FTextField {
                    id: search
                    implicitWidth: 260
                    implicitHeight: 38
                    icon: "search"
                    placeholder: "Filter"
                    onEdited: t => panel.filter = t
                }
                FIconButton {
                    icon: "edit"
                    size: 34
                    onClicked: Panels.openSettings("keyboard")
                }
            }

            FText {
                visible: panel.groups.length === 0
                text: loader.running ? "Reading your bindings…" : "Nothing matches"
                dim: true
            }

            GridLayout {
                Layout.fillWidth: true
                columns: panel.cardWidth > 900 ? 3 : 2
                columnSpacing: Theme.sp4
                rowSpacing: Theme.sp4

                Repeater {
                    model: panel.groups
                    ColumnLayout {
                        id: grp
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        Layout.preferredWidth: 1
                        spacing: 6

                        FText {
                            text: grp.modelData.name.toUpperCase()
                            color: Theme.accent
                            font.pixelSize: Theme.fsXs
                            font.weight: Font.Bold
                            font.letterSpacing: 1.2
                        }
                        Repeater {
                            model: grp.modelData.items
                            RowLayout {
                                required property var modelData
                                Layout.fillWidth: true
                                spacing: Theme.sp3
                                FText {
                                    Layout.fillWidth: true
                                    text: modelData.title
                                    elide: Text.ElideRight
                                    font.pixelSize: Theme.fsSm
                                }
                                FKeycaps { combo: modelData.key }
                            }
                        }
                    }
                }
            }
        }
    }
}
