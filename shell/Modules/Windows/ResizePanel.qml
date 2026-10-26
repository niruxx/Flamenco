import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

// Resize a window without grabbing its edges: preset widths and heights, sliders,
// steps and the arrow keys, and (floating) moving and centering it. Easier on a
// touchpad than a two-finger drag on a thin edge, and it works for apps that draw
// no frame. Opened from a window's menu or the "Resize the window" shortcut.
Variants {
    model: Quickshell.screens

    OverlayPanel {
        id: panel
        name: "resize"
        placement: "center"
        cardWidth: 460
        exclusiveKeyboard: true

        readonly property var w: Resize.target
        readonly property bool floating: !!w?.is_floating
        // its size now, when niri says (25.05+)
        readonly property var size: w?.layout?.window_size ?? null
        readonly property var entry: w ? Apps.lookup(w.app_id) : null

        onOpened: keys.forceActiveFocus()
        // its window went away
        onWChanged: if (!w && Panels.current === "resize") Panels.close()

        // sliders send the last value a moment after they stop moving, not every step
        property string pendingW: ""
        property string pendingH: ""
        Timer {
            id: send
            interval: 70
            onTriggered: {
                if (panel.pendingW)
                    Resize.width(panel.pendingW);
                if (panel.pendingH)
                    Resize.height(panel.pendingH);
                panel.pendingW = "";
                panel.pendingH = "";
            }
        }

        Item {
            id: keys
            implicitHeight: col.implicitHeight
            width: parent?.width ?? 0
            focus: true
            Keys.onPressed: event => {
                const shift = event.modifiers & Qt.ShiftModifier;
                const k = event.key;
                if (k === Qt.Key_Left || k === Qt.Key_Right) {
                    if (shift)
                        Resize.move(k === Qt.Key_Left ? -40 : 40, 0);
                    else
                        Resize.width(k === Qt.Key_Left ? "-5%" : "+5%");
                } else if (k === Qt.Key_Up || k === Qt.Key_Down) {
                    if (shift)
                        Resize.move(0, k === Qt.Key_Up ? -40 : 40);
                    else
                        Resize.height(k === Qt.Key_Up ? "-5%" : "+5%");
                } else if (k === Qt.Key_C) {
                    Resize.center();
                } else if (k === Qt.Key_Return || k === Qt.Key_Enter) {
                    Panels.close();
                } else {
                    return;
                }
                event.accepted = true;
            }

            ColumnLayout {
                id: col
                width: parent.width
                spacing: Theme.sp3

                // ── the window ──
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.sp3
                    AppIcon {
                        implicitSize: 36
                        name: panel.entry?.icon ?? Apps.iconFor(panel.w?.app_id ?? "")
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        FText {
                            Layout.fillWidth: true
                            text: panel.entry?.name ?? panel.w?.app_id ?? ""
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }
                        FText {
                            Layout.fillWidth: true
                            text: (panel.size ? Math.round(panel.size[0]) + " × " + Math.round(panel.size[1]) + "  ·  " : "") + (panel.floating ? "Floating" : "Tiled")
                            dim: true
                            font.pixelSize: Theme.fsSm
                            elide: Text.ElideRight
                        }
                    }
                    FButton {
                        text: panel.floating ? "Tile it" : "Float it"
                        variant: "tonal"
                        implicitHeight: 32
                        onClicked: Niri.toggleFloating(panel.w)
                    }
                }

                // ── width and height: presets, steps, a slider ──
                Repeater {
                    model: [
                        { axis: "width", label: "Width", icon: "width", max: panel.modelData.width, i: 0 },
                        { axis: "height", label: "Height", icon: "height", max: panel.modelData.height, i: 1 }
                    ]
                    ColumnLayout {
                        id: axisRow
                        required property var modelData
                        readonly property bool wide: modelData.axis === "width"
                        Layout.fillWidth: true
                        spacing: Theme.sp2
                        // tiled windows take the column's height from the workspace
                        visible: wide || panel.floating
                        function change(v) {
                            wide ? Resize.width(v) : Resize.height(v);
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.sp2
                            FIcon { icon: axisRow.modelData.icon; color: Theme.textDim }
                            FText { text: axisRow.modelData.label; Layout.preferredWidth: 56 }
                            Repeater {
                                model: [{ t: "⅓", v: "33.333%" }, { t: "½", v: "50%" }, { t: "⅔", v: "66.667%" }, { t: "Full", v: "100%" }]
                                FButton {
                                    required property var modelData
                                    text: modelData.t
                                    variant: "tonal"
                                    implicitHeight: 32
                                    implicitWidth: 56
                                    onClicked: axisRow.change(modelData.v)
                                }
                            }
                            Item { Layout.fillWidth: true }
                            FIconButton { icon: "remove"; size: 32; onClicked: axisRow.change("-5%") }
                            FIconButton { icon: "add"; size: 32; onClicked: axisRow.change("+5%") }
                        }
                        FSlider {
                            Layout.fillWidth: true
                            visible: panel.size !== null
                            from: 200
                            to: Math.max(400, axisRow.modelData.max)
                            stepSize: 10
                            value: panel.size ? panel.size[axisRow.modelData.i] : 0
                            showValue: true
                            valueText: Math.round(value) + " px"
                            onMoved: v => {
                                if (axisRow.wide)
                                    panel.pendingW = String(Math.round(v));
                                else
                                    panel.pendingH = String(Math.round(v));
                                send.restart();
                            }
                        }
                    }
                }

                // ── place (floating) ──
                RowLayout {
                    visible: panel.floating
                    Layout.fillWidth: true
                    spacing: Theme.sp2
                    FIcon { icon: "open_with"; color: Theme.textDim }
                    FText { text: "Place"; Layout.preferredWidth: 56 }
                    FButton { text: "Center"; icon: "center_focus_strong"; variant: "tonal"; implicitHeight: 32; onClicked: Resize.center() }
                    Item { Layout.fillWidth: true }
                    FIconButton { icon: "arrow_back"; size: 32; onClicked: Resize.move(-40, 0) }
                    FIconButton { icon: "arrow_upward"; size: 32; onClicked: Resize.move(0, -40) }
                    FIconButton { icon: "arrow_downward"; size: 32; onClicked: Resize.move(0, 40) }
                    FIconButton { icon: "arrow_forward"; size: 32; onClicked: Resize.move(40, 0) }
                }

                FText {
                    Layout.fillWidth: true
                    text: Niri.hyprland ? "Some of these need niri; on Hyprland, Super + right-drag resizes"
                        : "← → width · ↑ ↓ height" + (panel.floating ? " · Shift + arrows move · C centers" : "") + " · Enter or Esc when done. Super + right-drag resizes too"
                    dim: true
                    font.pixelSize: Theme.fsXs
                    wrapMode: Text.Wrap
                }
            }
        }
    }
}
