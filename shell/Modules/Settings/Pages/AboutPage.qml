import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

Page {
    id: page
    title: "About"

    RowLayout {
        spacing: Theme.sp4
        Rectangle {
            width: 72; height: 72; radius: Theme.rXl
            gradient: Gradient {
                GradientStop { position: 0; color: Theme.accent }
                GradientStop { position: 1; color: Theme.accent2 }
            }
            FIcon { anchors.centerIn: parent; icon: "local_fire_department"; size: 40; fill: 1; color: Theme.onAccent }
        }
        ColumnLayout {
            FText { text: "Flamenco Shell"; font.pixelSize: Theme.fsXl; font.weight: Font.Bold }
            FText { text: "A Quickshell desktop shell for niri"; dim: true }
            FText { text: "Config: " + Paths.configDir; dim: true; font.pixelSize: Theme.fsSm; mono: true }
        }
    }

    Group {
        title: "Setup"
        SettingRow {
            title: "Run the setup again"
            subtitle: "The first-run tour: displays, look, wallpaper, sound, Bluetooth, sharing and keyring"
            icon: "assistant"
            FButton {
                text: "Open setup"
                variant: "tonal"
                onClicked: {
                    Panels.settingsOpen = false;
                    Panels.setupOpen = true;
                }
            }
        }
    }

    Group {
        title: "Health"
        SettingRow {
            title: "System check"
            subtitle: "See which dependencies are installed and get the command for the rest"
            icon: "health_and_safety"
            FButton {
                text: "Open"
                variant: "tonal"
                onClicked: Panels.settingsPage = "system"
            }
        }
    }
}
