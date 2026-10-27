import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

// Waiting package updates: shows while there are some. Click for the list
// and an "Update now" that runs the upgrade in a terminal.
BarChip {
    id: root

    required property var window             // the bar window, for the popup
    property string screenName
    property int barLevel: 0
    property bool barVisible: Updates.enabled && (Settings.data.updates.showInBar ?? true) && Updates.count > 0
    highlighted: pop.visible

    onClicked: {
        if (pop.visible) {
            pop.visible = false;
            return;
        }
        const p = root.mapToItem(null, 0, 0);
        pop.at = Qt.rect(p.x, p.y, root.width, root.height);
        pop.visible = true;
    }

    BarFlow {
        spacing: 4
        FIcon { icon: "system_update_alt"; size: Theme.barIconSm; color: Theme.accent }
        FText {
            visible: !Theme.barVertical || Updates.count < 100
            text: Updates.count
            font.pixelSize: Theme.fsSm
            font.weight: Font.DemiBold
        }
    }

    PopupWindow {
        id: pop
        property rect at: Qt.rect(0, 0, 1, 1)
        readonly property int gap: 8
        anchor.window: root.window
        anchor.rect.x: Theme.barPos === "right" ? at.x - gap : Theme.barPos === "left" ? at.x + at.width + gap : at.x + at.width / 2
        anchor.rect.y: Theme.barPos === "bottom" ? at.y - gap : Theme.barVertical ? at.y : at.y + at.height + gap
        anchor.rect.width: 1
        anchor.rect.height: 1
        anchor.edges: Theme.barPos === "bottom" ? Edges.Top : Theme.barPos === "left" ? Edges.Right : Theme.barPos === "right" ? Edges.Left : Edges.Bottom
        anchor.gravity: anchor.edges
        grabFocus: true
        color: "transparent"
        visible: false
        implicitWidth: 360
        implicitHeight: Math.min(480, col.implicitHeight + 24)

        Rectangle {
            anchors.fill: parent
            radius: Theme.rLg
            color: Theme.popupBg
            border.width: 1
            border.color: Theme.alpha(Theme.border, 0.7)

            ColumnLayout {
                id: col
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    FText { Layout.fillWidth: true; text: Updates.count + (Updates.count === 1 ? " update" : " updates"); font.weight: Font.Bold }
                    FIconButton { icon: Updates.checking ? "progress_activity" : "refresh"; size: 28; iconSize: 16; onClicked: Updates.check() }
                }
                FScroll {
                    id: sc
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(320, list.implicitHeight)
                    contentHeight: list.implicitHeight
                    Column {
                        id: list
                        width: sc.width - sc.gutter
                        spacing: 2
                        Repeater {
                            model: Updates.repo.map(p => Object.assign({ src: "" }, p)).concat(Updates.aur.map(p => Object.assign({ src: "AUR" }, p)), Updates.flatpak.map(p => Object.assign({ src: "Flatpak" }, p)))
                            RowLayout {
                                required property var modelData
                                width: list.width
                                FText { Layout.fillWidth: true; text: modelData.name; elide: Text.ElideRight; font.pixelSize: Theme.fsSm }
                                FText { visible: modelData.src !== ""; text: modelData.src; color: Theme.accent; font.pixelSize: Theme.fsXs }
                                FText { text: modelData.to; dim: true; mono: true; font.pixelSize: Theme.fsXs }
                            }
                        }
                    }
                }
                FButton {
                    Layout.fillWidth: true
                    text: I18n.tr("Update now")
                    icon: "download"
                    onClicked: {
                        pop.visible = false;
                        Updates.runUpgrade();
                    }
                }
                FText {
                    Layout.fillWidth: true
                    text: I18n.tr("Runs ") + (Updates.upgrade || "sudo pacman -Syu") + " in a terminal"
                    dim: true
                    font.pixelSize: Theme.fsXs
                    wrapMode: Text.Wrap
                }
            }
        }
    }
}
