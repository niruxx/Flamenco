import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs.Commons
import qs.Services
import qs.Widgets

// The per-app volume mixer: every app playing sound as a card with its volume,
// mute and which output it plays on; an app with several streams (browser tabs)
// opens up to set each one. Apps recording (the microphone) follow. Used by the
// volume panel, the control center's Mixer page and Settings → Sound.
// The rows are keyed by app (ScriptModel diffs the keys), so a card keeps its
// state (opened, mid-drag) while streams come and go.
ColumnLayout {
    id: root

    property bool showRecording: true
    property bool roomy: false                  // bigger cards (Settings)
    spacing: Theme.sp2

    // ── nothing playing ──
    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: Theme.sp2
        Layout.bottomMargin: Theme.sp2
        visible: Audio.streamGroups.length === 0 && (!root.showRecording || Audio.recorderGroups.length === 0)
        spacing: 4
        FIcon { Layout.alignment: Qt.AlignHCenter; icon: "music_off"; size: 32; color: Theme.textDim }
        FText { Layout.alignment: Qt.AlignHCenter; text: I18n.tr("No apps are playing sound"); dim: true }
    }

    Repeater {
        model: ScriptModel { values: Audio.streamGroups.map(g => g.key) }
        delegate: mixRow
    }

    FText {
        visible: root.showRecording && Audio.recorderGroups.length > 0
        Layout.topMargin: Theme.sp2
        text: I18n.tr("Recording")
        dim: true
        font.pixelSize: Theme.fsSm
        font.weight: Font.Bold
    }
    Repeater {
        model: ScriptModel { values: root.showRecording ? Audio.recorderGroups.map(g => "rec:" + g.key) : [] }
        delegate: mixRow
    }

    Component {
        id: mixRow

        Rectangle {
            id: card
            required property string modelData
            readonly property bool rec: modelData.startsWith("rec:")     // an app recording
            readonly property var g: (rec ? Audio.recorderGroups : Audio.streamGroups).find(x => x.key === (rec ? modelData.slice(4) : modelData)) ?? { key: "", name: "", icon: "", nodes: [] }
            readonly property bool muted: Audio.groupMuted(g)
            readonly property real vol: Audio.groupVolume(g)
            readonly property int many: g.nodes.length
            readonly property var devices: rec ? Audio.sources : Audio.sinks
            // where it plays (or records from): the other end of its first stream's links
            readonly property var device: {
                const lg = links.linkGroups ?? [];
                const n = g.nodes[0];
                const l = lg.find(x => rec ? x.target === n : x.source === n);
                return l ? (rec ? l.source : l.target) : null;
            }
            property bool open: false
            property bool picking: false
            readonly property color tint: rec ? Theme.accent3 : Theme.accent2

            Layout.fillWidth: true
            implicitHeight: body.implicitHeight + (root.roomy ? 24 : 18)
            radius: Theme.rLg
            color: Theme.alpha(Theme.text, 0.045)
            border.width: 1
            border.color: Theme.alpha(Theme.text, 0.06)

            PwNodeLinkTracker {
                id: links
                node: card.g.nodes[0] ?? null
            }

            ColumnLayout {
                id: body
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 12
                anchors.rightMargin: 8
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Item {
                        implicitWidth: root.roomy ? 36 : 30
                        implicitHeight: implicitWidth
                        AppIcon {
                            anchors.fill: parent
                            implicitSize: parent.width
                            name: card.g.icon
                            fallback: card.rec ? "audio-input-microphone" : "audio-x-generic"
                            opacity: card.muted ? 0.45 : 1
                        }
                        // recording: a red dot on the icon
                        Rectangle {
                            visible: card.rec
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            width: 10
                            height: 10
                            radius: 5
                            color: Theme.error
                            border.width: 2
                            border.color: Theme.surface
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        FText {
                            Layout.fillWidth: true
                            text: card.g.name
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }
                        FText {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: card.many > 1 ? card.many + (card.rec ? " recordings" : " streams") + (card.device ? " · " + Audio.nodeName(card.device) : "")
                                : [Audio.streamTitle(card.g.nodes[0]), card.device && card.devices.length > 1 ? Audio.nodeName(card.device) : ""].filter(x => x).join(" · ")
                            dim: true
                            font.pixelSize: Theme.fsXs
                            elide: Text.ElideRight
                        }
                    }
                    FText {
                        text: card.muted ? I18n.tr("Muted") : Math.round(card.vol * 100) + "%"
                        mono: true
                        font.pixelSize: Theme.fsSm
                        color: card.muted ? Theme.textDim : card.vol > 1 ? Theme.warning : Theme.text
                    }
                    // which output (or input)
                    FIconButton {
                        visible: card.devices.length > 1
                        icon: card.rec ? "mic" : "speaker_group"
                        size: 30
                        iconSize: 17
                        iconColor: card.picking ? Theme.accent : Theme.text
                        onClicked: card.picking = !card.picking
                    }
                    FIconButton {
                        icon: card.muted ? (card.rec ? "mic_off" : "volume_off") : (card.rec ? "mic" : "volume_up")
                        size: 30
                        iconSize: 17
                        iconColor: card.muted ? Theme.error : Theme.text
                        onClicked: Audio.toggleGroupMute(card.g)
                    }
                    FIconButton {
                        visible: card.many > 1 && (Settings.data.sound.mixerStreams ?? true)
                        icon: card.open ? "expand_less" : "expand_more"
                        size: 30
                        iconSize: 18
                        onClicked: card.open = !card.open
                    }
                }

                FSlider {
                    Layout.fillWidth: true
                    Layout.rightMargin: 4
                    implicitHeight: root.roomy ? 30 : 26
                    to: Audio.maxAppVolume
                    value: card.muted ? 0 : card.vol
                    accent: card.vol > 1 ? Theme.warning : card.tint
                    onMoved: v => Audio.setGroupVolume(card.g, v)
                }

                // the outputs (inputs) to move it to
                Flow {
                    Layout.fillWidth: true
                    Layout.topMargin: 2
                    visible: card.picking
                    spacing: 6
                    Repeater {
                        model: card.picking ? card.devices : []
                        Rectangle {
                            id: chip
                            required property var modelData
                            readonly property bool on: modelData === card.device
                            width: chipRow.implicitWidth + 20
                            height: 30
                            radius: 15
                            color: on ? Theme.alpha(Theme.accent, 0.2) : Theme.alpha(Theme.text, 0.06)
                            border.width: on ? 1 : 0
                            border.color: Theme.accent
                            Row {
                                id: chipRow
                                anchors.centerIn: parent
                                spacing: 5
                                FIcon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    icon: card.rec ? "mic" : chip.modelData.name.includes("bluez") ? "headphones" : chip.modelData.name.includes("hdmi") ? "tv" : chip.modelData.name.includes("usb") ? "usb" : "speaker"
                                    size: 15
                                    fill: chip.on ? 1 : 0
                                    color: chip.on ? Theme.accent : Theme.text
                                }
                                FText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: Audio.nodeName(chip.modelData)
                                    font.pixelSize: Theme.fsXs
                                    font.weight: chip.on ? Font.Bold : Font.Normal
                                    width: Math.min(implicitWidth, 200)
                                    elide: Text.ElideRight
                                }
                            }
                            StateLayer {
                                onClicked: {
                                    Audio.moveGroup(card.g, chip.modelData);
                                    card.picking = false;
                                }
                            }
                        }
                    }
                }

                // each stream on its own
                Repeater {
                    model: card.open ? card.g.nodes : []
                    RowLayout {
                        id: sub
                        required property var modelData
                        readonly property bool m: modelData.audio?.muted ?? false
                        Layout.fillWidth: true
                        Layout.leftMargin: 40
                        spacing: 6
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            FText {
                                Layout.fillWidth: true
                                text: Audio.streamTitle(sub.modelData) || Audio.nodeName(sub.modelData)
                                font.pixelSize: Theme.fsXs
                                elide: Text.ElideRight
                            }
                            FSlider {
                                Layout.fillWidth: true
                                implicitHeight: 22
                                to: Audio.maxAppVolume
                                value: sub.m ? 0 : Audio.streamVolume(sub.modelData)
                                accent: card.tint
                                onMoved: v => Audio.setStreamVolume(sub.modelData, v)
                            }
                        }
                        FIconButton {
                            icon: sub.m ? "volume_off" : "volume_up"
                            size: 26
                            iconSize: 15
                            iconColor: sub.m ? Theme.error : Theme.text
                            onClicked: Audio.toggleStreamMute(sub.modelData)
                        }
                    }
                }
            }
        }
    }
}
