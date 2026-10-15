pragma Singleton

import QtQuick
import Quickshell
import qs.Services as FS

// Flamenco shim for DMS's PluginService: each plugin's data and state (kept by
// Flamenco), shared variables between a plugin's parts, and its folder.
Singleton {
    id: root

    readonly property var availablePlugins: {
        const out = {};
        for (const p of FS.ThirdParty.plugins.filter(x => x.kind === "dms"))
            out[p.id] = Object.assign({}, p.manifest, { id: p.id, pluginDirectory: p.dir, loaded: FS.ThirdParty.isEnabled(p.key) });
        return out;
    }
    readonly property var loadedPlugins: {
        const out = {};
        for (const id in availablePlugins)
            if (availablePlugins[id].loaded)
                out[id] = availablePlugins[id];
        return out;
    }
    readonly property string pluginDirectory: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/flamenco/compat/dms"
    property var globalVars: ({})
    property var pluginInstances: ({})
    property var pluginDaemonInstances: ({})
    property var pluginLoadErrors: ({})

    signal pluginLoaded(string pluginId)
    signal pluginUnloaded(string pluginId)
    signal pluginLoadFailed(string pluginId, string error)
    signal pluginDataChanged(string pluginId)
    signal pluginStateChanged(string pluginId)
    signal globalVarChanged(string pluginId, string varName)
    signal requestLauncherUpdate(string pluginId)

    Connections {
        target: FS.ThirdParty
        function onDataChanged(key) {
            if (key.startsWith("dms/"))
                root.pluginDataChanged(key.slice(4));
        }
        function onStateChanged(key) {
            if (key.startsWith("dms/"))
                root.pluginStateChanged(key.slice(4));
        }
    }

    function loadPluginData(pluginId, key, defaultValue) {
        const v = FS.ThirdParty.data("dms/" + pluginId)[key];
        return v === undefined ? defaultValue : v;
    }
    function savePluginData(pluginId, key, value) {
        FS.ThirdParty.setData("dms/" + pluginId, key, value);
        return true;
    }
    function loadPluginState(pluginId, key, defaultValue) {
        const v = FS.ThirdParty.state("dms/" + pluginId)[key];
        return v === undefined ? defaultValue : v;
    }
    function savePluginState(pluginId, key, value) {
        FS.ThirdParty.setState("dms/" + pluginId, key, value);
    }
    function clearPluginState(pluginId) {
        FS.ThirdParty.clearState("dms/" + pluginId);
    }
    function getGlobalVar(pluginId, varName, defaultValue) {
        const v = (globalVars[pluginId] || {})[varName];
        return v === undefined ? defaultValue : v;
    }
    function setGlobalVar(pluginId, varName, value) {
        const all = Object.assign({}, globalVars);
        all[pluginId] = Object.assign({}, all[pluginId] || {}, { [varName]: value });
        globalVars = all;
        globalVarChanged(pluginId, varName);
    }
    function getPluginPath(pluginId) {
        return FS.ThirdParty.find("dms/" + pluginId)?.dir ?? "";
    }
    function isPluginLoaded(pluginId) {
        return FS.ThirdParty.isEnabled("dms/" + pluginId);
    }
    function getPluginVariants(pluginId) {
        return [];
    }
    function getAllPluginVariants() {
        return [];
    }
    function createPluginVariant(pluginId, name, config) {
        return null;
    }
    function removePluginVariant(pluginId, variantId) {}
    function updatePluginVariant(pluginId, variantId, config) {}
    function getLauncherPlugin(pluginId) {
        return null;
    }
    function getAllPluginTriggers() {
        return ({});
    }
    function getPluginsWithEmptyTrigger() {
        return [];
    }
    function ensureLauncherInstance(pluginId) {
        return null;
    }
    function loadPlugin(pluginId) {
        FS.ThirdParty.setEnabled("dms/" + pluginId, true);
        return true;
    }
    function unloadPlugin(pluginId) {
        FS.ThirdParty.setEnabled("dms/" + pluginId, false);
        return true;
    }
    function reloadPlugin(pluginId) {
        FS.ThirdParty.reload("dms/" + pluginId);
    }
}
