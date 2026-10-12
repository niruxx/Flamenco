import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets
import "Pages"

// The Flamenco Settings app: a regular toplevel window (app-id org.quickshell,
// title "Flamenco Settings") so niri can tile/float it like any other app.
LazyLoader {
    active: Panels.settingsOpen

    FloatingWindow {
        id: win

        title: "Flamenco Settings"
        implicitWidth: 1040
        implicitHeight: 720
        color: Theme.bg
        visible: true
        onVisibleChanged: if (!visible) Panels.settingsOpen = false

        readonly property var pages: [
            { id: "appearance", icon: "palette", label: "Appearance", comp: appearanceC },
            { id: "apps", icon: "format_paint", label: "App Theming", comp: appsC },
            { id: "bar", icon: "toolbar", label: "Bar", comp: barC },
            { id: "dock", icon: "dock_to_bottom", label: "Dock", comp: dockC },
            { id: "wallpaper", icon: "wallpaper", label: "Wallpaper", comp: wallpaperC },
            { id: "notifications", icon: "notifications", label: "Notifications", comp: notifC },
            { id: "launcher", icon: "apps", label: "Launcher", comp: launcherC },
            { id: "lock", icon: "lock", label: "Lock & Idle", comp: lockC },
            { id: "clock", icon: "schedule", label: "Clock & Weather", comp: clockC },
            { id: "about", icon: "info", label: "About", comp: aboutC }
        ]
        readonly property int index: Math.max(0, pages.findIndex(p => p.id === Panels.settingsPage))

        Component { id: appearanceC; AppearancePage {} }
        Component { id: appsC; AppThemingPage {} }
        Component { id: barC; BarPage {} }
        Component { id: dockC; DockPage {} }
        Component { id: wallpaperC; WallpaperPage {} }
        Component { id: notifC; NotificationsPage {} }
        Component { id: launcherC; LauncherPage {} }
        Component { id: lockC; LockPage {} }
        Component { id: clockC; ClockPage {} }
        Component { id: aboutC; AboutPage {} }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // ── sidebar ──
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 248
                color: Theme.surface

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.sp4
                    spacing: 4

                    RowLayout {
                        Layout.bottomMargin: Theme.sp4
                        Layout.leftMargin: 6
                        spacing: 10
                        Rectangle {
                            width: 36; height: 36; radius: Theme.rMd
                            gradient: Gradient {
                                GradientStop { position: 0; color: Theme.accent }
                                GradientStop { position: 1; color: Theme.accent2 }
                            }
                            FIcon { anchors.centerIn: parent; icon: "local_fire_department"; fill: 1; color: Theme.onAccent }
                        }
                        ColumnLayout {
                            spacing: -2
                            FText { text: "Flamenco"; font.pixelSize: Theme.fsLg; font.weight: Font.Bold }
                            FText { text: "Settings"; dim: true; font.pixelSize: Theme.fsSm }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        implicitHeight: nav.implicitHeight

                        // gliding selection
                        Rectangle {
                            width: parent.width
                            height: 42
                            y: win.index * 46
                            radius: Theme.rMd
                            color: Theme.accent
                            Behavior on y { Anim { duration: Theme.durLong; easing.bezierCurve: Theme.curves.spring } }
                        }

                        Column {
                            id: nav
                            width: parent.width
                            spacing: 4
                            Repeater {
                                model: win.pages
                                Item {
                                    required property var modelData
                                    required property int index
                                    readonly property bool sel: win.index === index
                                    width: nav.width
                                    height: 42

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 14
                                        spacing: 12
                                        FIcon {
                                            icon: modelData.icon
                                            fill: sel ? 1 : 0
                                            color: sel ? Theme.onAccent : Theme.text
                                        }
                                        FText {
                                            Layout.fillWidth: true
                                            text: modelData.label
                                            font.weight: sel ? Font.Bold : Font.Normal
                                            color: sel ? Theme.onAccent : Theme.text
                                        }
                                    }
                                    StateLayer {
                                        radius: Theme.rMd
                                        tint: sel ? Theme.onAccent : Theme.text
                                        onClicked: Panels.settingsPage = modelData.id
                                    }
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    FText {
                        Layout.leftMargin: 6
                        text: "Changes apply instantly"
                        dim: true
                        font.pixelSize: Theme.fsXs
                    }
                }
            }

            // ── page ──
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                Loader {
                    id: loader
                    anchors.fill: parent
                    sourceComponent: win.pages[win.index].comp
                    property real enter: 1
                    opacity: enter
                    transform: Translate { y: (1 - loader.enter) * 24 }
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
        }
    }
}
