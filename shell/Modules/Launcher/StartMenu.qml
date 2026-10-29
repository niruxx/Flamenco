import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

// A small, app-only Start menu. The full launcher and its backend stay independent.
Variants {
    model: Quickshell.screens

    OverlayPanel {
        id: panel
        name: "startmenu"
        placement: "bar"
        hAlign: "left"
        exclusiveKeyboard: true
        cardWidth: Math.round(560 * Theme.scale)
        cardPadding: Theme.sp2
        avoidBar: true

        property string category: "all"
        readonly property var categories: [
            { id: "all", label: I18n.tr("All programs"), cats: [] },
            { id: "internet", label: I18n.tr("Internet"), cats: ["Network"] },
            { id: "office", label: I18n.tr("Office"), cats: ["Office"] },
            { id: "media", label: I18n.tr("Media"), cats: ["AudioVideo", "Audio", "Video"] },
            { id: "graphics", label: I18n.tr("Graphics"), cats: ["Graphics"] },
            { id: "games", label: I18n.tr("Games"), cats: ["Game"] },
            { id: "dev", label: I18n.tr("Development"), cats: ["Development"] },
            { id: "system", label: I18n.tr("System"), cats: ["System", "Settings"] },
            { id: "utility", label: I18n.tr("Utilities"), cats: ["Utility", "Accessories"] },
            { id: "learn", label: I18n.tr("Learning"), cats: ["Education", "Science"] }
        ]
        readonly property var entries: {
            const selected = categories.find(c => c.id === category);
            const query = search.text.trim();
            // Searching spans all programs; browsing is alphabetical, like a Programs menu.
            const apps = query ? Apps.search(query) : Apps.all;
            return query || category === "all" ? apps
                : apps.filter(e => selected.cats.some(c => (e.categories || []).includes(c)));
        }
        function launch(entry) {
            if (!entry)
                return;
            Panels.close();
            Apps.launch(entry);
        }
        onEntriesChanged: applications.currentIndex = entries.length ? 0 : -1
        onOpened: {
            category = "all";
            search.text = "";
            applications.currentIndex = entries.length ? 0 : -1;
            applications.positionViewAtBeginning();
            search.focusInput();
        }

        ColumnLayout {
            width: parent.width
            Keys.onEscapePressed: Panels.close()
            spacing: Theme.sp2

            FText {
                Layout.fillWidth: true
                Layout.margins: Theme.sp2
                text: I18n.tr("Applications")
                font.weight: Font.DemiBold
                font.pixelSize: Theme.fsLg
            }
            FTextField {
                id: search
                Layout.fillWidth: true
                placeholder: I18n.tr("Find an application")
                icon: "search"
                onAccepted: panel.launch(panel.entries[applications.currentIndex])
                onKeyPressed: event => {
                    if (event.key === Qt.Key_Down || event.key === Qt.Key_Up) {
                        const step = event.key === Qt.Key_Down ? 1 : -1;
                        applications.currentIndex = Math.max(0, Math.min(panel.entries.length - 1, applications.currentIndex + step));
                        applications.positionViewAtIndex(applications.currentIndex, ListView.Contain);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Escape) {
                        Panels.close();
                        event.accepted = true;
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                // Leave space for the heading, search and footer even on short screens.
                Layout.preferredHeight: Math.max(80, Math.min(420 * Theme.scale, panel.height - 240 * Theme.scale - Theme.barHeight - Theme.barMargin))
                spacing: Theme.sp2

                FScroll {
                    id: categoryScroll
                    Layout.preferredWidth: Math.min(150 * Theme.scale, panel.card.width * 0.35)
                    Layout.fillHeight: true
                    contentHeight: categoryColumn.implicitHeight
                    Column {
                        id: categoryColumn
                        width: categoryScroll.width - categoryScroll.gutter
                        spacing: 2
                        Repeater {
                            model: panel.categories
                            FButton {
                                required property var modelData
                                width: categoryColumn.width
                                text: modelData.label
                                variant: panel.category === modelData.id && !search.text.trim() ? "tonal" : "text"
                                onClicked: {
                                    panel.category = modelData.id;
                                    search.text = "";
                                    applications.positionViewAtBeginning();
                                }
                                onActiveFocusChanged: if (activeFocus) {
                                    categoryScroll.contentY = Math.max(0, Math.min(categoryScroll.maxY, y + height - categoryScroll.height));
                                }
                            }
                        }
                    }
                }
                Rectangle { Layout.fillHeight: true; implicitWidth: 1; color: Theme.border }
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    ListView {
                        id: applications
                        anchors.fill: parent
                        clip: true
                        model: panel.entries
                        spacing: 2
                        boundsBehavior: Flickable.StopAtBounds
                        keyNavigationEnabled: true
                        activeFocusOnTab: true
                        highlightMoveDuration: 0
                        Keys.onReturnPressed: panel.launch(panel.entries[currentIndex])
                        Keys.onEnterPressed: panel.launch(panel.entries[currentIndex])
                        Keys.onEscapePressed: Panels.close()
                        Keys.onPressed: event => {
                            if (event.text && event.text >= " " && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
                                search.text += event.text;
                                search.focusInput();
                                event.accepted = true;
                            }
                        }
                        delegate: Rectangle {
                            id: appRow
                            required property var modelData
                            required property int index
                            width: applications.width
                            height: Math.round(38 * Theme.scale)
                            radius: Theme.rSm
                            color: applications.currentIndex === index ? Theme.accentContainer : "transparent"
                            Accessible.role: Accessible.Button
                            Accessible.name: modelData.name
                            Accessible.onPressAction: panel.launch(modelData)
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: Theme.sp2
                                spacing: Theme.sp2
                                AppIcon { name: appRow.modelData.icon || ""; implicitSize: Math.round(24 * Theme.scale) }
                                FText {
                                    Layout.fillWidth: true
                                    text: appRow.modelData.name
                                    elide: Text.ElideRight
                                    color: applications.currentIndex === appRow.index ? Theme.onAccentContainer : Theme.text
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: applications.currentIndex = appRow.index
                                onClicked: panel.launch(appRow.modelData)
                            }
                        }
                    }
                    FText {
                        anchors.fill: parent
                        visible: panel.entries.length === 0
                        text: I18n.tr("No applications found")
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        dim: true
                    }
                }
            }
            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.border }
            RowLayout {
                Layout.fillWidth: true
                FButton { Layout.fillWidth: true; text: I18n.tr("Settings"); icon: "settings"; variant: "text"; onClicked: Panels.openSettings("appearance") }
                FButton { Layout.fillWidth: true; text: I18n.tr("Power"); icon: "power_settings_new"; variant: "text"; onClicked: Panels.open("power", panel.modelData.name) }
            }
        }
    }
}
