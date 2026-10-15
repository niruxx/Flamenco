import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

// Clipboard history, from the bar's clipboard button (or `flamenco clipboard`):
// search it, click an entry to copy it again, remove entries, or clear it all.
// Keys: ↑ ↓ to pick, Enter copies, Delete removes, Esc closes.
Variants {
    model: Quickshell.screens

    OverlayPanel {
        id: panel
        name: "clipboard"
        hAlign: "right"
        cardWidth: 460
        exclusiveKeyboard: true

        property string query: ""
        property bool confirmClear: false
        readonly property var shown: {
            const q = query.trim().toLowerCase();
            return Clipboard.entries.filter(e => !q || (e.image ? "image " + e.kind : e.text.toLowerCase()).includes(q));
        }

        function copyAt(i) {
            const e = shown[i];
            if (!e)
                return;
            Clipboard.copy(e);
            Panels.close();
        }

        onOpened: {
            query = "";
            search.text = "";
            confirmClear = false;
            list.currentIndex = 0;
            Clipboard.refresh();
            search.focusInput();
        }

        Timer {
            id: clearTimeout
            interval: 3000
            onTriggered: panel.confirmClear = false
        }

        ColumnLayout {
            width: parent.width
            spacing: Theme.sp3

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.sp2

                FIcon {
                    icon: "content_paste"
                    size: 22
                    color: Theme.accent
                }
                FText {
                    Layout.fillWidth: true
                    text: "Clipboard"
                    font.pixelSize: Theme.fsLg
                    font.weight: Font.Bold
                }
                FText {
                    visible: Clipboard.entries.length > 0
                    text: Clipboard.entries.length + (Clipboard.entries.length === 1 ? " item" : " items")
                    dim: true
                    font.pixelSize: Theme.fsSm
                }
                // clearing asks for a second click
                FButton {
                    visible: Clipboard.entries.length > 0
                    text: panel.confirmClear ? "Clear all?" : "Clear"
                    icon: "delete_sweep"
                    variant: panel.confirmClear ? "filled" : "tonal"
                    onClicked: {
                        if (panel.confirmClear) {
                            Clipboard.wipe();
                            panel.confirmClear = false;
                        } else {
                            panel.confirmClear = true;
                            clearTimeout.restart();
                        }
                    }
                }
            }

            FTextField {
                id: search
                Layout.fillWidth: true
                visible: Clipboard.entries.length > 0
                icon: "search"
                placeholder: "Search the clipboard"
                onEdited: t => {
                    panel.query = t;
                    list.currentIndex = 0;
                }
                onAccepted: panel.copyAt(list.currentIndex)
                onKeyPressed: event => {
                    if (event.key === Qt.Key_Down) {
                        list.incrementCurrentIndex();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Up) {
                        list.decrementCurrentIndex();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Delete && panel.shown[list.currentIndex]) {
                        Clipboard.remove(panel.shown[list.currentIndex]);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Escape) {
                        Panels.close();
                        event.accepted = true;
                    }
                }
            }

            ListView {
                id: list
                Layout.fillWidth: true
                implicitHeight: Math.min(contentHeight, 460)
                visible: count > 0
                clip: true
                spacing: 4
                model: panel.shown
                boundsBehavior: Flickable.StopAtBounds
                highlightMoveDuration: Theme.durShort
                highlightFollowsCurrentItem: true
                highlight: Rectangle {
                    radius: Theme.rMd
                    color: Theme.alpha(Theme.accent, 0.14)
                    border.width: 1
                    border.color: Theme.alpha(Theme.accent, 0.35)
                }

                SmoothWheel {
                    view: list
                }

                delegate: Item {
                    id: row
                    required property var modelData
                    required property int index
                    width: list.width
                    height: modelData.image ? 92 : Math.max(48, rowText.implicitHeight + 20)
                    Component.onCompleted: Clipboard.preview(modelData)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 6
                        spacing: 10

                        // an image: its picture, once decoded
                        Rectangle {
                            visible: row.modelData.image
                            Layout.preferredWidth: 110
                            Layout.preferredHeight: 76
                            radius: Theme.rSm
                            color: Theme.surfaceHigh
                            clip: true
                            Image {
                                anchors.fill: parent
                                anchors.margins: 2
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                cache: false
                                source: Clipboard.previews[row.modelData.id] ? "file://" + Clipboard.previews[row.modelData.id] : ""
                            }
                            FIcon {
                                anchors.centerIn: parent
                                visible: !Clipboard.previews[row.modelData.id]
                                icon: "image"
                                color: Theme.textDim
                            }
                        }

                        FText {
                            id: rowText
                            Layout.fillWidth: true
                            text: row.modelData.image ? "Image · " + row.modelData.kind.toUpperCase() + "\n" + row.modelData.size : row.modelData.text
                            dim: row.modelData.image
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                            font.pixelSize: Theme.fsSm
                        }

                        FIconButton {
                            icon: "close"
                            size: 30
                            iconColor: Theme.textDim
                            opacity: hover.hovered || list.currentIndex === row.index ? 1 : 0
                            onClicked: Clipboard.remove(row.modelData)
                        }
                    }

                    HoverHandler {
                        id: hover
                        onHoveredChanged: if (hovered) list.currentIndex = row.index
                    }
                    TapHandler {
                        onTapped: panel.copyAt(row.index)
                    }
                }
            }

            // nothing to show, and why
            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: Theme.sp4
                Layout.bottomMargin: Theme.sp4
                visible: list.count === 0
                spacing: Theme.sp2

                FIcon {
                    Layout.alignment: Qt.AlignHCenter
                    icon: Clipboard.available ? "content_paste_off" : "content_paste_search"
                    size: 40
                    color: Theme.textDim
                }
                FText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    dim: true
                    text: !Clipboard.available ? "Clipboard history needs cliphist and wl-clipboard:\nsudo pacman -S cliphist wl-clipboard"
                        : panel.query !== "" ? "Nothing matches “" + panel.query.trim() + "”"
                        : !Clipboard.watching ? "History is off (Settings → Launcher → Clipboard history)"
                        : "Nothing copied yet. What you copy shows up here."
                }
            }

            FText {
                Layout.fillWidth: true
                visible: list.count > 0
                horizontalAlignment: Text.AlignHCenter
                text: "Click or Enter copies · Delete removes"
                dim: true
                font.pixelSize: Theme.fsXs
            }
        }
    }
}
