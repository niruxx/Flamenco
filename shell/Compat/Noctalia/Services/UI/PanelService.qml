pragma Singleton

import QtQuick
import Quickshell
import qs.Services as FS

// Flamenco shim for Noctalia's PanelService: context menus, the launcher, and
// plugin panels (pluginPanel1/2 are Flamenco's 3rd-party plugin panel).
Singleton {
    id: root

    property var openedPanel: null
    property var closingPanel: null
    property bool isKeybindRecording: false
    property bool overlayLauncherOpen: false
    property var registeredPanels: ({})
    property var openMenu: null

    function showContextMenu(contextMenu, anchorItem, screen, targetItem) {
        if (!contextMenu || !anchorItem)
            return;
        closeContextMenu(screen);
        // clicking anywhere else closes it
        if (contextMenu.grabFocus !== undefined)
            contextMenu.grabFocus = true;
        contextMenu.openAtItem(anchorItem, screen, targetItem);
        openMenu = contextMenu;
    }
    function closeContextMenu(screen) {
        if (openMenu && openMenu.visible)
            openMenu.close();
        openMenu = null;
    }
    function showTrayMenu() {
        return false;
    }
    function closeTrayMenu(screen) {}
    function getPopupMenuWindow(screen) {
        return null;
    }
    function registerPanel(panel) {}
    function registerPopupMenuWindow(screen, window) {}
    function unregisterPopupMenuWindow(screen) {}
    // the plugin panel host stands in for Noctalia's two plugin panel slots
    function getPanel(name, screen) {
        if (String(name).startsWith("pluginPanel"))
            return FS.ThirdParty.panelProxy;
        return null;
    }
    function hasPanel(name) {
        return String(name).startsWith("pluginPanel");
    }
    function closePanel() {
        FS.ThirdParty.closePanel();
    }
    function isLauncherOpen(screen) {
        return FS.Panels.current === "launcher";
    }
    function openLauncher(screen) {
        FS.Panels.open("launcher", screen?.name ?? "");
    }
    function toggleLauncher(screen) {
        FS.Panels.toggle("launcher", screen?.name ?? "");
    }
    function openLauncherWithSearch(screen, text) {
        FS.Panels.launcherQuery = text || "";
        FS.Panels.open("launcher", screen?.name ?? "");
    }
    function closeLauncher(screen) {
        if (FS.Panels.current === "launcher")
            FS.Panels.close();
    }
    function getLauncherSearchText(screen) {
        return "";
    }
    function setLauncherSearchText(screen, text) {
        FS.Panels.launcherQuery = text || "";
    }
    function closeOverlayLauncher() {
        closeLauncher(null);
    }
}
