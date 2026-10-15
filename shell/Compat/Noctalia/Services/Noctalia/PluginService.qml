pragma Singleton

import QtQuick
import Quickshell
import qs.Services as FS

// Flamenco shim for Noctalia's PluginService: what a plugin may ask about plugins.
// Installing and updating happen in Settings → Plugins (3rd party).
Singleton {
    readonly property var availablePlugins: FS.ThirdParty.plugins.filter(p => p.kind === "noctalia").map(p => ({ id: p.id, name: p.name, version: p.version, description: p.description, author: p.author, enabled: FS.ThirdParty.isEnabled(p.key), downloaded: true }))
    readonly property var pluginUpdates: ({})
    readonly property var pluginUpdatesPending: ({})
    readonly property var installingPlugins: ({})
    readonly property var activeFetches: ({})
    readonly property bool pluginsFullyLoaded: true
    readonly property bool initialized: true
    signal pluginLoaded(string pluginId)
    signal availablePluginsUpdated

    function getPluginAPI(pluginId) {
        return FS.ThirdParty.noctaliaApi(pluginId);
    }
    function isPluginLoaded(pluginId) {
        return FS.ThirdParty.isEnabled("noctalia/" + pluginId);
    }
    function hasPluginError(pluginId) {
        return !!FS.ThirdParty.errors["noctalia/" + pluginId];
    }
    function getPluginError(pluginId) {
        return FS.ThirdParty.errors["noctalia/" + pluginId] ?? null;
    }
    function enablePlugin(key) {
        FS.ThirdParty.setEnabled("noctalia/" + String(key).split(":").pop(), true);
    }
    function disablePlugin(key) {
        FS.ThirdParty.setEnabled("noctalia/" + String(key).split(":").pop(), false);
    }
    function openPluginPanel(pluginId, screen, buttonItem) {
        return FS.ThirdParty.openPanel("noctalia/" + pluginId, screen?.name ?? "", buttonItem);
    }
    function togglePluginPanel(pluginId, screen, buttonItem) {
        return FS.ThirdParty.togglePanel("noctalia/" + pluginId, screen?.name ?? "", buttonItem);
    }
    function refreshAvailablePlugins() {
        FS.ThirdParty.refresh();
    }
    function checkForUpdates() {}
    function updatePlugin(pluginId, callback) {}
    function installPlugin(meta, skip, callback) {}
    function uninstallPlugin(key, callback) {}
    function isPluginHotReloadEnabled(pluginId) {
        return false;
    }
    function togglePluginHotReload(pluginId) {}
}
