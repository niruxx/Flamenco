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
        implicitHeight: 780
        color: Theme.bg
        visible: true
        onVisibleChanged: if (!visible) Panels.settingsOpen = false

        readonly property var pages: [
            { id: "appearance", icon: "palette", label: "Appearance", comp: appearanceC },
            { id: "apps", icon: "format_paint", label: "App Theming", comp: appsC },
            { id: "bar", icon: "toolbar", label: "Bar", comp: barC },
            { id: "dock", icon: "dock_to_bottom", label: "Dock", comp: dockC },
            { id: "windows", icon: "select_window", label: "Windows & Layout", comp: windowsC },
            { id: "workspaces", icon: "view_carousel", label: "Workspaces", comp: workspacesC },
            { id: "edges", icon: "select_all", label: "Screen edges", comp: edgesC },
            { id: "desktop", icon: "widgets", label: "Desktop widgets", comp: desktopC },
            { id: "displays", icon: "monitor", label: "Displays", comp: displaysC },
            { id: "keyboard", icon: "keyboard", label: "Keyboard", comp: keyboardC },
            { id: "pointer", icon: "mouse", label: "Mouse & Touchpad", comp: pointerC },
            { id: "network", icon: "wifi", label: "Network", comp: networkC },
            { id: "ai", icon: "auto_awesome", label: "AI", comp: aiC },
            { id: "sharing", icon: "screen_share", label: "Screen sharing & files", comp: sharingC },
            { id: "sound", icon: "volume_up", label: "Sound", comp: soundC },
            { id: "screenshots", icon: "screenshot_monitor", label: "Screenshots", comp: screenshotC },
            { id: "power", icon: "battery_charging_full", label: "Power", comp: powerC },
            { id: "firewall", icon: "shield", label: "Firewall", comp: firewallC },
            { id: "keyring", icon: "key", label: "Keyring", comp: keyringC },
            { id: "printers", icon: "print", label: "Printers", comp: printersC },
            { id: "wallpaper", icon: "wallpaper", label: "Wallpaper", comp: wallpaperC },
            { id: "notifications", icon: "notifications", label: "Notifications", comp: notifC },
            { id: "launcher", icon: "apps", label: "Launcher", comp: launcherC },
            { id: "defaults", icon: "open_in_new", label: "Default apps", comp: defaultsC },
            { id: "autostart", icon: "rocket_launch", label: "Auto-start", comp: autostartC },
            { id: "flatpak", icon: "inventory_2", label: "Flatpak permissions", comp: flatpakC },
            { id: "lock", icon: "lock", label: "Lock & Login", comp: lockC },
            { id: "clock", icon: "schedule", label: "Clock & Weather", comp: clockC },
            { id: "system", icon: "health_and_safety", label: "System check", comp: systemC },
            { id: "about", icon: "info", label: "About", comp: aboutC }
        ]
        readonly property int index: Math.max(0, pages.findIndex(p => p.id === Panels.settingsPage))

        Component { id: appearanceC; AppearancePage {} }
        Component { id: appsC; AppThemingPage {} }
        Component { id: barC; BarPage {} }
        Component { id: dockC; DockPage {} }
        Component { id: desktopC; DesktopPage {} }
        Component { id: displaysC; DisplaysPage {} }
        Component { id: keyboardC; KeyboardPage {} }
        Component { id: pointerC; PointerPage {} }
        Component { id: networkC; NetworkPage {} }
        Component { id: aiC; AiPage {} }
        Component { id: sharingC; ScreenSharingPage {} }
        Component { id: soundC; SoundPage {} }
        Component { id: firewallC; FirewallPage {} }
        Component { id: keyringC; KeyringPage {} }
        Component { id: powerC; PowerSettingsPage {} }
        Component { id: printersC; PrintersPage {} }
        Component { id: systemC; SystemCheckPage {} }
        Component { id: wallpaperC; WallpaperPage {} }
        Component { id: notifC; NotificationsPage {} }
        Component { id: launcherC; LauncherPage {} }
        Component { id: lockC; LockPage {} }
        Component { id: clockC; ClockPage {} }
        Component { id: aboutC; AboutPage {} }
        Component { id: windowsC; WindowsPage {} }
        Component { id: workspacesC; WorkspacesPage {} }
        Component { id: edgesC; EdgesPage {} }
        Component { id: screenshotC; ScreenshotPage {} }
        Component { id: defaultsC; DefaultAppsPage {} }
        Component { id: autostartC; AutostartPage {} }
        Component { id: flatpakC; FlatpakPage {} }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // ── title bar (drag it to move the window; Super+drag also works) ──
            Rectangle {
                id: titleBar
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                color: Theme.surface

                // Hand the drag to the compositor (xdg_toplevel.move). A DragHandler only
                // activates once the pointer moves, so clicks on the buttons still work.
                DragHandler {
                    target: null
                    cursorShape: Qt.ClosedHandCursor
                    onActiveChanged: {
                        const w = titleBar.Window.window;
                        if (active && w && typeof w.startSystemMove === "function")
                            w.startSystemMove();
                    }
                }
                HoverHandler {
                    cursorShape: Qt.OpenHandCursor
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.sp4
                    anchors.rightMargin: 10
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 30
                        Layout.preferredHeight: 30
                        radius: Theme.rSm
                        gradient: Gradient {
                            GradientStop { position: 0; color: Theme.accent }
                            GradientStop { position: 1; color: Theme.accent2 }
                        }
                        FIcon { anchors.centerIn: parent; icon: "local_fire_department"; size: 18; fill: 1; color: Theme.onAccent }
                    }
                    FText {
                        text: "Flamenco Settings"
                        font.pixelSize: Theme.fsLg
                        font.weight: Font.Bold
                    }
                    FIcon {
                        icon: "chevron_right"
                        size: 18
                        color: Theme.textDim
                    }
                    // current page, cross-fading on change
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        FText {
                            id: crumb
                            anchors.verticalCenter: parent.verticalCenter
                            text: win.pages[win.index].label
                            dim: true
                            Behavior on text {
                                SequentialAnimation {
                                    NumberAnimation { target: crumb; property: "opacity"; to: 0; duration: Theme.durShort }
                                    PropertyAction {}
                                    NumberAnimation { target: crumb; property: "opacity"; to: 1; duration: Theme.durShort }
                                }
                            }
                        }
                    }
                    FIconButton {
                        icon: "close"
                        size: 32
                        iconSize: 18
                        iconColor: hovered ? Theme.onAccent : Theme.text
                        activeColor: Theme.error
                        active: hovered
                        onClicked: Panels.settingsOpen = false
                    }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: Theme.border
                    opacity: 0.6
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                // ── sidebar ──
                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 268
                    color: Theme.surface

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.sp4
                        anchors.rightMargin: Theme.sp2
                        spacing: 4

                        FScroll {
                            id: navScroll
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            contentHeight: nav.implicitHeight

                            // gliding selection
                            Rectangle {
                                width: nav.width
                                height: 38
                                y: win.index * 40
                                radius: Theme.rMd
                                color: Theme.accent
                                Behavior on y { Anim { duration: Theme.durLong; easing.bezierCurve: Theme.curves.spring } }
                            }

                            Column {
                                id: nav
                                width: navScroll.width - navScroll.gutter
                                Behavior on width { Anim { duration: Theme.durShort } }
                                spacing: 2
                                Repeater {
                                    model: win.pages
                                    Item {
                                        required property var modelData
                                        required property int index
                                        readonly property bool sel: win.index === index
                                        width: nav.width
                                        height: 38

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
                                                Layout.rightMargin: 10
                                                text: modelData.label
                                                elide: Text.ElideRight
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
}
