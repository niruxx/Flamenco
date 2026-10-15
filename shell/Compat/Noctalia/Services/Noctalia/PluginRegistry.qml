pragma Singleton

import QtQuick
import Quickshell
import qs.Services as FS

// Flamenco shim for Noctalia's PluginRegistry.
Singleton {
    readonly property string pluginsDir: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/flamenco/compat/noctalia"
    readonly property var pluginSources: [{ name: "Noctalia Plugins", url: "https://github.com/noctalia-dev/noctalia-plugins", enabled: true }]
    readonly property var pluginLoadVersions: ({})

    function getPluginManifest(pluginId) {
        return FS.ThirdParty.find("noctalia/" + pluginId)?.manifest ?? null;
    }
    function getPluginDir(pluginId) {
        return FS.ThirdParty.find("noctalia/" + pluginId)?.dir ?? "";
    }
    function getAllInstalledPluginIds() {
        return FS.ThirdParty.plugins.filter(p => p.kind === "noctalia").map(p => p.id);
    }
    function isPluginEnabled(pluginId) {
        return FS.ThirdParty.isEnabled("noctalia/" + pluginId);
    }
    function isMainSource(url) {
        return true;
    }
    function parseCompositeKey(key) {
        return { pluginId: String(key).split(":").pop(), sourceHash: "" };
    }
    function getSourceNameByHash(hash) {
        return "Noctalia Plugins";
    }
    function getPluginSourceUrl(pluginId) {
        return "https://github.com/noctalia-dev/noctalia-plugins";
    }
    function addPluginSource(name, url) {}
    function removePluginSource(url) {}
    function setSourceEnabled(url, enabled) {}
}
