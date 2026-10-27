pragma Singleton

import QtQuick
import Quickshell
import qs.Commons

// Which popout is open, and on which screen.
Singleton {
    id: root

    property string current: ""
    property string screen: ""
    property bool settingsOpen: false
    property bool setupOpen: false
    property string settingsPage: "appearance"
    property bool whatsNew: false
    property string browserUrl: ""            // a link waiting for "which browser?" (Modules/Extras/BrowserPicker)
    property string qr: ""                    // the QR window: "@wifi", or text (Modules/Extras/QrPanel)             // the "What's new" window (Modules/Extras/WhatsNew)
    // Settings search: the row or section to scroll to and flash on the page
    // just opened (matched by its title); findSeq makes the same one re-trigger
    property string settingsFind: ""
    property int findSeq: 0

    function findSetting(page, title) {
        settingsPage = page;
        settingsFind = title;
        findSeq++;
        findClear.restart();
    }

    Timer {
        id: findClear
        interval: 3000
        onTriggered: root.settingsFind = ""
    }
    // dashboard (clock popout): tab requested by the next open, and the tab showing now
    property string dashboardTab: ""
    property string dashboardShown: ""

    // control-center sub page: "" (main) | wifi | bluetooth | audio | mic
    property string controlDetail: ""
    // the bar hidden by hand (`flamenco bar toggle`, a shortcut); until shown again or a restart
    property bool barHidden: false
    // desktop widget editing (sidebar + arranging), on Panels.screen
    property bool widgetsEdit: false
    // text the launcher opens with (`flamenco launcher openWith ":"`)
    property string launcherQuery: ""

    function editWidgets(s) {
        close();
        screen = targetScreen(s);
        widgetsEdit = true;
    }

    function targetScreen(s) {
        return s || Niri.focusedOutput || (Quickshell.screens[0]?.name ?? "");
    }

    // Where the open panel came from: the bar section of the widget that opened
    // it (start | center | end, "" = the panel's usual spot), and that widget's
    // center along the bar, so a panel opens on the same side as its widget.
    property string side: ""
    property real anchor: -1

    function noteOrigin(from) {
        side = "";
        anchor = -1;
        if (!from)
            return;
        let p = from;
        while (p && p.barSide === undefined)
            p = p.parent;
        if (!p || !p.barSide)
            return;
        side = p.barSide;
        const c = from.mapToItem(null, from.width / 2, from.height / 2);
        anchor = Theme.barVertical ? c.y : c.x;
    }

    // fuzzel as the launcher (Settings → Launcher): it opens instead of the shell's panel
    function external(name) {
        if (name === "launcher" && Fuzzel.on && Fuzzel.found) {
            close();
            Fuzzel.toggle();
            return true;
        }
        return false;
    }

    function open(name, s, from) {
        if (external(name))
            return;
        widgetsEdit = false;
        noteOrigin(from);
        screen = targetScreen(s);
        current = name;
    }

    function close() {
        current = "";
    }

    function toggle(name, s, from) {
        if (external(name))
            return;
        const sc = targetScreen(s);
        if (current === name && screen === sc) {
            close();
        } else {
            if (name === "control")
                controlDetail = "";
            open(name, sc, from);
        }
    }

    // Open the dashboard on a tab; toggles shut if that tab is already showing.
    function openDashboard(tab, s, from) {
        const sc = targetScreen(s);
        if (current === "calendar" && screen === sc && dashboardShown === tab) {
            close();
            return;
        }
        dashboardTab = tab;
        open("calendar", sc, from);
    }

    // Open the control center straight on a sub page (or toggle it shut if
    // that exact page is already showing).
    function openControl(detail, s, from) {
        const sc = targetScreen(s);
        if (current === "control" && screen === sc && controlDetail === detail) {
            close();
            return;
        }
        controlDetail = detail;
        open("control", sc, from);
    }

    function openSettings(page) {
        if (page)
            settingsPage = page;
        settingsOpen = true;
        close();
    }
}
