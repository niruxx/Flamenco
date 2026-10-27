import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

// "Welcome to Flamenco" with the user's actual shortcuts.
Item {
    id: root
    signal finish

    function keyFor(fn, fallback) {
        return Settings.data.keyboard.shortcuts.find(sc => sc.type === "flamenco" && sc.value === fn)?.key ?? fallback;
    }
    readonly property var tips: [
        { icon: "apps", label: I18n.tr("Open apps"), key: keyFor("launcher", "Mod+Space") },
        { icon: "tune", label: I18n.tr("Quick settings"), key: keyFor("control", "Mod+A") },
        { icon: "notifications", label: I18n.tr("Notifications"), key: keyFor("notifications", "Mod+N") },
        { icon: "wallpaper", label: I18n.tr("Wallpapers"), key: keyFor("wallpapers", "Mod+W") },
        { icon: "settings", label: I18n.tr("Settings"), key: keyFor("settings", "Mod+Comma") },
        { icon: "power_settings_new", label: I18n.tr("Power menu"), key: keyFor("power", "Mod+Escape") }
    ]

    // a few drifting sparks
    Repeater {
        model: Theme.speed > 0 ? 14 : 0
        Rectangle {
            required property int index
            readonly property real seed: (index * 37 % 100) / 100
            width: 6 + seed * 8
            height: width
            radius: width / 2
            color: index % 3 === 0 ? Theme.accent : index % 3 === 1 ? Theme.accent2 : Theme.accent3
            x: root.width * ((index * 53 % 100) / 100)
            opacity: 0
            SequentialAnimation on y {
                loops: Animation.Infinite
                PauseAnimation { duration: index * 220 }
                NumberAnimation { from: root.height + 20; to: -20; duration: 5200 + seed * 3000; easing.type: Easing.OutQuad }
            }
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                PauseAnimation { duration: index * 220 }
                NumberAnimation { from: 0; to: 0.7; duration: 900 }
                NumberAnimation { to: 0; duration: 4300 + seed * 3000 }
            }
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(600, parent.width - 80)
        spacing: Theme.sp4

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 112
            Layout.preferredHeight: 112
            radius: Theme.rXl * 1.4
            gradient: Gradient {
                GradientStop { position: 0; color: Theme.accent }
                GradientStop { position: 1; color: Theme.accent2 }
            }
            scale: 0.3
            Component.onCompleted: scale = 1
            Behavior on scale { Anim { duration: Theme.durXl; easing.bezierCurve: Theme.curves.spring } }
            FIcon { anchors.centerIn: parent; icon: "local_fire_department"; size: 66; fill: 1; color: Theme.onAccent }
        }

        FText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: I18n.tr("Welcome to Flamenco, ") + Paths.user
            font.pixelSize: Theme.fsXxl
            font.weight: Font.Bold
            wrapMode: Text.Wrap
        }
        FText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: I18n.tr("You're all set. A few keys to remember:")
            dim: true
        }

        GridLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Theme.sp2
            columns: 2
            rowSpacing: 10
            columnSpacing: Theme.sp6
            Repeater {
                model: root.tips
                RowLayout {
                    required property var modelData
                    spacing: 10
                    FIcon { icon: modelData.icon; size: 20; color: Theme.accent }
                    FText { text: modelData.label; Layout.preferredWidth: 130 }
                    FKeycaps { combo: modelData.key }
                }
            }
        }

        FButton {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Theme.sp5
            implicitHeight: 46
            text: I18n.tr("Start using Flamenco")
            icon: "rocket_launch"
            onClicked: root.finish()
        }
    }
}
