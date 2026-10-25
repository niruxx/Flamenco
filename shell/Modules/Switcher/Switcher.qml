import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Commons
import qs.Services
import qs.Widgets

// The app switcher (Switcher service): the open windows, most recent first, on
// a raised sheet. Keep Alt held and press Tab to move along (Shift+Tab back); let
// go of Alt to switch. Arrows, Enter, a click and Esc work too.
//
// Layouts (Settings → Overview → App switcher): cards (Material 3 cards in a row),
// grid (bigger cards in rows), list (one window per line), icons (big app icons,
// the picked one's title under them) and compact (a slim pill of icons, the picked
// one opening up with its title). Styles: tonal, filled and outlined (Material 3).
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win

        required property ShellScreen modelData
        readonly property bool shown: Switcher.open && Panels.screen === modelData.name
        readonly property real p: pAnim.v
        readonly property int n: Switcher.list.length
        readonly property var cfg: Settings.data.switcher
        readonly property string layout: ["cards", "grid", "list", "icons", "compact", "fullmaterial", "fullcards", "android"].includes(cfg.layout) ? cfg.layout : "cards"
        // the full-screen ones: the sheet becomes the whole screen
        readonly property bool full: ["fullmaterial", "fullcards", "android"].includes(layout)
        readonly property string look: ["tonal", "filled", "outlined"].includes(cfg.look) ? cfg.look : "tonal"
        readonly property int cardW: Math.max(168, Math.min(212, (width - 200) / Math.max(1, n) - 14))
        readonly property int cardH: Math.round(cardW * 1.22)
        readonly property var tints: [Theme.accent, Theme.accent2, Theme.accent3]
        // window pictures (cards and grid); never in a nested niri, whose old dmabuf
        // version makes capturing drop the whole shell
        readonly property bool previews: (cfg.previews ?? false) && !Quickshell.screens.some(s => s.name === "winit")
        readonly property var picked: Switcher.list[Switcher.index] ?? null

        // ── the style: Material 3 tonal, filled or outlined ──
        function itemBg(sel) {
            return look === "filled" ? (sel ? Theme.accent : Theme.surfaceHigh)
                : look === "outlined" ? (sel ? Theme.alpha(Theme.accent, 0.1) : "transparent")
                : (sel ? Theme.alpha(Theme.accent, 0.2) : Theme.surfaceHigh);
        }
        function itemFg(sel) {
            return look === "filled" && sel ? Theme.onAccent : Theme.text;
        }
        function itemDim(sel) {
            return look === "filled" && sel ? Theme.alpha(Theme.onAccent, 0.8) : sel ? Theme.accent : Theme.textDim;
        }
        function itemBorderW(sel) {
            return look === "outlined" ? (sel ? 2 : 1) : look === "filled" ? 0 : (sel ? 2 : 1);
        }
        function itemBorder(sel) {
            return look === "outlined" ? (sel ? Theme.accent : Theme.alpha(Theme.text, 0.22)) : sel ? Theme.accent : Theme.alpha(Theme.text, 0.06);
        }
        function appName(w) {
            return Apps.lookup(w?.app_id)?.name ?? w?.app_id ?? "";
        }
        function wsOf(w) {
            return Niri.workspaces.find(x => x.id === w?.workspace_id) ?? null;
        }
        function pick(i) {
            Switcher.index = i;
            Switcher.activate();
        }

        screen: modelData
        visible: shown || p > 0.01
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "flamenco-switcher"
        WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        onShownChanged: if (shown) keys.forceActiveFocus()

        // animated value lives on an Item: Behaviors on the window itself crash Qt 6.12
        Item {
            id: pAnim
            property real v: win.shown ? 1 : 0
            Behavior on v { Anim { duration: Theme.durA("panels", 260); easing.bezierCurve: Theme.curves.emphasizedDecel } }
        }

        // the scrim
        Rectangle {
            anchors.fill: parent
            color: Theme.alpha(Theme.shadow, 0.32)
            opacity: win.p
            MouseArea {
                anchors.fill: parent
                onClicked: Switcher.cancel()
            }
        }

        Item {
            id: keys
            focus: true
            Keys.onPressed: event => {
                const k = event.key;
                // the grid moves a whole row with ↑ ↓
                const rowStep = win.layout === "grid" ? Math.max(1, body.item?.cols ?? 1) : 1;
                if (k === Qt.Key_Escape)
                    Switcher.cancel();
                else if (k === Qt.Key_Backtab || (k === Qt.Key_Tab && event.modifiers & Qt.ShiftModifier) || k === Qt.Key_Left)
                    Switcher.step(-1);
                else if (k === Qt.Key_Tab || k === Qt.Key_Right)
                    Switcher.step(1);
                else if (k === Qt.Key_Up)
                    Switcher.step(-rowStep);
                else if (k === Qt.Key_Down)
                    Switcher.step(rowStep);
                else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space)
                    Switcher.activate();
                else if (k === Qt.Key_Delete && win.picked)
                    Niri.closeWindow(win.picked.id);
                else
                    return;
                event.accepted = true;
            }
            // letting go of the switcher's modifier switches
            Keys.onReleased: event => {
                if (event.key === Qt.Key_Alt || event.key === Qt.Key_Meta || event.key === Qt.Key_Super_L || event.key === Qt.Key_Super_R) {
                    Switcher.activate();
                    event.accepted = true;
                }
            }
        }

        // the sheet's shadow
        RectangularShadow {
            visible: !win.full
            anchors.fill: sheet
            radius: sheet.radius
            blur: 36
            spread: 2
            offset: Qt.vector2d(0, 10)
            color: Theme.alpha(Theme.shadow, 0.35)
            opacity: win.p
            scale: sheet.scale
        }

        // ── the sheet ──
        Rectangle {
            id: sheet
            readonly property bool slim: win.layout === "compact"
            anchors.centerIn: parent
            width: win.full ? parent.width : Math.min(parent.width - 80, Math.max(body.implicitWidth, slim ? 0 : header.implicitWidth) + (slim ? 20 : 48))
            height: win.full ? parent.height : (slim ? 0 : header.height + 24) + body.implicitHeight + (slim ? 20 : 48)
            radius: win.full ? 0 : slim ? height / 2 : 32
            // full screen: Material's surface (or Android's dim backdrop) over everything
            color: win.layout === "android" ? Theme.alpha(Theme.shadow, 0.55) : win.full ? Theme.alpha(Theme.bg, Math.max(0.85, Theme.switcherOp)) : Theme.switcherBg
            border.width: win.full ? 0 : 1
            border.color: Theme.alpha(Theme.border, 0.6)
            opacity: win.p
            scale: win.full ? 1.03 - 0.03 * win.p : 0.92 + 0.08 * win.p

            // the surface finish (gloss / chrome), under the content
            Finish {}

            // header: what this is, how many, and the keys as chips
            RowLayout {
                id: header
                visible: !sheet.slim && win.layout !== "android"
                readonly property int m: win.full ? 56 : 24
                x: m
                y: win.full ? 44 : 20
                width: sheet.width - m * 2
                spacing: 10

                Rectangle {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    radius: 14
                    color: Theme.alpha(Theme.accent, 0.18)
                    FIcon { anchors.centerIn: parent; icon: "select_window"; size: 22; fill: 1; color: Theme.accent }
                }
                ColumnLayout {
                    spacing: 0
                    FText { text: "Switch window"; font.pixelSize: Theme.fsLg; font.weight: Font.Bold }
                    FText { text: win.n + (win.n === 1 ? " window open" : " windows open"); dim: true; font.pixelSize: Theme.fsXs }
                }
                Item { Layout.fillWidth: true }
                Repeater {
                    model: [{ k: "Tab", t: "next" }, { k: "⇧ Tab", t: "back" }, { k: "Alt", t: "release to switch" }]
                    Rectangle {
                        required property var modelData
                        implicitWidth: chip.implicitWidth + 20
                        implicitHeight: 30
                        radius: 9
                        color: "transparent"
                        border.width: 1
                        border.color: Theme.alpha(Theme.text, 0.18)
                        Row {
                            id: chip
                            anchors.centerIn: parent
                            spacing: 6
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: kt.implicitWidth + 10
                                height: 20
                                radius: 6
                                color: Theme.alpha(Theme.text, 0.1)
                                FText { id: kt; anchors.centerIn: parent; text: modelData.k; mono: true; font.pixelSize: Theme.fsXs; font.weight: Font.Bold }
                            }
                            FText { anchors.verticalCenter: parent.verticalCenter; text: modelData.t; dim: true; font.pixelSize: Theme.fsXs }
                        }
                    }
                }
            }

            Loader {
                id: body
                // full screen: the room under the header; otherwise its own size, at the sheet's bottom
                readonly property real topY: win.full ? (header.visible ? header.y + header.height + 32 : 40) : 0
                width: win.full ? sheet.width - (win.layout === "android" ? 0 : 112) : implicitWidth
                height: win.full ? sheet.height - topY - 48 : implicitHeight
                x: (sheet.width - width) / 2
                y: win.full ? topY : sheet.height - height - (sheet.slim ? 10 : 24)
                sourceComponent: ({ cards: cardsC, grid: gridC, list: listC, icons: iconsC, compact: compactC,
                        fullmaterial: fullMaterialC, fullcards: fullCardsC, android: androidC })[win.layout]
            }
        }

        // ───────────────────────────── the window, as a card (cards and grid) ─────────────────────────────
        // (inline components can't see this file's ids: the switcher window comes in as `sw`)
        component WinCard: Rectangle {
            id: card
            required property var sw
            required property var w
            required property int i
            property real cw: sw.cardW
            property real ch: sw.cardH
            readonly property bool sel: i === Switcher.index
            readonly property var ws: sw.wsOf(w)
            readonly property color tint: sw.tints[i % sw.tints.length]
            width: cw
            height: ch
            radius: 24
            color: sw.itemBg(sel)
            border.width: sw.itemBorderW(sel)
            border.color: sw.itemBorder(sel)
            Behavior on color { CAnim {} }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                // hero: the app on a soft wash of its tint (or the window's picture)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 18
                    gradient: Gradient {
                        GradientStop { position: 0; color: Theme.alpha(sw.look === "filled" && card.sel ? Theme.onAccent : card.tint, card.sel ? 0.42 : 0.22) }
                        GradientStop { position: 1; color: Theme.alpha(card.tint, 0.06) }
                    }
                    Loader {
                        id: shot
                        anchors.fill: parent
                        anchors.margins: 4
                        readonly property var toplevel: sw.previews && sw.shown ? (ToplevelManager.toplevels.values.find(t => t.appId === card.w.app_id && t.title === card.w.title) ?? null) : null
                        active: toplevel !== null
                        sourceComponent: ClippingRectangle {
                            readonly property bool got: pic.hasContent
                            radius: 14
                            color: "transparent"
                            ScreencopyView {
                                id: pic
                                anchors.centerIn: parent
                                readonly property real aspect: hasContent && sourceSize.height > 0 ? sourceSize.width / sourceSize.height : 16 / 10
                                width: Math.min(parent.width, parent.height * aspect)
                                height: width / aspect
                                captureSource: shot.toplevel
                                live: false
                            }
                        }
                    }
                    readonly property bool hasShot: shot.item?.got ?? false
                    AppIcon {
                        anchors.centerIn: parent.hasShot ? undefined : parent
                        anchors.left: parent.hasShot ? parent.left : undefined
                        anchors.bottom: parent.hasShot ? parent.bottom : undefined
                        anchors.margins: 8
                        implicitSize: parent.hasShot ? 30 : Math.round(Math.min(card.cw, card.ch) * (card.sel ? 0.4 : 0.34))
                        name: Apps.iconFor(card.w.app_id)
                        Behavior on implicitSize { Anim { duration: Theme.durShort } }
                    }
                    // the workspace, as an assist chip
                    Rectangle {
                        visible: !!card.ws
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.margins: 8
                        width: wsRow.implicitWidth + 14
                        height: 24
                        radius: 8
                        color: Theme.alpha(Theme.surface, 0.85)
                        Row {
                            id: wsRow
                            anchors.centerIn: parent
                            spacing: 3
                            FIcon { anchors.verticalCenter: parent.verticalCenter; icon: "view_carousel"; size: 13; color: card.tint }
                            FText { anchors.verticalCenter: parent.verticalCenter; text: card.ws ? (card.ws.name || card.ws.idx) : ""; font.pixelSize: Theme.fsXs; font.weight: Font.Bold }
                        }
                    }
                    FIcon {
                        visible: !!card.w.is_floating
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 10
                        icon: "picture_in_picture"
                        size: 16
                        color: card.tint
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 6
                    Layout.rightMargin: 6
                    Layout.bottomMargin: 4
                    spacing: 1
                    FText { Layout.fillWidth: true; text: card.w.title || sw.appName(card.w); font.pixelSize: Theme.fsSm; font.weight: Font.Bold; elide: Text.ElideRight; color: sw.itemFg(card.sel) }
                    FText { Layout.fillWidth: true; text: sw.appName(card.w); font.pixelSize: Theme.fsXs; font.weight: Font.DemiBold; elide: Text.ElideRight; color: sw.itemDim(card.sel) }
                }
            }
            HoverHandler { id: chover; cursorShape: Qt.PointingHandCursor }
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: Theme.text
                opacity: chover.hovered && !card.sel ? 0.06 : 0
            }
            TapHandler { onTapped: sw.pick(card.i) }
        }

        // ── cards: a row of Material 3 cards (the picked one lifted) ──
        Component {
            id: cardsC
            ListView {
                id: row
                orientation: ListView.Horizontal
                spacing: 14
                implicitWidth: Math.min(contentWidth, win.width - 128)
                implicitHeight: win.cardH + 16
                width: implicitWidth
                height: implicitHeight
                interactive: contentWidth > width
                model: Switcher.list
                currentIndex: Switcher.index
                highlightMoveDuration: Theme.durShort
                preferredHighlightBegin: width / 2 - win.cardW / 2
                preferredHighlightEnd: width / 2 + win.cardW / 2
                highlightRangeMode: contentWidth > width ? ListView.ApplyRange : ListView.NoHighlightRange
                clip: true
                delegate: Item {
                    required property var modelData
                    required property int index
                    width: win.cardW
                    height: win.cardH + 16
                    WinCard {
                        sw: win
                        w: parent.modelData
                        i: parent.index
                        y: sel ? 0 : 8
                        Behavior on y { Anim { duration: Theme.durShort; easing.bezierCurve: Theme.curves.springFast } }
                    }
                }
            }
        }

        // ── grid: bigger cards in rows ──
        Component {
            id: gridC
            GridView {
                id: grid
                readonly property int cols: Math.max(1, Math.min(4, win.n, Math.floor((win.width - 160) / 260)))
                readonly property int rows: Math.ceil(win.n / cols)
                cellWidth: 260
                cellHeight: 210
                implicitWidth: cols * cellWidth
                implicitHeight: Math.min(rows, 3) * cellHeight
                width: implicitWidth
                height: implicitHeight
                interactive: rows > 3
                model: Switcher.list
                currentIndex: Switcher.index
                highlightMoveDuration: Theme.durShort
                clip: true
                delegate: Item {
                    required property var modelData
                    required property int index
                    width: grid.cellWidth
                    height: grid.cellHeight
                    WinCard {
                        sw: win
                        anchors.centerIn: parent
                        w: parent.modelData
                        i: parent.index
                        cw: grid.cellWidth - 16
                        ch: grid.cellHeight - 16
                        scale: sel ? 1 : 0.96
                        Behavior on scale { Anim { duration: Theme.durShort; easing.bezierCurve: Theme.curves.springFast } }
                    }
                }
            }
        }

        // ── list: one window per line ──
        Component {
            id: listC
            ListView {
                id: list
                spacing: 4
                implicitWidth: Math.min(560, win.width - 120)
                implicitHeight: Math.min(contentHeight, 8 * 60 + 7 * 4)
                width: implicitWidth
                height: implicitHeight
                interactive: contentHeight > height
                model: Switcher.list
                currentIndex: Switcher.index
                highlightMoveDuration: Theme.durShort
                clip: true
                delegate: Rectangle {
                    id: lrow
                    required property var modelData
                    required property int index
                    readonly property bool sel: index === Switcher.index
                    readonly property var ws: win.wsOf(modelData)
                    width: list.width
                    height: 56
                    radius: index === 0 ? 18 : index === win.n - 1 ? 18 : 8
                    color: win.itemBg(sel)
                    border.width: win.itemBorderW(sel)
                    border.color: win.itemBorder(sel)
                    Behavior on color { CAnim {} }
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12
                        AppIcon { implicitSize: 32; name: Apps.iconFor(lrow.modelData.app_id) }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            FText { Layout.fillWidth: true; text: lrow.modelData.title || win.appName(lrow.modelData); font.weight: Font.DemiBold; elide: Text.ElideRight; color: win.itemFg(lrow.sel) }
                            FText { Layout.fillWidth: true; text: win.appName(lrow.modelData); font.pixelSize: Theme.fsXs; elide: Text.ElideRight; color: win.itemDim(lrow.sel) }
                        }
                        Rectangle {
                            visible: !!lrow.ws
                            implicitWidth: lws.implicitWidth + 16
                            implicitHeight: 24
                            radius: 12
                            color: win.look === "filled" && lrow.sel ? Theme.alpha(Theme.onAccent, 0.2) : Theme.alpha(Theme.text, 0.08)
                            FText { id: lws; anchors.centerIn: parent; text: lrow.ws ? (lrow.ws.name || "Workspace " + lrow.ws.idx) : ""; font.pixelSize: Theme.fsXs; color: win.itemFg(lrow.sel) }
                        }
                    }
                    TapHandler { onTapped: win.pick(lrow.index) }
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                }
            }
        }

        // ── icons: big app icons in a row, the picked one's title under them ──
        Component {
            id: iconsC
            ColumnLayout {
                spacing: 14
                ListView {
                    id: strip
                    Layout.alignment: Qt.AlignHCenter
                    orientation: ListView.Horizontal
                    spacing: 10
                    implicitWidth: Math.min(contentWidth, win.width - 160)
                    implicitHeight: 104
                    Layout.preferredWidth: implicitWidth
                    Layout.preferredHeight: implicitHeight
                    interactive: contentWidth > width
                    model: Switcher.list
                    currentIndex: Switcher.index
                    highlightMoveDuration: Theme.durShort
                    highlightRangeMode: contentWidth > width ? ListView.ApplyRange : ListView.NoHighlightRange
                    preferredHighlightBegin: width / 2 - 52
                    preferredHighlightEnd: width / 2 + 52
                    clip: true
                    delegate: Rectangle {
                        id: tile
                        required property var modelData
                        required property int index
                        readonly property bool sel: index === Switcher.index
                        width: 104
                        height: 104
                        radius: 28
                        color: win.itemBg(sel)
                        border.width: win.itemBorderW(sel)
                        border.color: win.itemBorder(sel)
                        Behavior on color { CAnim {} }
                        AppIcon {
                            anchors.centerIn: parent
                            implicitSize: tile.sel ? 64 : 54
                            name: Apps.iconFor(tile.modelData.app_id)
                            Behavior on implicitSize { Anim { duration: Theme.durShort; easing.bezierCurve: Theme.curves.springFast } }
                        }
                        // more than one window of the app: a count
                        Rectangle {
                            readonly property int same: Switcher.list.filter(x => x.app_id === tile.modelData.app_id).length
                            visible: same > 1
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 8
                            width: 20
                            height: 20
                            radius: 10
                            color: Theme.accent3
                            FText { anchors.centerIn: parent; text: parent.same; font.pixelSize: Theme.fsXs; font.weight: Font.Bold; color: Theme.onAccent }
                        }
                        TapHandler { onTapped: win.pick(tile.index) }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                    }
                }
                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.maximumWidth: Math.min(600, win.width - 200)
                    spacing: 0
                    FText { Layout.alignment: Qt.AlignHCenter; Layout.maximumWidth: parent.Layout.maximumWidth; text: win.picked ? (win.picked.title || win.appName(win.picked)) : ""; font.pixelSize: Theme.fsLg; font.weight: Font.Bold; elide: Text.ElideRight }
                    FText { Layout.alignment: Qt.AlignHCenter; text: win.picked ? win.appName(win.picked) : ""; dim: true; font.pixelSize: Theme.fsSm }
                }
            }
        }

        // ── full-screen Material: the windows as big cards in a grid filling the screen ──
        Component {
            id: fullMaterialC
            GridView {
                id: fgrid
                readonly property int cols: Math.max(1, Math.min(win.n, Math.max(2, Math.floor(width / 380))))
                readonly property int rows: Math.max(1, Math.ceil(win.n / cols))
                cellWidth: width / cols
                // as tall as fits, up to a 16:11 card
                cellHeight: Math.min(cellWidth * 0.69, height / Math.min(rows, 3))
                model: Switcher.list
                currentIndex: Switcher.index
                highlightMoveDuration: Theme.durMed
                interactive: rows > 3
                clip: true
                delegate: Item {
                    required property var modelData
                    required property int index
                    width: fgrid.cellWidth
                    height: fgrid.cellHeight
                    WinCard {
                        sw: win
                        anchors.centerIn: parent
                        w: parent.modelData
                        i: parent.index
                        cw: fgrid.cellWidth - 28
                        ch: fgrid.cellHeight - 28
                        radius: 28
                        scale: sel ? 1 : 0.95
                        // they arrive one after another
                        opacity: win.p
                        Behavior on scale { Anim { duration: Theme.durMed; easing.bezierCurve: Theme.curves.springFast } }
                    }
                }
            }
        }

        // ── full-screen cards: big cards in a row, the picked one forward, the rest set back ──
        Component {
            id: fullCardsC
            ListView {
                id: fcards
                readonly property real ch: Math.min(height - 40, width * 0.42)
                readonly property real cw: ch * 1.3
                orientation: ListView.Horizontal
                spacing: -cw * 0.12
                model: Switcher.list
                currentIndex: Switcher.index
                highlightRangeMode: ListView.StrictlyEnforceRange
                preferredHighlightBegin: width / 2 - cw / 2
                preferredHighlightEnd: width / 2 + cw / 2
                highlightMoveDuration: Theme.durMed
                interactive: true
                clip: false
                delegate: Item {
                    id: fslot
                    required property var modelData
                    required property int index
                    readonly property int dist: Math.abs(index - Switcher.index)
                    width: fcards.cw
                    height: fcards.height
                    z: 100 - dist
                    WinCard {
                        sw: win
                        anchors.centerIn: parent
                        w: fslot.modelData
                        i: fslot.index
                        cw: fcards.cw
                        ch: fcards.ch
                        radius: 32
                        // depth: the further from the picked one, the smaller and dimmer
                        scale: Math.max(0.7, 1 - fslot.dist * 0.1)
                        opacity: Math.max(0.35, 1 - fslot.dist * 0.22)
                        Behavior on scale { Anim { duration: Theme.durMed; easing.bezierCurve: Theme.curves.emphasizedDecel } }
                        Behavior on opacity { Anim { duration: Theme.durMed } }
                    }
                }
            }
        }

        // ── Android: Recents. Tall cards side by side, the app above each; the picked one in the
        //    middle at full size, the others peeking in smaller. Swipe a card up to close it. ──
        Component {
            id: androidC
            ColumnLayout {
                spacing: 12
                ListView {
                    id: recents
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    readonly property real ch: height - 52
                    readonly property real cw: Math.min(width * 0.5, ch * 1.45)
                    orientation: ListView.Horizontal
                    spacing: 28
                    model: Switcher.list
                    currentIndex: Switcher.index
                    highlightRangeMode: ListView.StrictlyEnforceRange
                    preferredHighlightBegin: width / 2 - cw / 2
                    preferredHighlightEnd: width / 2 + cw / 2
                    highlightMoveDuration: Theme.durMed
                    clip: false
                    delegate: Item {
                        id: rec
                        required property var modelData
                        required property int index
                        readonly property bool sel: index === Switcher.index
                        readonly property var toplevel: win.previews && win.shown ? (ToplevelManager.toplevels.values.find(t => t.appId === modelData.app_id && t.title === modelData.title) ?? null) : null
                        width: recents.cw
                        height: recents.height
                        scale: sel ? 1 : 0.86
                        opacity: sel ? 1 : 0.75
                        Behavior on scale { Anim { duration: Theme.durMed; easing.bezierCurve: Theme.curves.emphasizedDecel } }
                        Behavior on opacity { Anim { duration: Theme.durMed } }

                        // the app, above its card
                        Row {
                            id: appRow
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 8
                            AppIcon { anchors.verticalCenter: parent.verticalCenter; implicitSize: 30; name: Apps.iconFor(rec.modelData.app_id) }
                            FText { anchors.verticalCenter: parent.verticalCenter; text: win.appName(rec.modelData); color: "#ffffff"; font.weight: Font.DemiBold; font.pixelSize: Theme.fsMd }
                        }
                        // the card: the window's picture, or its app on a soft wash; drag it up to close
                        ClippingRectangle {
                            id: rcard
                            x: 0
                            y: 44 + swipe.translation.y * (swipe.active ? 1 : 0)
                            width: parent.width
                            height: recents.ch
                            radius: 28
                            color: Theme.surfaceHigh
                            border.width: rec.sel ? 2 : 0
                            border.color: Theme.accent
                            opacity: 1 - Math.max(0, -swipe.translation.y) / (recents.ch * 0.8)
                            Behavior on y { enabled: !swipe.active; Anim { duration: Theme.durMed; easing.bezierCurve: Theme.curves.springFast } }
                            Rectangle {
                                anchors.fill: parent
                                gradient: Gradient {
                                    GradientStop { position: 0; color: Theme.alpha(Theme.accent, 0.25) }
                                    GradientStop { position: 1; color: Theme.alpha(Theme.accent3, 0.08) }
                                }
                            }
                            ScreencopyView {
                                anchors.fill: parent
                                captureSource: rec.toplevel
                                live: false
                                visible: rec.toplevel !== null && hasContent
                            }
                            AppIcon {
                                anchors.centerIn: parent
                                visible: rec.toplevel === null
                                implicitSize: Math.round(recents.cw * 0.22)
                                name: Apps.iconFor(rec.modelData.app_id)
                            }
                            FText {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                anchors.margins: 16
                                text: rec.modelData.title || ""
                                elide: Text.ElideRight
                                color: "#ffffff"
                                style: Text.Outline
                                styleColor: Theme.alpha(Theme.shadow, 0.5)
                            }
                            FIconButton {
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 10
                                icon: "close"
                                size: 34
                                flat: false
                                onClicked: Niri.closeWindow(rec.modelData.id)
                            }
                            TapHandler { onTapped: win.pick(rec.index) }
                            DragHandler {
                                id: swipe
                                target: null
                                xAxis.enabled: false
                                // far enough up: the window closes
                                onActiveChanged: if (!active && translation.y < -recents.ch * 0.28) Niri.closeWindow(rec.modelData.id)
                            }
                        }
                    }
                }
                FText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Swipe a window up (or press Delete) to close it  ·  ← → to move  ·  release Alt to switch"
                    color: Qt.rgba(1, 1, 1, 0.7)
                    font.pixelSize: Theme.fsSm
                }
            }
        }

        // ── compact: a slim pill of icons, the picked one opening up with its title ──
        Component {
            id: compactC
            Row {
                spacing: 6
                Repeater {
                    model: Switcher.list
                    Rectangle {
                        id: chipW
                        required property var modelData
                        required property int index
                        readonly property bool sel: index === Switcher.index
                        width: sel ? Math.min(320, 52 + ttl.implicitWidth + 16) : 52
                        height: 52
                        radius: 26
                        color: win.itemBg(sel)
                        border.width: win.look === "outlined" || sel ? win.itemBorderW(sel) : 0
                        border.color: win.itemBorder(sel)
                        clip: true
                        Behavior on width { Anim { duration: Theme.durMed; easing.bezierCurve: Theme.curves.emphasizedDecel } }
                        Behavior on color { CAnim {} }
                        AppIcon {
                            x: 10
                            anchors.verticalCenter: parent.verticalCenter
                            implicitSize: 32
                            name: Apps.iconFor(chipW.modelData.app_id)
                        }
                        FText {
                            id: ttl
                            x: 50
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.min(implicitWidth, 250)
                            opacity: chipW.sel ? 1 : 0
                            text: chipW.modelData.title || win.appName(chipW.modelData)
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                            color: win.itemFg(chipW.sel)
                            Behavior on opacity { Anim { duration: Theme.durShort } }
                        }
                        TapHandler { onTapped: win.pick(chipW.index) }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                    }
                }
            }
        }
    }
}
