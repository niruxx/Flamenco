import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets
import qs.Modules.Settings.Pages

// First-run setup: a guided tour through the settings that matter on day one,
// ending with "Welcome to Flamenco". Reuses the real settings pages.
LazyLoader {
    active: Panels.setupOpen

    FloatingWindow {
        id: win

        title: I18n.tr("Flamenco Setup")
        implicitWidth: 1040
        implicitHeight: 760
        color: Theme.bg
        visible: true
        onVisibleChanged: if (!visible) Panels.setupOpen = false

        readonly property var steps: [
            { id: "welcome", icon: "waving_hand", label: I18n.tr("Welcome"), comp: welcomeC },
            { id: "displays", icon: "monitor", label: I18n.tr("Displays"), comp: displaysC },
            { id: "look", icon: "palette", label: I18n.tr("Look & colors"), comp: lookC },
            { id: "apps", icon: "format_paint", label: I18n.tr("Icons & cursors"), comp: appsC },
            { id: "wallpaper", icon: "wallpaper", label: I18n.tr("Wallpaper"), comp: wallpaperC },
            { id: "sound", icon: "volume_up", label: I18n.tr("Sound"), comp: soundC },
            { id: "bluetooth", icon: "bluetooth", label: I18n.tr("Bluetooth"), comp: btC },
            { id: "sharing", icon: "screen_share", label: I18n.tr("Screen sharing & files"), comp: sharingC },
            { id: "keyring", icon: "key", label: I18n.tr("Keyring"), comp: keyringC },
            { id: "done", icon: "celebration", label: I18n.tr("All set"), comp: doneC }
        ]
        property int index: 0
        property int furthest: 0
        property int dir: 1
        readonly property bool last: index === steps.length - 1

        function go(i) {
            i = Math.max(0, Math.min(steps.length - 1, i));
            dir = i >= index ? 1 : -1;
            index = i;
            furthest = Math.max(furthest, i);
        }
        function finish(playWelcome) {
            Settings.data.general.setupDone = true;
            Panels.setupOpen = false;
            if (playWelcome)
                SessionFx.playIntro(true);
        }

        Component { id: displaysC; DisplaysPage {} }
        Component { id: lookC; AppearancePage {} }
        Component { id: appsC; AppThemingPage {} }
        Component { id: wallpaperC; WallpaperPage {} }
        Component { id: soundC; SoundPage {} }
        Component { id: btC; BluetoothStep {} }
        Component { id: sharingC; ScreenSharingPage {} }
        Component { id: keyringC; KeyringPage {} }
        Component { id: welcomeC; WelcomeStep { steps: win.steps; onStart: win.go(1) } }
        Component { id: doneC; DoneStep { onFinish: win.finish(true) } }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // ── step rail (drag its empty space to move the window) ──
            Rectangle {
                id: railBg
                Layout.fillHeight: true
                Layout.preferredWidth: 250
                color: Theme.surface

                DragHandler {
                    target: null
                    onActiveChanged: {
                        const w = railBg.Window.window;
                        if (active && w && typeof w.startSystemMove === "function")
                            w.startSystemMove();
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.sp4
                    spacing: 4

                    RowLayout {
                        Layout.bottomMargin: Theme.sp4
                        spacing: 10
                        Rectangle {
                            Layout.preferredWidth: 34
                            Layout.preferredHeight: 34
                            radius: Theme.rMd
                            gradient: Gradient {
                                GradientStop { position: 0; color: Theme.accent }
                                GradientStop { position: 1; color: Theme.accent2 }
                            }
                            FIcon { anchors.centerIn: parent; icon: "local_fire_department"; size: 20; fill: 1; color: Theme.onAccent }
                        }
                        ColumnLayout {
                            spacing: -2
                            FText { text: I18n.tr("Flamenco"); font.pixelSize: Theme.fsLg; font.weight: Font.Bold }
                            FText { text: I18n.tr("Setup"); dim: true; font.pixelSize: Theme.fsSm }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        implicitHeight: rail.implicitHeight

                        Rectangle {
                            width: parent.width
                            height: 38
                            y: win.index * 40
                            radius: Theme.rMd
                            color: Theme.accent
                            Behavior on y { Anim { duration: Theme.durLong; easing.bezierCurve: Theme.curves.spring } }
                        }

                        Column {
                            id: rail
                            width: parent.width
                            spacing: 2
                            Repeater {
                                model: win.steps
                                Item {
                                    required property var modelData
                                    required property int index
                                    readonly property bool cur: win.index === index
                                    readonly property bool visited: index <= win.furthest && !cur
                                    width: rail.width
                                    height: 38

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 10
                                        spacing: 10
                                        FIcon {
                                            icon: visited && !cur ? "check_circle" : modelData.icon
                                            fill: cur || visited ? 1 : 0
                                            size: 18
                                            color: cur ? Theme.onAccent : visited ? Theme.success : Theme.textDim
                                        }
                                        FText {
                                            Layout.fillWidth: true
                                            text: modelData.label
                                            elide: Text.ElideRight
                                            font.weight: cur ? Font.Bold : Font.Normal
                                            color: cur ? Theme.onAccent : index <= win.furthest ? Theme.text : Theme.textDim
                                        }
                                    }
                                    StateLayer {
                                        radius: Theme.rMd
                                        tint: cur ? Theme.onAccent : Theme.text
                                        onClicked: win.go(index)
                                    }
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    FButton {
                        Layout.fillWidth: true
                        visible: !win.last
                        text: I18n.tr("Skip for now")
                        variant: "text"
                        onClicked: win.finish(false)
                    }
                    FText {
                        Layout.fillWidth: true
                        text: I18n.tr("Everything here is also in Settings")
                        dim: true
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Theme.fsXs
                    }
                }
            }

            // ── step + footer ──
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                // progress
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 3
                    color: Theme.surfaceHigh
                    Rectangle {
                        height: parent.height
                        width: parent.width * (win.index / (win.steps.length - 1))
                        color: Theme.accent
                        Behavior on width { Anim { duration: Theme.durLong; easing.bezierCurve: Theme.curves.emphasizedDecel } }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    Loader {
                        id: loader
                        anchors.fill: parent
                        sourceComponent: win.steps[win.index].comp
                        property real enter: 1
                        opacity: enter
                        transform: Translate { x: (1 - loader.enter) * 40 * win.dir }
                        onSourceComponentChanged: {
                            enter = 0;
                            enterAnim.restart();
                        }
                        NumberAnimation {
                            id: enterAnim
                            target: loader
                            property: "enter"
                            to: 1
                            duration: Theme.durLong
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Theme.curves.emphasizedDecel
                        }
                    }
                }

                // footer
                Rectangle {
                    visible: win.index > 0 && !win.last
                    Layout.fillWidth: true
                    Layout.preferredHeight: 64
                    color: Theme.surface

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.sp5
                        anchors.rightMargin: Theme.sp5
                        spacing: Theme.sp3
                        FText {
                            Layout.fillWidth: true
                            text: I18n.tr("Step ") + win.index + " of " + (win.steps.length - 2)
                            dim: true
                        }
                        FButton {
                            text: I18n.tr("Back")
                            icon: "arrow_back"
                            variant: "outlined"
                            onClicked: win.go(win.index - 1)
                        }
                        FButton {
                            text: win.index === win.steps.length - 2 ? I18n.tr("Finish") : I18n.tr("Next")
                            icon: "arrow_forward"
                            onClicked: win.go(win.index + 1)
                        }
                    }
                }
            }
        }
    }
}
