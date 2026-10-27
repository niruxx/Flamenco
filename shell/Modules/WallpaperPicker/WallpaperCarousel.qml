import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Commons
import qs.Services
import qs.Widgets
import qs.Modules.Background

// The wallpaper switcher as a carousel (Settings → Wallpaper → Switcher): the
// wallpapers in a 3D cover flow over the selected one, blurred, with its colors
// and name below. ← → browse, Enter applies, / searches, ↑ ↓ switch to Wallhaven / KDE Store / Live,
// Esc closes. Click the centre card to apply it, another to bring it to the centre.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win

        required property ShellScreen modelData
        readonly property string screenName: modelData.name
        readonly property bool shown: Panels.current === "wallpaper" && Panels.screen === screenName && Settings.data.wallpaper.picker !== "grid"
        readonly property real p: pAnim.v

        property string source: "folder"           // folder | wallhaven | kde | live
        property string query: ""
        property bool favOnly: false               // ★: favorites only
        readonly property var files: {
            const q = query.trim().toLowerCase();
            const all = favOnly ? Wallpapers.files.filter(f => (Wallpapers.cfg.favorites || []).includes(f)) : Wallpapers.files;
            return q ? all.filter(f => Paths.fileName(f).toLowerCase().includes(q)) : all;
        }
        readonly property string selected: files[view.currentIndex] ?? ""
        readonly property string applied: Wallpapers.forScreen(screenName)
        readonly property real cardW: Math.round(Math.min(760, width * 0.42))
        readonly property real cardH: Math.round(cardW * (modelData.height > 0 ? modelData.height / modelData.width : 9 / 16))

        function apply() {
            if (selected)
                Wallpapers.set(selected, screenName);
        }
        function close() {
            Panels.close();
        }
        function shuffle() {
            if (files.length > 1)
                view.currentIndex = (view.currentIndex + 1 + Math.floor(Math.random() * (files.length - 1))) % files.length;
        }

        // opening: the cards spin in to the current wallpaper
        onShownChanged: {
            if (!shown)
                return;
            Wallpapers.rescan();
            query = "";
            search.text = "";
            source = "folder";
            const i = Math.max(0, files.indexOf(applied));
            view.highlightMoveDuration = 0;
            view.currentIndex = files.length ? (i - 5 + files.length * 2) % files.length : 0;
            spinIn.target = i;
            spinIn.restart();
            keys.forceActiveFocus();
        }
        Timer {
            id: spinIn
            property int target: 0
            interval: 40
            onTriggered: {
                view.highlightMoveDuration = Theme.durA("panels", 700);
                view.currentIndex = target;
                restoreSpeed.restart();
            }
        }
        Timer {
            id: restoreSpeed
            interval: Theme.durA("panels", 700)
            onTriggered: view.highlightMoveDuration = Theme.durA("panels", 380)
        }

        screen: modelData
        visible: shown || p > 0.01
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "flamenco-wallpapers"
        WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        // animated value lives on an Item: Behaviors on the window itself crash Qt 6.12
        Item {
            id: pAnim
            property real v: win.shown ? 1 : 0
            Behavior on v { Anim { duration: Theme.durA("panels", 450); easing.bezierCurve: Theme.curves.emphasizedDecel } }
        }

        // ── the selected wallpaper, blurred, behind it all; a click there closes ──
        Item {
            anchors.fill: parent
            opacity: win.p
            BackdropLayer {
                source: Wallpapers.stillUrl(win.selected || win.applied)
                shown: true
            }
            Rectangle {
                anchors.fill: parent
                color: Theme.alpha(Theme.dark ? Theme.shadow : Theme.bg, 0.35)
            }
            MouseArea {
                anchors.fill: parent
                onClicked: win.close()
            }
        }

        // keys, while the search field isn't typing
        Item {
            id: keys
            focus: true
            Keys.onPressed: event => {
                const k = event.key;
                if (k === Qt.Key_Escape)
                    win.close();
                else if (k === Qt.Key_Left || k === Qt.Key_H)
                    view.decrementCurrentIndex();
                else if (k === Qt.Key_Right || k === Qt.Key_L)
                    view.incrementCurrentIndex();
                else if (k === Qt.Key_PageUp)
                    view.currentIndex = Math.max(0, view.currentIndex - 10);
                else if (k === Qt.Key_PageDown)
                    view.currentIndex = Math.min(view.count - 1, view.currentIndex + 10);
                else if (k === Qt.Key_Home)
                    view.currentIndex = 0;
                else if (k === Qt.Key_End)
                    view.currentIndex = view.count - 1;
                else if (k === Qt.Key_Return || k === Qt.Key_Enter)
                    win.apply();
                else if (k === Qt.Key_Up || k === Qt.Key_Down)
                    win.source = (k === Qt.Key_Down ? { folder: "wallhaven", wallhaven: "kde", kde: "live", live: "folder" } : { folder: "live", live: "kde", kde: "wallhaven", wallhaven: "folder" })[win.source];
                else if (k === Qt.Key_Slash || k === Qt.Key_F && event.modifiers & Qt.ControlModifier)
                    search.focusInput();
                else if (k === Qt.Key_R)
                    win.shuffle();
                else if (k === Qt.Key_F && win.selected)
                    Wallpapers.toggleFavorite(win.selected);
                else
                    return;
                event.accepted = true;
            }
        }

        Item {
            anchors.fill: parent
            opacity: win.p
            scale: 0.94 + 0.06 * win.p

            // ── top: source, search, shuffle ──
            RowLayout {
                id: top
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: Theme.barHeight + 40
                spacing: 12

                FSegmented {
                    implicitWidth: 560
                    options: [{ value: "folder", label: I18n.tr("Wallpapers · ") + Wallpapers.files.length, icon: "image" }, { value: "wallhaven", label: I18n.tr("Wallhaven"), icon: "travel_explore" }, { value: "kde", label: I18n.tr("KDE Store"), icon: "storefront" }, { value: "live", label: I18n.tr("Live"), icon: "animated_images" }]
                    current: win.source
                    onSelected: v => win.source = v
                }
                FTextField {
                    id: search
                    visible: win.source === "folder"
                    implicitWidth: 420
                    implicitHeight: 44
                    radius: height / 2
                    icon: "search"
                    placeholder: I18n.tr("Search ") + Wallpapers.files.length + " wallpapers…"
                    onEdited: t => {
                        win.query = t;
                        view.currentIndex = 0;
                    }
                    onAccepted: keys.forceActiveFocus()
                    onKeyPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            if (search.text !== "") {
                                search.text = "";
                                win.query = "";
                            } else {
                                win.close();
                            }
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                            keys.forceActiveFocus();
                            event.accepted = true;
                        }
                    }
                }
                FIconButton {
                    visible: win.source === "folder"
                    size: 44
                    flat: false
                    icon: "casino"
                    onClicked: win.shuffle()
                }
                // favorites only
                FIconButton {
                    visible: win.source === "folder"
                    size: 44
                    flat: false
                    icon: "star"
                    active: win.favOnly
                    onClicked: {
                        win.favOnly = !win.favOnly;
                        view.currentIndex = 0;
                    }
                }
                // per screen, or every screen at once
                FSegmented {
                    visible: Quickshell.screens.length > 1
                    implicitWidth: 240
                    options: [{ value: false, label: I18n.tr("All screens") }, { value: true, label: I18n.tr("This screen") }]
                    current: Settings.data.wallpaper.perScreen
                    onSelected: v => Settings.data.wallpaper.perScreen = v
                }
                FIconButton {
                    size: 44
                    flat: false
                    icon: "tune"
                    onClicked: Panels.openSettings("wallpaper")
                }
            }

            // ── the carousel ──
            PathView {
                id: view
                visible: win.source === "folder"
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -40
                height: win.cardH + 80
                // diffed, so a rescan doesn't send the carousel back to the first card
                model: ScriptModel { values: win.files }
                pathItemCount: Math.min(9, Math.max(1, win.files.length))
                cacheItemCount: 4
                preferredHighlightBegin: 0.5
                preferredHighlightEnd: 0.5
                highlightRangeMode: PathView.StrictlyEnforceRange
                highlightMoveDuration: Theme.durA("panels", 380)
                snapMode: PathView.SnapOneItem
                interactive: count > 1

                readonly property real c: width / 2
                readonly property real cy: height / 2
                readonly property real cw: win.cardW
                path: Path {
                    startX: view.c - view.cw * 1.77
                    startY: view.cy
                    PathAttribute { name: "rot"; value: 55 }
                    PathAttribute { name: "s"; value: 0.6 }
                    PathAttribute { name: "zz"; value: 0 }
                    PathAttribute { name: "op"; value: 0.35 }
                    PathLine { x: view.c - view.cw * 0.72; y: view.cy }
                    PathPercent { value: 0.389 }
                    PathAttribute { name: "rot"; value: 42 }
                    PathAttribute { name: "s"; value: 0.82 }
                    PathAttribute { name: "zz"; value: 90 }
                    PathAttribute { name: "op"; value: 0.95 }
                    PathLine { x: view.c; y: view.cy }
                    PathPercent { value: 0.5 }
                    PathAttribute { name: "rot"; value: 0 }
                    PathAttribute { name: "s"; value: 1 }
                    PathAttribute { name: "zz"; value: 100 }
                    PathAttribute { name: "op"; value: 1 }
                    PathLine { x: view.c + view.cw * 0.72; y: view.cy }
                    PathPercent { value: 0.611 }
                    PathAttribute { name: "rot"; value: -42 }
                    PathAttribute { name: "s"; value: 0.82 }
                    PathAttribute { name: "zz"; value: 90 }
                    PathAttribute { name: "op"; value: 0.95 }
                    PathLine { x: view.c + view.cw * 1.77; y: view.cy }
                    PathPercent { value: 1 }
                    PathAttribute { name: "rot"; value: -55 }
                    PathAttribute { name: "s"; value: 0.6 }
                    PathAttribute { name: "zz"; value: 0 }
                    PathAttribute { name: "op"; value: 0.35 }
                }

                WheelHandler {
                    onWheel: event => {
                        const n = cardNotches.take(event);
                        for (let i = 0; i < Math.abs(n); i++)
                            n > 0 ? view.decrementCurrentIndex() : view.incrementCurrentIndex();
                    }
                }
                WheelSteps { id: cardNotches; sideways: true }

                delegate: Item {
                    id: card
                    required property string modelData
                    required property int index
                    readonly property bool centre: PathView.isCurrentItem
                    width: win.cardW
                    height: win.cardH
                    z: PathView.zz ?? 0
                    scale: PathView.s ?? 1
                    opacity: PathView.op ?? 1
                    transform: Rotation {
                        origin.x: card.width / 2
                        origin.y: card.height / 2
                        axis { x: 0; y: 1; z: 0 }
                        angle: card.PathView.rot ?? 0
                    }

                    // the glow around the centre card
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -9
                        radius: Theme.rXl + 9
                        color: "transparent"
                        border.width: 8
                        border.color: Theme.alpha(Theme.accent, 0.55)
                        opacity: card.centre ? 1 : 0
                        Behavior on opacity { Anim {} }
                    }
                    ClippingRectangle {
                        anchors.fill: parent
                        radius: Theme.rXl
                        color: Theme.surfaceHigh
                        border.width: card.centre ? 2 : 0
                        border.color: Theme.accent

                        SafeImage {
                            anchors.fill: parent
                            path: Wallpapers.stillUrl(card.modelData)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            sourceSize: Qt.size(720, 420)
                            opacity: status === Image.Ready ? 1 : 0
                            Behavior on opacity { Anim {} }
                        }
                        // the side cards a little darker
                        Rectangle {
                            anchors.fill: parent
                            color: Theme.shadow
                            opacity: card.centre ? 0 : 0.28
                            Behavior on opacity { Anim {} }
                        }
                    }
                    LiveBadge {
                        path: card.modelData
                        big: true
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.margins: 12
                    }
                    Rectangle {
                        visible: card.modelData === win.applied
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 12
                        width: badge.implicitWidth + 20
                        height: 24
                        radius: 12
                        color: Theme.accent3
                        FText {
                            id: badge
                            anchors.centerIn: parent
                            text: "current"
                            font.pixelSize: Theme.fsXs
                            font.weight: Font.Bold
                            color: Theme.onAccent
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: card.centre ? win.apply() : view.currentIndex = card.index
                    }
                }
            }

            // a soft reflection under the centre card
            Item {
                visible: win.source === "folder" && win.selected !== ""
                anchors.horizontalCenter: parent.horizontalCenter
                y: view.y + view.height / 2 + win.cardH / 2 + 12
                width: win.cardW
                height: win.cardH * 0.4
                clip: true
                opacity: 0.4

                SafeImage {
                    id: mirror
                    width: win.cardW
                    height: win.cardH
                    path: Wallpapers.stillUrl(win.selected)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize: Qt.size(360, 210)
                    visible: false
                    transform: Scale { origin.y: win.cardH / 2; yScale: -1 }
                }
                MultiEffect {
                    width: win.cardW
                    height: win.cardH
                    source: mirror
                    blurEnabled: true
                    blur: 1
                    blurMax: 40
                    transform: Scale { origin.y: win.cardH / 2; yScale: -1 }
                }
                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0; color: "transparent" }
                        GradientStop { position: 1; color: Theme.alpha(Theme.dark ? Theme.shadow : Theme.bg, 0.9) }
                    }
                }
            }

            // ── Wallhaven ──
            Rectangle {
                visible: win.source === "wallhaven"
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: top.bottom
                anchors.topMargin: 24
                width: Math.min(1100, parent.width - 160)
                height: Math.min(620, parent.height - top.y - top.height - 120)
                radius: Theme.rXl
                color: Theme.switcherBg
                border.width: 1
                border.color: Theme.border
                Loader {
                    anchors.fill: parent
                    anchors.margins: Theme.sp4
                    active: win.source === "wallhaven"
                    sourceComponent: WallhavenGrid {
                        screenName: win.screenName
                        minSize: Qt.size(win.modelData.width, win.modelData.height)
                    }
                }
            }

            // ── the KDE Store ──
            Rectangle {
                visible: win.source === "kde"
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: top.bottom
                anchors.topMargin: 24
                width: Math.min(1100, parent.width - 160)
                height: Math.min(620, parent.height - top.y - top.height - 120)
                radius: Theme.rXl
                color: Theme.switcherBg
                border.width: 1
                border.color: Theme.border
                Loader {
                    anchors.fill: parent
                    anchors.margins: Theme.sp4
                    active: win.source === "kde"
                    sourceComponent: KdeStoreGrid {
                        screenName: win.screenName
                    }
                }
            }

            // ── live wallpapers online ──
            Rectangle {
                visible: win.source === "live"
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: top.bottom
                anchors.topMargin: 24
                width: Math.min(1100, parent.width - 160)
                height: Math.min(620, parent.height - top.y - top.height - 120)
                radius: Theme.rXl
                color: Theme.switcherBg
                border.width: 1
                border.color: Theme.border
                Loader {
                    anchors.fill: parent
                    anchors.margins: Theme.sp4
                    active: win.source === "live"
                    sourceComponent: LiveGrid {
                        screenName: win.screenName
                    }
                }
            }

            FText {
                visible: win.source === "folder" && view.count === 0
                anchors.centerIn: parent
                horizontalAlignment: Text.AlignHCenter
                text: Wallpapers.scanning ? I18n.tr("Scanning…") : win.query ? I18n.tr("No wallpapers match “") + win.query + "”"
                    : Wallpapers.status === "missing" ? "Folder not found:\n" + Wallpapers.dir : "No images in " + Wallpapers.dir
                color: "#ffffff"
                font.pixelSize: Theme.fsLg
            }

            // ── bottom: its name, colors, place, Apply ──
            ColumnLayout {
                visible: win.source === "folder" && view.count > 0
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 36
                spacing: 10

                FText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Paths.fileName(win.selected).replace(/\.[^.]+$/, "")
                    color: "#ffffff"
                    font.pixelSize: Theme.fsLg
                    font.weight: Font.Bold
                    style: Text.Raised
                    styleColor: Theme.alpha(Theme.shadow, 0.4)
                }
                // its colors (click one to copy it)
                Row {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 8
                    Repeater {
                        model: quant.colors.slice(0, 8)
                        Rectangle {
                            required property color modelData
                            width: 30
                            height: 30
                            radius: 8
                            color: modelData
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.35)
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Quickshell.execDetached(["wl-copy", String(parent.modelData).slice(0, 7)])
                            }
                        }
                    }
                }
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 12
                    FText {
                        text: (view.currentIndex + 1) + "  /  " + view.count
                        color: Qt.rgba(1, 1, 1, 0.8)
                        mono: true
                        font.pixelSize: Theme.fsSm
                    }
                    FIconButton {
                        readonly property bool fav: Wallpapers.isFavorite(win.selected)
                        icon: "star"
                        iconColor: fav ? Theme.warning : "#ffffff"
                        onClicked: Wallpapers.toggleFavorite(win.selected)
                    }
                    FButton {
                        text: win.selected === win.applied ? I18n.tr("Applied") : I18n.tr("Apply")
                        icon: "check"
                        disabled: win.selected === win.applied
                        onClicked: win.apply()
                    }
                }
                FText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "← → browse  ·  ↑ ↓ wallpapers / Wallhaven / KDE Store / Live  ·  Enter apply  ·  / search  ·  R shuffle  ·  F favorite  ·  click the centre card to apply"
                    color: Qt.rgba(1, 1, 1, 0.6)
                    font.pixelSize: Theme.fsXs
                }
            }
        }

        ColorQuantizer {
            id: quant
            source: win.selected ? Wallpapers.stillUrl(win.selected) : ""
            depth: 3
            rescaleSize: 64
        }
    }
}
