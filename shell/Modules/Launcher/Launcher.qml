import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services
import qs.Widgets

// App launcher. Prefixes:  =  calculator   >  run command   ;  clipboard (cliphist)
//                          :  emoji        #  colors (and the screen color picker)
Variants {
    model: Quickshell.screens

    OverlayPanel {
        id: panel
        name: "launcher"
        // Settings → Launcher → Position; "bar" opens next to the bar's start (where the launcher button is)
        placement: Settings.data.launcher.position
        hAlign: "left"
        exclusiveKeyboard: true
        cardWidth: Settings.data.launcher.width

        property string query: ""
        readonly property var lc: Settings.data.launcher
        readonly property string mode: query.startsWith("=") && lc.calculator ? "calc" : query.startsWith(">") ? "run" : query.startsWith(";") && lc.clipboard ? "clip"
            : query.startsWith(":") && lc.emoji ? "emoji" : query.startsWith("#") && lc.colors ? "color" : "apps"
        property var emojis: []                // [[glyph, name], …] from `flamenco emoji`
        readonly property string term: mode === "apps" ? query : query.slice(1).trim()
        property var clips: []

        readonly property var results: {
            if (mode === "calc") {
                const r = calc(term);
                return r === null ? [] : [{ kind: "calc", title: String(r), subtitle: "Enter to copy · " + term, icon: "calculate" }];
            }
            if (mode === "run")
                return term ? [{ kind: "run", title: term, subtitle: "Run in shell", icon: "terminal" }, { kind: "runterm", title: term, subtitle: "Run in " + Settings.data.general.terminal, icon: "terminal" }] : [];
            if (mode === "emoji") {
                const words = term.toLowerCase().split(/\s+/).filter(Boolean);
                const hits = words.length ? emojis.filter(e => words.every(w => e[1].includes(w)))
                    : (lc.recentEmoji || []).map(g => emojis.find(e => e[0] === g)).filter(Boolean).concat(emojis.filter(e => !(lc.recentEmoji || []).includes(e[0])));
                return hits.slice(0, 80).map(e => ({ kind: "emoji", glyph: e[0], title: e[1].charAt(0).toUpperCase() + e[1].slice(1), subtitle: "Enter to copy", icon: "" }));
            }
            if (mode === "color") {
                const out = [{ kind: "pickcolor", title: "Pick a color on screen", subtitle: "Copies its hex code", icon: "colorize" }];
                const c = parseColor(term);
                if (c) {
                    const hex = "#" + [c.r, c.g, c.b].map(v => v.toString(16).padStart(2, "0")).join("");
                    const hsl = toHsl(c);
                    for (const t of [hex, "rgb(" + c.r + ", " + c.g + ", " + c.b + ")", "hsl(" + hsl.h + ", " + hsl.s + "%, " + hsl.l + "%)"])
                        out.push({ kind: "copy", title: t, subtitle: "Enter to copy", icon: "palette", swatch: hex });
                }
                return out;
            }
            if (mode === "clip") {
                const q = term.toLowerCase();
                return clips.filter(c => c.toLowerCase().includes(q)).slice(0, 50).map(c => ({ kind: "clip", line: c, title: c.split("\t").slice(1).join(" ").trim(), subtitle: "Clipboard", icon: "content_paste" }));
            }
            return Apps.search(term).slice(0, 50).map(e => ({ kind: "app", entry: e, title: e.name, subtitle: e.genericName || e.comment || "", icon: e.icon }));
        }

        // "#abc", "abc", "#aabbcc", "aabbcc(ff)"
        function parseColor(t) {
            const h = t.replace(/^#/, "").trim();
            if (!/^([0-9a-f]{3}|[0-9a-f]{6}|[0-9a-f]{8})$/i.test(h))
                return null;
            const full = h.length === 3 ? h.split("").map(x => x + x).join("") : h.slice(0, 6);
            return { r: parseInt(full.slice(0, 2), 16), g: parseInt(full.slice(2, 4), 16), b: parseInt(full.slice(4, 6), 16) };
        }
        function toHsl(c) {
            const r = c.r / 255, g = c.g / 255, b = c.b / 255;
            const mx = Math.max(r, g, b), mn = Math.min(r, g, b), l = (mx + mn) / 2;
            let h = 0, s = 0;
            if (mx !== mn) {
                const d = mx - mn;
                s = l > 0.5 ? d / (2 - mx - mn) : d / (mx + mn);
                h = mx === r ? (g - b) / d + (g < b ? 6 : 0) : mx === g ? (b - r) / d + 2 : (r - g) / d + 4;
                h /= 6;
            }
            return { h: Math.round(h * 360), s: Math.round(s * 100), l: Math.round(l * 100) };
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
                Quickshell.execDetached(Paths.termHold(item.title));
            else if (item.kind === "clip")
                Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | cliphist decode | wl-copy', "sh", item.line]);
            else if (item.kind === "emoji") {
                Quickshell.execDetached(["wl-copy", item.glyph]);
                lc.recentEmoji = [item.glyph].concat((lc.recentEmoji || []).filter(g => g !== item.glyph)).slice(0, 24);
            } else if (item.kind === "copy")
                Quickshell.execDetached(["wl-copy", item.title]);
            else if (item.kind === "pickcolor")
                // after the launcher has closed, so it isn't what gets picked
                Quickshell.execDetached(["sh", "-c", 'sleep 0.35; exec "$1" pick-color', "sh", Paths.bin]);
            Panels.close();
        }

        onModeChanged: {
            if (mode === "clip")
                clipProc.running = true;
            else if (mode === "emoji" && emojis.length === 0 && !emojiProc.running)
                emojiProc.running = true;
        }
        onOpened: {
            // opened for a mode (e.g. ":" from the emoji shortcut)
            query = Panels.launcherQuery;
            field.text = Panels.launcherQuery;
            Panels.launcherQuery = "";
            list.currentIndex = 0;
            field.focusInput();
        }

        Process {
            id: emojiProc
            command: [Paths.bin, "emoji"]
            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        panel.emojis = JSON.parse(text);
                    } catch (e) {}
                }
            }
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
                icon: panel.mode === "calc" ? "calculate" : panel.mode === "run" ? "terminal" : panel.mode === "clip" ? "content_paste" : panel.mode === "emoji" ? "mood" : panel.mode === "color" ? "palette" : "search"
                placeholder: "Search apps   ·   = calc   > run   ; clipboard   : emoji   # color"
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
                boundsBehavior: Flickable.OvershootBounds

                SmoothWheel {
                    view: list
                }
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
                                visible: row.modelData.kind !== "app" && row.modelData.kind !== "emoji" && !row.modelData.swatch
                                icon: row.modelData.icon
                                size: 26
                                color: Theme.accent
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: row.modelData.kind === "emoji"
                                text: row.modelData.glyph ?? ""
                                font.pixelSize: 28
                            }
                            Rectangle {
                                anchors.centerIn: parent
                                visible: !!row.modelData.swatch
                                width: 30
                                height: 30
                                radius: 15
                                color: row.modelData.swatch ?? "transparent"
                                border.width: 1
                                border.color: Theme.border
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
