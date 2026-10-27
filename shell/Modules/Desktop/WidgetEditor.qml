import QtQuick
import Quickshell.Io
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services
import qs.Widgets

// Arranging desktop widgets, opened from quick settings (Panels.editWidgets):
// a sidebar of widgets to drag onto the desktop (or click to add), and the
// placed ones can be dragged, resized (S / M / L) and removed. Everything is
// in this one layer, so dragging from the sidebar onto the desktop just works.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: ed

        required property ShellScreen modelData
        readonly property bool shown: Panels.widgetsEdit && Panels.screen === modelData.name
        readonly property string screenName: modelData.name

        screen: modelData
        visible: shown
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        // inside the space the bar and dock leave free, so it never covers them
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "flamenco-widget-editor"
        WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        function done() {
            Panels.widgetsEdit = false;
        }

        // the desktop shows through, a little dimmed
        Rectangle {
            anchors.fill: parent
            color: Theme.alpha(Theme.shadow, 0.3)
            TapHandler { onTapped: ed.done() }
        }

        Item {
            focus: ed.shown
            Keys.onEscapePressed: ed.done()
        }

        FText {
            anchors.top: parent.top
            anchors.topMargin: Theme.gap * 4
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: -side.width / 2
            visible: Desk.on(ed.screenName).length === 0
            text: I18n.tr("Drag a widget from the right onto the desktop")
            font.pixelSize: Theme.fsXl
            color: "white"
            opacity: 0.85
        }

        // ── the placed widgets ──
        Repeater {
            model: Desk.on(ed.screenName)

            Item {
                id: slot
                required property var modelData
                width: body.width
                height: body.height
                x: Desk.px(modelData.x, ed.width, width)
                y: Desk.px(modelData.y, ed.height, height)
                z: drag.active ? 10 : toolsShown ? 5 : 0

                WidgetBody {
                    id: body
                    spec: slot.modelData
                    editing: true
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -5
                    radius: Theme.rXl + 5
                    color: "transparent"
                    border.width: 2
                    border.color: Theme.alpha(Theme.accent, hov.hovered || drag.active ? 1 : 0.45)
                }

                HoverHandler {
                    id: hov
                    cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    onHoveredChanged: if (!hovered) linger.restart()
                }
                // the toolbar sits above the widget: it stays a moment after the pointer
                // leaves the widget, and while it's on the toolbar, so it can be reached
                Timer {
                    id: linger
                    interval: 600
                }
                readonly property bool toolsShown: (hov.hovered || toolHov.hovered || linger.running) && !drag.active
                DragHandler {
                    id: drag
                    target: slot
                    xAxis.minimum: 0
                    xAxis.maximum: ed.width - slot.width
                    yAxis.minimum: 0
                    yAxis.maximum: ed.height - slot.height
                    onActiveChanged: if (!active) Desk.update(slot.modelData.id, { x: Desk.snap(slot.x, ed.width, slot.width) / ed.width, y: Desk.snap(slot.y, ed.height, slot.height) / ed.height })
                }

                // size and remove, above the widget while it's hovered
                Rectangle {
                    anchors.bottom: parent.top
                    anchors.bottomMargin: 4
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: slot.toolsShown
                    HoverHandler { id: toolHov }
                    width: tools.width + 12
                    height: tools.height + 8
                    radius: height / 2
                    color: Theme.panelBg
                    border.width: 1
                    border.color: Theme.alpha(Theme.border, 0.7)
                    Row {
                        id: tools
                        anchors.centerIn: parent
                        spacing: 2
                        Repeater {
                            model: ["s", "m", "l"]
                            FButton {
                                required property string modelData
                                text: modelData.toUpperCase()
                                variant: (slot.modelData.size || "m") === modelData ? "filled" : "text"
                                implicitHeight: 30
                                onClicked: Desk.update(slot.modelData.id, { size: modelData })
                            }
                        }
                        // the photo frame: its picture, or back to the wallpaper slideshow
                        FIconButton {
                            visible: slot.modelData.type === "photo"
                            icon: "add_photo_alternate"
                            size: 30
                            onClicked: {
                                photoPick.target = slot.modelData.id;
                                photoPick.running = true;
                            }
                        }
                        FIconButton {
                            visible: slot.modelData.type === "photo" && !!slot.modelData.path
                            icon: "slideshow"
                            size: 30
                            onClicked: Desk.update(slot.modelData.id, { path: "" })
                        }
                        FIconButton {
                            icon: "delete"
                            size: 30
                            iconColor: Theme.error
                            onClicked: Desk.remove(slot.modelData.id)
                        }
                    }
                }
            }
        }

        // ── the sidebar ──
        Rectangle {
            id: side
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.margins: Theme.gap * 2
            width: 330
            radius: Theme.rXl
            color: Theme.panelBg
            border.width: 1
            border.color: Theme.alpha(Theme.border, 0.7)

            // keep clicks here from closing the editor
            MouseArea { anchors.fill: parent }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.sp4
                spacing: Theme.sp3

                RowLayout {
                    Layout.fillWidth: true
                    FIcon { icon: "widgets"; size: 24; color: Theme.accent; fill: 1 }
                    FText {
                        Layout.fillWidth: true
                        text: I18n.tr("Desktop widgets")
                        font.pixelSize: Theme.fsXl
                        font.weight: Font.Bold
                    }
                    FIconButton { icon: "close"; size: 32; onClicked: ed.done() }
                }
                FText {
                    Layout.fillWidth: true
                    text: I18n.tr("Drag one onto the desktop, or click to add it. Drag placed widgets to move them; hover one to resize or remove it.")
                    dim: true
                    wrapMode: Text.Wrap
                    font.pixelSize: Theme.fsSm
                }

                // the catalog scrolls (by wheel and the scrollbar) inside the sidebar; cards
                // are dragged out onto the desktop, so a drag doesn't scroll it
                FScroll {
                    id: catalog
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentHeight: cards.implicitHeight
                    interactive: false
                    WheelHandler {
                        onWheel: event => {
                            const d = event.pixelDelta.y !== 0 ? event.pixelDelta.y : event.angleDelta.y / 120 * 70;
                            catalog.contentY = Math.max(0, Math.min(catalog.maxY, catalog.contentY - d));
                        }
                    }
                    ColumnLayout {
                        id: cards
                        width: catalog.width - catalog.gutter
                        spacing: Theme.sp2
                        Repeater {
                            model: Desk.catalog

                            Rectangle {
                                id: card
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: 62
                                radius: Theme.rLg
                                color: cardHov.hovered ? Theme.alpha(Theme.accent, 0.14) : Theme.alpha(Theme.text, 0.05)
                                Behavior on color { CAnim {} }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: Theme.sp3
                                    spacing: Theme.sp3
                                    Rectangle {
                                        implicitWidth: 38
                                        implicitHeight: 38
                                        radius: Theme.rMd
                                        color: Theme.alpha(Theme.accent, 0.18)
                                        FIcon { anchors.centerIn: parent; icon: card.modelData.icon; color: Theme.accent; fill: 1 }
                                    }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0
                                        FText { text: card.modelData.name; font.weight: Font.DemiBold }
                                        FText { Layout.fillWidth: true; text: card.modelData.about; dim: true; font.pixelSize: Theme.fsSm; elide: Text.ElideRight }
                                    }
                                    FIcon { icon: "drag_indicator"; color: Theme.textDim }
                                }

                                HoverHandler { id: cardHov; cursorShape: Qt.OpenHandCursor }
                                TapHandler { onTapped: Desk.addHere(card.modelData.type, ed.screenName) }
                                DragHandler {
                                    target: null
                                    onActiveChanged: {
                                        if (active) {
                                            ghost.type = card.modelData.type;
                                        } else {
                                            ghost.drop();
                                        }
                                    }
                                    onCentroidChanged: if (active) ghost.at = centroid.scenePosition
                                }
                            }
                        }
                    }
                }

                FText { text: I18n.tr("Style"); font.weight: Font.DemiBold }
                FSegmented {
                    Layout.fillWidth: true
                    implicitHeight: 38
                    options: [{ value: "card", label: I18n.tr("Card") }, { value: "glass", label: I18n.tr("Glass") }, { value: "bare", label: I18n.tr("Bare") }]
                    current: Settings.data.desktop.style
                    onSelected: v => Settings.data.desktop.style = v
                }
                RowLayout {
                    Layout.fillWidth: true
                    FButton {
                        text: I18n.tr("Remove all")
                        variant: "text"
                        disabled: Desk.on(ed.screenName).length === 0
                        onClicked: Desk.clear(ed.screenName)
                    }
                    Item { Layout.fillWidth: true }
                    FButton {
                        text: I18n.tr("Done")
                        icon: "done"
                        onClicked: ed.done()
                    }
                }
            }
        }

        // the widget being dragged out of the sidebar
        Item {
            id: ghost
            property string type: ""
            property point at: Qt.point(-1000, -1000)
            visible: type !== ""
            width: gb.width
            height: gb.height
            x: at.x - width / 2
            y: at.y - height / 2
            z: 20
            opacity: 0.85

            function drop() {
                // dropped on the desktop (the pointer outside the sidebar)
                if (type !== "" && at.x < side.x)
                    Desk.add(type, ed.screenName, Math.max(0, x) / ed.width, Math.max(0, y) / ed.height);
                type = "";
                at = Qt.point(-1000, -1000);
            }

            WidgetBody {
                id: gb
                spec: ({ id: "", type: ghost.type || "clock", size: "m", text: "" })
                editing: true
            }
        }

        // the photo frame's picture chooser
        Process {
            id: photoPick
            property string target
            command: [Paths.bin, "pick", "image", Paths.home + "/Pictures"]
            stdout: StdioCollector {
                onStreamFinished: {
                    const p = text.trim();
                    if (p && photoPick.target)
                        Desk.update(photoPick.target, { path: p });
                }
            }
        }
    }
}
