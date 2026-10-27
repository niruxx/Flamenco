import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Services
import qs.Widgets

// A QR code: of the Wi-Fi network you're on (to share it with a phone), or of any
// text you type (`flamenco qr`, with qrencode). Opened from Wi-Fi settings and the
// launcher ("qr " and some text).
PanelWindow {
    id: win
    readonly property bool shown: Panels.qr !== ""
    property string path: ""
    property string label: ""
    property string error: ""

    function make(args) {
        error = "";
        maker.command = [Paths.bin, "qr"].concat(args);
        maker.running = true;
    }
    onShownChanged: {
        path = "";
        label = "";
        if (shown)
            Panels.qr === "@wifi" ? make(["--wifi"]) : make([Panels.qr]);
    }
    Process {
        id: maker
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    win.path = d.path;
                    win.label = d.label;
                } catch (e) {}
            }
        }
        stderr: StdioCollector { onStreamFinished: if (text.trim()) win.error = text.trim().split("\n").pop().replace(/^flamenco: /, "") }
    }

    visible: shown
    screen: Quickshell.screens.find(s => s.name === Panels.targetScreen("")) ?? Quickshell.screens[0]
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "flamenco-qr"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Rectangle {
        anchors.fill: parent
        color: Theme.alpha(Theme.shadow, 0.4)
        MouseArea { anchors.fill: parent; onClicked: Panels.qr = "" }
    }
    Rectangle {
        anchors.centerIn: parent
        width: 380
        height: col.implicitHeight + Theme.sp5 * 2
        radius: Theme.rXl
        color: Theme.popupBg
        border.width: 1
        border.color: Theme.alpha(Theme.border, 0.7)
        ColumnLayout {
            id: col
            x: Theme.sp5
            y: Theme.sp5
            width: parent.width - Theme.sp5 * 2
            spacing: Theme.sp3
            FText { text: Panels.qr === "@wifi" ? I18n.tr("Share Wi-Fi") + (win.label ? ": " + win.label : "") : I18n.tr("QR code"); font.pixelSize: Theme.fsLg; font.weight: Font.Bold }
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 260
                implicitHeight: 260
                radius: Theme.rMd
                color: "#ffffff"
                Image {
                    anchors.fill: parent
                    anchors.margins: 10
                    source: win.path ? "file://" + win.path : ""
                    sourceSize: Qt.size(480, 480)
                    smooth: false
                    fillMode: Image.PreserveAspectFit
                }
                FText { anchors.centerIn: parent; visible: !win.path; text: win.error ? "" : I18n.tr("Making it…"); color: "#555" }
            }
            FText { Layout.fillWidth: true; visible: win.error !== ""; text: win.error; color: Theme.error; wrapMode: Text.Wrap }
            FText { Layout.fillWidth: true; visible: Panels.qr === "@wifi" && win.path; text: I18n.tr("Point a phone's camera at it to join"); dim: true; horizontalAlignment: Text.AlignHCenter }
            FTextField {
                Layout.fillWidth: true
                placeholder: I18n.tr("Or type text or a link for a QR code")
                onAccepted: if (text.trim()) win.make([text.trim()])
            }
            FButton { Layout.alignment: Qt.AlignRight; text: I18n.tr("Done"); onClicked: Panels.qr = "" }
        }
    }
}
