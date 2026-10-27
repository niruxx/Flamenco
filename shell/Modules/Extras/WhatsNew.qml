import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Services
import qs.Widgets

// "What's new": after an update, once, the versions since the one seen last
// (assets/changelog.json). Also from Settings → About.
Scope {
    id: root
    property var log: []
    readonly property string latest: log[0]?.version ?? ""
    readonly property string seen: Settings.data.general.seenVersion || ""
    readonly property var fresh: {
        const out = [];
        for (const v of log) {
            if (v.version === seen)
                break;
            out.push(v);
        }
        return out.slice(0, 5);
    }
    readonly property bool shown: Panels.whatsNew

    FileView {
        path: Quickshell.shellDir + "/assets/changelog.json"
        onLoaded: {
            try {
                root.log = JSON.parse(text());
            } catch (e) {}
        }
    }
    // once settings are read: a fresh install just notes the version; an update shows what's new
    Timer {
        running: Settings.ready && root.latest !== ""
        interval: 4000
        onTriggered: {
            if (!Settings.data.general.setupDone || root.seen === "")
                Settings.data.general.seenVersion = root.latest;
            else if (root.seen !== root.latest)
                Panels.whatsNew = true;
        }
    }
    function close() {
        Settings.data.general.seenVersion = latest;
        Panels.whatsNew = false;
    }

    PanelWindow {
        visible: root.shown
        screen: Quickshell.screens.find(s => s.name === Panels.targetScreen("")) ?? Quickshell.screens[0]
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "flamenco-whatsnew"
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        Rectangle {
            anchors.fill: parent
            color: Theme.alpha(Theme.shadow, 0.4)
            MouseArea { anchors.fill: parent; onClicked: root.close() }
        }
        Rectangle {
            anchors.centerIn: parent
            width: Math.min(560, parent.width - 48)
            height: Math.min(col.implicitHeight + Theme.sp5 * 2, parent.height - 80)
            radius: Theme.rXl
            color: Theme.popupBg
            border.width: 1
            border.color: Theme.alpha(Theme.border, 0.7)
            focus: true
            Keys.onEscapePressed: root.close()
            Keys.onReturnPressed: root.close()
            FScroll {
                anchors.fill: parent
                anchors.margins: Theme.sp5
                contentHeight: col.implicitHeight
                ColumnLayout {
                    id: col
                    width: parent.width
                    spacing: Theme.sp3
                    RowLayout {
                        spacing: Theme.sp3
                        FIcon { icon: "auto_awesome"; size: 30; fill: 1; color: Theme.accent }
                        FText { text: I18n.tr("What's new in Flamenco ") + root.latest; font.pixelSize: Theme.fsXl; font.weight: Font.Bold }
                    }
                    Repeater {
                        model: root.fresh.length ? root.fresh : root.log.slice(0, 1)
                        ColumnLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 6
                            FText { text: modelData.version; color: Theme.accent; font.weight: Font.DemiBold }
                            Repeater {
                                model: modelData.items
                                FText {
                                    required property string modelData
                                    Layout.fillWidth: true
                                    text: "•  " + modelData
                                    wrapMode: Text.Wrap
                                }
                            }
                        }
                    }
                    FButton {
                        Layout.alignment: Qt.AlignRight
                        text: I18n.tr("Got it")
                        onClicked: root.close()
                    }
                }
            }
        }
    }
}
