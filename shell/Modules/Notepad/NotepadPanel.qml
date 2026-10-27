import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

// Notepad: a few quick notes, saved as you type, with a Markdown preview.
Variants {
    model: Quickshell.screens

    OverlayPanel {
        id: panel
        name: "notepad"
        hAlign: "right"
        cardWidth: 560
        exclusiveKeyboard: true

        property string current: ""
        property bool preview: false
        readonly property var note: Notes.notes.find(n => n.id === current) ?? null

        onOpened: {
            if (!note)
                current = Notes.notes[0]?.id ?? Notes.add();
            preview = false;
            editor.forceActiveFocus();
        }

        ColumnLayout {
            width: parent.width
            implicitHeight: Math.min(560, (panel.screen?.height ?? 900) * 0.7)
            spacing: Theme.sp3

            RowLayout {
                Layout.fillWidth: true
                FIcon { icon: "sticky_note_2"; size: 24; fill: 1; color: Theme.accent }
                FText { Layout.fillWidth: true; text: I18n.tr("Notepad"); font.pixelSize: Theme.fsXl; font.weight: Font.Bold }
                FIconButton {
                    icon: panel.preview ? "edit" : "visibility"
                    size: 34
                    onClicked: panel.preview = !panel.preview
                }
                FIconButton {
                    icon: "content_copy"
                    size: 34
                    disabled: !panel.note || panel.note.text === ""
                    onClicked: Quickshell.execDetached(["wl-copy", panel.note.text])
                }
                FIconButton {
                    icon: "delete"
                    size: 34
                    iconColor: Theme.error
                    disabled: !panel.note
                    onClicked: {
                        Notes.remove(panel.current);
                        panel.current = Notes.notes[0]?.id ?? Notes.add();
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Theme.sp3

                // the notes
                FScroll {
                    id: listScroll
                    Layout.preferredWidth: 150
                    Layout.fillHeight: true
                    contentHeight: noteCol.implicitHeight
                    Column {
                        id: noteCol
                        width: listScroll.width - listScroll.gutter
                        spacing: 2
                        FButton {
                            width: parent.width
                            text: I18n.tr("New note")
                            icon: "add"
                            variant: "tonal"
                            onClicked: {
                                panel.current = Notes.add();
                                panel.preview = false;
                                editor.forceActiveFocus();
                            }
                        }
                        Repeater {
                            model: Notes.notes
                            Rectangle {
                                required property var modelData
                                width: noteCol.width
                                height: 38
                                radius: Theme.rMd
                                color: modelData.id === panel.current ? Theme.alpha(Theme.accent, 0.18) : "transparent"
                                FText {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 8
                                    verticalAlignment: Text.AlignVCenter
                                    text: Notes.title(modelData)
                                    elide: Text.ElideRight
                                    font.pixelSize: Theme.fsSm
                                    font.weight: modelData.id === panel.current ? Font.DemiBold : Font.Normal
                                }
                                StateLayer { onClicked: panel.current = modelData.id }
                            }
                        }
                    }
                }

                // the note
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Theme.rLg
                    color: Theme.alpha(Theme.text, 0.04)

                    Flickable {
                        id: flick
                        anchors.fill: parent
                        anchors.margins: Theme.sp3
                        clip: true
                        contentHeight: Math.max(height, (panel.preview ? md.implicitHeight : editor.implicitHeight) + 20)
                        boundsBehavior: Flickable.StopAtBounds

                        TextEdit {
                            cursorDelegate: Component { Caret {} }
                            id: editor
                            visible: !panel.preview
                            width: flick.width
                            wrapMode: TextEdit.Wrap
                            selectByMouse: true
                            color: Theme.text
                            selectionColor: Theme.alpha(Theme.accent, 0.4)
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fsMd
                            text: panel.note?.text ?? ""
                            onTextChanged: if (activeFocus && panel.note && text !== panel.note.text) Notes.setText(panel.current, text)
                            // keep the caret in view
                            onCursorRectangleChanged: {
                                if (cursorRectangle.y < flick.contentY)
                                    flick.contentY = cursorRectangle.y;
                                else if (cursorRectangle.y + cursorRectangle.height > flick.contentY + flick.height)
                                    flick.contentY = cursorRectangle.y + cursorRectangle.height - flick.height;
                            }
                        }
                        FText {
                            visible: !panel.preview && editor.text === ""
                            text: I18n.tr("Write something… Markdown works: # headings, **bold**, - lists")
                            dim: true
                        }
                        TextEdit {
                            cursorDelegate: Component { Caret {} }
                            id: md
                            visible: panel.preview
                            width: flick.width
                            readOnly: true
                            selectByMouse: true
                            wrapMode: TextEdit.Wrap
                            textFormat: TextEdit.MarkdownText
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fsMd
                            text: panel.note?.text ?? ""
                        }
                    }
                }
            }
        }
    }
}
