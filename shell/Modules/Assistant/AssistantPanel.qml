import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

// The AI assistant: chat with the model chosen in Settings → AI (Claude,
// OpenAI, Gemini, OpenRouter, or a local LM Studio / Ollama server).
Variants {
    model: Quickshell.screens

    OverlayPanel {
        id: panel
        name: "assistant"
        hAlign: "right"
        cardWidth: 460
        exclusiveKeyboard: true

        onOpened: {
            Ai.refresh();
            field.input.forceActiveFocus();
        }

        ColumnLayout {
            width: parent.width
            implicitHeight: Math.min(640, (panel.screen?.height ?? 900) * 0.75)
            spacing: Theme.sp3

            // ── header ──
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.sp3
                FIcon { icon: "auto_awesome"; size: 24; fill: 1; color: Theme.accent }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    FText { text: "Assistant"; font.pixelSize: Theme.fsXl; font.weight: Font.Bold }
                    FText {
                        Layout.fillWidth: true
                        text: Ai.current ? Ai.current.name + (Ai.model ? " · " + Ai.model : "") : "Not set up"
                        dim: true
                        font.pixelSize: Theme.fsSm
                        elide: Text.ElideRight
                    }
                }
                FIconButton {
                    icon: "delete_sweep"
                    size: 34
                    disabled: Ai.messages.count === 0
                    onClicked: Ai.clear()
                }
                FIconButton {
                    icon: "tune"
                    size: 34
                    onClicked: Panels.openSettings("ai")
                }
            }

            // ── not ready: what's missing ──
            Rectangle {
                visible: !Ai.ready
                Layout.fillWidth: true
                implicitHeight: setup.implicitHeight + Theme.sp4 * 2
                radius: Theme.rLg
                color: Theme.alpha(Theme.accent, 0.1)
                ColumnLayout {
                    id: setup
                    anchors.fill: parent
                    anchors.margins: Theme.sp4
                    spacing: Theme.sp2
                    FText {
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        text: !Ai.current ? "Choose a provider in Settings → AI."
                            : Ai.current.kind === "anthropic" && !Ai.status.anthropicSdk ? "Claude needs the Anthropic SDK: install python-anthropic, or pick another provider."
                            : Ai.current.key === "required" && !Ai.current.keyFrom ? "Add your " + Ai.current.name + " API key in Settings → AI."
                            : "Choose a model for " + Ai.current.name + " in Settings → AI."
                    }
                    FButton {
                        text: "Open AI settings"
                        icon: "tune"
                        variant: "tonal"
                        onClicked: Panels.openSettings("ai")
                    }
                }
            }

            // ── the conversation ──
            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: Theme.sp3
                model: Ai.messages
                boundsBehavior: Flickable.StopAtBounds
                // follow the reply as it streams in
                onCountChanged: Qt.callLater(() => list.positionViewAtEnd())
                onContentHeightChanged: if (Ai.busy) list.positionViewAtEnd()

                SmoothWheel { view: list }

                FText {
                    anchors.centerIn: parent
                    width: parent.width * 0.8
                    visible: list.count === 0 && Ai.ready
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    text: "Ask anything. " + (Ai.current?.id === "lmstudio" || Ai.current?.id === "ollama" ? "This model runs on your computer." : "Messages go to " + (Ai.current?.name ?? "the provider") + ".")
                    dim: true
                }

                delegate: Item {
                    id: msg
                    required property string role
                    required property string content
                    required property bool error
                    required property int index
                    readonly property bool mine: role === "user"
                    readonly property bool streaming: Ai.busy && index === list.count - 1 && !mine
                    width: list.width
                    implicitHeight: bubble.height

                    Rectangle {
                        id: bubble
                        anchors.right: msg.mine ? parent.right : undefined
                        anchors.left: msg.mine ? undefined : parent.left
                        width: Math.min(parent.width * (msg.mine ? 0.85 : 1), body.implicitWidth + Theme.sp3 * 2 + 2)
                        height: body.implicitHeight + Theme.sp3 * 2 + (tools.visible ? tools.height + 4 : 0)
                        radius: Theme.rLg
                        color: msg.mine ? Theme.alpha(Theme.accent, 0.18) : Theme.alpha(Theme.text, 0.05)

                        TextEdit {
                            cursorDelegate: Component { Caret {} }
                            id: body
                            x: Theme.sp3
                            y: Theme.sp3
                            width: Math.min(implicitWidth, list.width * (msg.mine ? 0.85 : 1) - Theme.sp3 * 2 - 2)
                            readOnly: true
                            selectByMouse: true
                            wrapMode: TextEdit.Wrap
                            textFormat: msg.mine ? TextEdit.PlainText : TextEdit.MarkdownText
                            // replies are Markdown: images shown as their description only (they'd be fetched from anywhere)
                            text: msg.mine ? (msg.content || "") : String(msg.content || (msg.streaming ? "…" : msg.error ? "(no reply)" : "")).replace(/!\[([^\]]*)\]\([^)]*\)/g, "$1").replace(/<img\b[^>]*>/gi, "")
                            color: msg.error ? Theme.textDim : Theme.text
                            selectionColor: Theme.alpha(Theme.accent, 0.4)
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fsMd
                        }
                        Row {
                            id: tools
                            visible: !msg.mine && !msg.streaming && msg.content !== ""
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.sp2
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 2
                            FIconButton {
                                icon: "content_copy"
                                size: 26
                                iconSize: 14
                                onClicked: Quickshell.execDetached(["wl-copy", msg.content])
                            }
                        }
                    }
                }
            }

            FText {
                visible: Ai.error !== ""
                Layout.fillWidth: true
                text: Ai.error
                color: Theme.error
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fsSm
            }

            // ── input ──
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.sp2
                FTextField {
                    id: field
                    Layout.fillWidth: true
                    implicitHeight: 44
                    icon: "chat"
                    placeholder: Ai.ready ? "Message" : "Set up AI first"
                    onAccepted: if (Ai.ready && !Ai.busy && text.trim() !== "") {
                        Ai.send(text);
                        text = "";
                    }
                }
                FIconButton {
                    icon: Ai.busy ? "stop" : "send"
                    size: 44
                    active: true
                    disabled: !Ai.ready || (!Ai.busy && field.text.trim() === "")
                    onClicked: {
                        if (Ai.busy) {
                            Ai.stop();
                        } else {
                            Ai.send(field.text);
                            field.text = "";
                        }
                    }
                }
            }
        }
    }
}
