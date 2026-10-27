import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services
import qs.Widgets

// "Which browser?" for a link (Settings → Default apps → Ask which browser): the
// installed browsers; "always" makes the chosen one the default again.
PanelWindow {
    id: win
    readonly property string url: Panels.browserUrl
    property bool always: false
    readonly property var browsers: Apps.all.filter(e => (e.categories ?? []).includes("WebBrowser") && !String(e.id).includes("flamenco-browser-picker"))
    property int sel: 0

    function choose(e) {
        if (!e)
            return;
        Quickshell.execDetached([Paths.bin, "open-with", e.id.endsWith(".desktop") ? e.id : e.id + ".desktop", url]);
        if (always) {
            Settings.data.general.browserPicker = false;
            Quickshell.execDetached(["sh", "-c", 'f="$1"; "$2" browser-picker off; xdg-settings set default-web-browser "$f"', "sh", e.id.endsWith(".desktop") ? e.id : e.id + ".desktop", Paths.bin]);
        }
        Panels.browserUrl = "";
    }

    visible: url !== ""
    onVisibleChanged: {
        sel = 0;
        always = false;
    }
    screen: Quickshell.screens.find(s => s.name === Panels.targetScreen("")) ?? Quickshell.screens[0]
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "flamenco-browser-picker"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Rectangle {
        anchors.fill: parent
        color: Theme.alpha(Theme.shadow, 0.35)
        MouseArea { anchors.fill: parent; onClicked: Panels.browserUrl = "" }
    }
    Rectangle {
        anchors.centerIn: parent
        width: Math.min(460, parent.width - 48)
        height: col.implicitHeight + Theme.sp5 * 2
        radius: Theme.rXl
        color: Theme.popupBg
        border.width: 1
        border.color: Theme.alpha(Theme.border, 0.7)
        focus: true
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape)
                Panels.browserUrl = "";
            else if (event.key === Qt.Key_Down)
                win.sel = (win.sel + 1) % Math.max(1, win.browsers.length);
            else if (event.key === Qt.Key_Up)
                win.sel = (win.sel + win.browsers.length - 1) % Math.max(1, win.browsers.length);
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                win.choose(win.browsers[win.sel]);
            else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9)
                win.choose(win.browsers[event.key - Qt.Key_1]);
            else
                return;
            event.accepted = true;
        }
        ColumnLayout {
            id: col
            x: Theme.sp5
            y: Theme.sp5
            width: parent.width - Theme.sp5 * 2
            spacing: Theme.sp2
            FText { text: "Open with"; font.pixelSize: Theme.fsLg; font.weight: Font.Bold }
            FText { Layout.fillWidth: true; text: win.url; dim: true; elide: Text.ElideMiddle; font.pixelSize: Theme.fsSm }
            Repeater {
                model: win.browsers
                Rectangle {
                    id: b
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    implicitHeight: 48
                    radius: Theme.rMd
                    color: win.sel === index ? Theme.alpha(Theme.accent, 0.16) : "transparent"
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 12
                        AppIcon { implicitSize: 30; name: b.modelData.icon }
                        FText { Layout.fillWidth: true; text: b.modelData.name; elide: Text.ElideRight }
                        FText { visible: b.index < 9; text: String(b.index + 1); dim: true; mono: true }
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: win.sel = b.index
                        onClicked: win.choose(b.modelData)
                    }
                }
            }
            RowLayout {
                spacing: 8
                FSwitch { checked: win.always; onToggled: c => win.always = c }
                FText { text: "Always use this one (stop asking)"; dim: true }
            }
        }
    }
}
