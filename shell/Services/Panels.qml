pragma Singleton

import QtQuick
import Quickshell

// Which popout is open, and on which screen.
Singleton {
    id: root

    property string current: ""
    property string screen: ""
    property bool settingsOpen: false
    property string settingsPage: "appearance"

    function targetScreen(s) {
        return s || Niri.focusedOutput || (Quickshell.screens[0]?.name ?? "");
    }

    function open(name, s) {
        screen = targetScreen(s);
        current = name;
    }

    function close() {
        current = "";
    }

    function toggle(name, s) {
        const sc = targetScreen(s);
        if (current === name && screen === sc)
            close();
        else
            open(name, sc);
    }

    function openSettings(page) {
        if (page)
            settingsPage = page;
        settingsOpen = true;
        close();
    }
}
