pragma Singleton

import QtQuick
import Quickshell

// Which popout is open, and on which screen.
Singleton {
    id: root

    property string current: ""
    property string screen: ""
    property bool settingsOpen: false
    property bool setupOpen: false
    property string settingsPage: "appearance"
    // dashboard (clock popout): tab requested by the next open, and the tab showing now
    property string dashboardTab: ""
    property string dashboardShown: ""

    // control-center sub page: "" (main) | wifi | bluetooth | audio | mic
    property string controlDetail: ""

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
        if (current === name && screen === sc) {
            close();
        } else {
            if (name === "control")
                controlDetail = "";
            open(name, sc);
        }
    }

    // Open the dashboard on a tab; toggles shut if that tab is already showing.
    function openDashboard(tab, s) {
        const sc = targetScreen(s);
        if (current === "calendar" && screen === sc && dashboardShown === tab) {
            close();
            return;
        }
        dashboardTab = tab;
        open("calendar", sc);
    }

    // Open the control center straight on a sub page (or toggle it shut if
    // that exact page is already showing).
    function openControl(detail, s) {
        const sc = targetScreen(s);
        if (current === "control" && screen === sc && controlDetail === detail) {
            close();
            return;
        }
        controlDetail = detail;
        open("control", sc);
    }

    function openSettings(page) {
        if (page)
            settingsPage = page;
        settingsOpen = true;
        close();
    }
}
