pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The shell's icons from an icon theme (Settings → Appearance → UI icons): which
// file stands in for each Material Symbols name (`flamenco icons map THEME`),
// for FIcon to draw. "flamenco" (the default) keeps the built-in Material Symbols;
// a name the theme doesn't have stays Material Symbols too.
Singleton {
    id: root

    readonly property string choice: Settings.data.appearance.uiIcons || "flamenco"
    // the theme to use: the apps' one, or a chosen one
    readonly property string theme: choice === "flamenco" ? "" : choice === "apps" ? (Settings.data.apps.iconTheme || "") : choice
    property var map: ({})
    readonly property bool active: theme !== "" && Object.keys(map).length > 0
    readonly property int count: Object.keys(map).length
    property bool loading: proc.running

    onThemeChanged: load()
    Component.onCompleted: load()
    function load() {
        if (!theme) {
            map = {};
            return;
        }
        proc.running = false;
        proc.command = [Paths.bin, "icons", "map", theme];
        proc.running = true;
    }
    Process {
        id: proc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.map = JSON.parse(text);
                } catch (e) {
                    root.map = {};
                }
            }
        }
    }
}
