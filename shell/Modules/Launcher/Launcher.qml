import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services
import qs.Widgets

// App launcher. Prefixes:  =  calculator   >  run command   ;  clipboard (cliphist)
Variants {
    model: Quickshell.screens

    OverlayPanel {
        id: panel
        name: "launcher"
        centered: true
        exclusiveKeyboard: true
        cardWidth: 600

        property string query: ""
        readonly property string mode: query.startsWith("=") && Settings.data.launcher.calculator ? "calc" : query.startsWith(">") ? "run" : query.startsWith(";") && Settings.data.launcher.clipboard ? "clip" : "apps"
        readonly property string term: mode === "apps" ? query : query.slice(1).trim()
        property var clips: []

        readonly property var results: {
            if (mode === "calc") {
                const r = calc(term);
                return r === null ? [] : [{ kind: "calc", title: String(r), subtitle: "Enter to copy · " + term, icon: "calculate" }];
            }
            if (mode === "run")
                return term ? [{ kind: "run", title: term, subtitle: "Run in shell", icon: "terminal" }, { kind: "runterm", title: term, subtitle: "Run in " + Settings.data.general.terminal, icon: "terminal" }] : [];
            if (mode === "clip") {
                const q = term.toLowerCase();
                return clips.filter(c => c.toLowerCase().includes(q)).slice(0, 50).map(c => ({ kind: "clip", line: c, title: c.split("\t").slice(1).join(" ").trim(), subtitle: "Clipboard", icon: "content_paste" }));
            }
            return Apps.search(term).slice(0, 50).map(e => ({ kind: "app", entry: e, title: e.name, subtitle: e.genericName || e.comment || "", icon: e.icon }));
        }

        function calc(expr) {
            if (!expr || !/^[0-9+\-*/().,%^\s]+$/.test(expr))
                return null;
            try {
                const v = Function('"use strict"; return (' + expr.replace(/\^/g, "**").replace(/,/g, ".") + ")")();
                return typeof v === "number" && isFinite(v) ? Math.round(v * 1e10) / 1e10 : null;
            } catch (e) {
                return null;
            }
        }

        function activate(item) {
            if (!item)
                return;
            if (item.kind === "app")
                Apps.launch(item.entry);
            else if (item.kind === "calc")
                Quickshell.execDetached(["wl-copy", item.title]);
            else if (item.kind === "run")
                Quickshell.execDetached(["sh", "-c", item.title]);
            else if (item.kind === "runterm")
                Quickshell.execDetached([Settings.data.general.terminal, "-e", "sh", "-c", item.title]);
            else if (item.kind === "clip")
                Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | cliphist decode | wl-copy', "sh", item.line]);
            Panels.close();
        }

        onModeChanged: if (mode === "clip") clipProc.running = true
        onOpened: {
            query = "";
            field.text = "";
            list.currentIndex = 0;
            field.focusInput();
        }

        Process {
            id: clipProc
            command: ["cliphist", "list"]
            stdout: StdioCollector {
                onStreamFinished: panel.clips = text.split("\n").filter(Boolean)
            }
        }

        ColumnLayout {
            width: parent.width
            spacing: Theme.sp3

            FTextField {
                id: field
                Layout.fillWidth: true
                implicitHeight: 52
                radius: Theme.rLg
                icon: panel.mode === "calc" ? "calculate" : panel.mode === "run" ? "terminal" : panel.mode === "clip" ? "content_paste" : "search"
                placeholder: "Search apps   ·   = calc   > run   ; clipboard"
                fontSize: Theme.fsLg
                onEdited: t => {
                    panel.query = t;
                    list.currentIndex = 0;
                }
                onAccepted: panel.activate(panel.results[list.currentIndex])
                onKeyPressed: event => {
                    if (event.key === Qt.Key_Down || (event.key === Qt.Key_N && event.modifiers & Qt.ControlModifier)) {
                        list.incrementCurrentIndex();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Up || (event.key === Qt.Key_P && event.modifiers & Qt.ControlModifier)) {
                        list.decrementCurrentIndex();
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
                implicitHeight: Math.min(count, Settings.data.launcher.maxResults) * 58
                clip: true
                model: panel.results
                keyNavigationWraps: true
                boundsBehavior: Flickable.StopAtBounds
                highlightMoveDuration: Theme.durMed
                highlightResizeDuration: 0
                highlightFollowsCurrentItem: true
                visible: count > 0

                Behavior on implicitHeight { Anim { easing.bezierCurve: Theme.curves.emphasizedDecel } }

                highlight: Rectangle {
                    radius: Theme.rMd
                    color: Theme.alpha(Theme.accent, 0.16)
                    border.width: 1
                    border.color: Theme.alpha(Theme.accent, 0.4)
                }

                delegate: Item {
                    id: row
                    required property var modelData
                    required property int index
                    width: list.width
                    height: 58

                    // staggered entrance
                    opacity: 0
                    Component.onCompleted: appear.start()
                    NumberAnimation {
                        id: appear
                        target: row
                        property: "opacity"
                        to: 1
                        duration: Theme.durMed
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 14

                        Item {
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 36
                            AppIcon {
                                anchors.centerIn: parent
                                visible: row.modelData.kind === "app"
                                implicitSize: 34
                                name: row.modelData.kind === "app" ? row.modelData.icon : ""
                                scale: list.currentIndex === row.index ? 1.1 : 1
                                Behavior on scale { Anim { easing.bezierCurve: Theme.curves.springFast } }
                            }
                            FIcon {
                                anchors.centerIn: parent
                                visible: row.modelData.kind !== "app"
                                icon: row.modelData.icon
                                size: 26
                                color: Theme.accent
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            FText {
                                Layout.fillWidth: true
                                text: row.modelData.title
                                font.weight: Font.DemiBold
                                font.pixelSize: row.modelData.kind === "calc" ? Theme.fsXl : Theme.fsMd
                                elide: Text.ElideRight
                            }
                            FText {
                                Layout.fillWidth: true
                                visible: text !== ""
                                text: row.modelData.subtitle
                                dim: true
                                font.pixelSize: Theme.fsSm
                                elide: Text.ElideRight
                            }
                        }

                        FIcon {
                            icon: "keyboard_return"
                            size: 18
                            color: Theme.textDim
                            opacity: list.currentIndex === row.index ? 1 : 0
                            Behavior on opacity { Anim {} }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: list.currentIndex = row.index
                        onClicked: panel.activate(row.modelData)
                    }
                }
            }

            FText {
                visible: list.count === 0 && panel.query !== ""
                Layout.alignment: Qt.AlignHCenter
                Layout.margins: Theme.sp4
                text: "No results"
                dim: true
            }
        }
    }
}
