pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons as F
import qs.Services as FS

// Flamenco shim for Noctalia's Settings: its defaults (Assets/settings-default.json),
// with what Flamenco already decides (bar position, fonts, dark mode, weather units…)
// filled in from Flamenco's own settings. Read-only: plugins keep their own settings
// through pluginApi, which Flamenco stores.
Singleton {
    id: root

    readonly property string configDir: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/flamenco/compat/noctalia/"
    readonly property string cacheDir: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/flamenco/noctalia/"
    readonly property string settingsFile: configDir + "settings.json"
    readonly property bool isDebug: false
    readonly property bool isLoaded: true
    property bool shouldOpenSetupWizard: false

    readonly property var defaults: {
        try {
            return JSON.parse(defaultsFile.text());
        } catch (e) {
            return {};
        }
    }
    readonly property var data: build(defaults)

    function build(base) {
        const d = JSON.parse(JSON.stringify(base || {}));
        const sect = k => (d[k] = d[k] || {});
        const fs = F.Settings.data;
        const g = sect("general");
        g.scaleRatio = F.Theme.scale;
        g.radiusRatio = F.Theme.round;
        g.iRadiusRatio = F.Theme.round;
        g.boxRadiusRatio = F.Theme.round;
        g.screenRadiusRatio = 1;
        const ms = F.Theme.dur(1000);
        g.animationDisabled = ms <= 0;
        g.animationSpeed = ms > 0 ? 1000 / ms : 1;
        g.shadowOffsetX = g.shadowOffsetX ?? 0;
        g.shadowOffsetY = g.shadowOffsetY ?? 3;
        const ui = sect("ui");
        ui.fontDefault = F.Theme.fontFamily;
        ui.fontFixed = F.Theme.monoFamily;
        ui.fontDefaultScale = 1;
        ui.fontFixedScale = 1;
        ui.panelBackgroundOpacity = fs.appearance.panelOpacity ?? 1;
        ui.translucentWidgets = false;
        ui.tooltipsEnabled = true;
        ui.boxBorderEnabled = true;
        const bar = sect("bar");
        bar.position = fs.bar.position;
        // capsule = Flamenco's chip size (bar height - 10), see the patched Style.qml
        bar.density = "comfortable";
        bar.showCapsule = false;
        bar.showOutline = false;
        bar.capsuleOpacity = 1;
        bar.fontScale = 1;
        bar.backgroundOpacity = fs.appearance.panelOpacity ?? 1;
        bar.screenOverrides = [];
        const cs = sect("colorSchemes");
        cs.darkMode = F.Theme.dark;
        cs.useWallpaperColors = fs.appearance.palette === "wallpaper";
        const loc = sect("location");
        loc.name = FS.Weather.place || fs.weather.city || "";
        loc.useFahrenheit = !!fs.weather.fahrenheit;
        loc.use12hourFormat = !FS.Time.use24h;
        loc.weatherEnabled = true;
        const al = sect("appLauncher");
        al.terminalCommand = (fs.general.terminal || "kitty") + " -e";
        return d;
    }

    function preprocessPath(path) {
        if (typeof path !== "string" || path === "")
            return path;
        if (path.startsWith("~/"))
            return Quickshell.env("HOME") + path.substring(1);
        return path === "~" ? Quickshell.env("HOME") : path;
    }
    function ensureTrailingSlash(path) {
        return path.endsWith("/") ? path : path + "/";
    }
    function getDefaultValue(path) {
        let cur = defaults;
        for (const p of String(path).split(".")) {
            if (cur === undefined || cur === null)
                return undefined;
            cur = cur[p];
        }
        return cur;
    }
    function isValueChanged(path, currentValue) {
        const dv = getDefaultValue(path);
        if (dv === undefined)
            return false;
        if (typeof currentValue === "object" && typeof dv === "object")
            return JSON.stringify(currentValue) !== JSON.stringify(dv);
        return currentValue !== dv;
    }
    function formatDefaultValueForTooltip(path) {
        const dv = getDefaultValue(path);
        if (dv === undefined)
            return "";
        if (typeof dv === "string")
            return dv === "" ? "(empty)" : dv;
        if (Array.isArray(dv))
            return dv.length === 0 ? "(empty)" : "[" + dv.length + " items]";
        return typeof dv === "object" ? "(object)" : String(dv);
    }
    // one bar everywhere in Flamenco (per-screen layouts share its position)
    function getBarPositionForScreen(screenName) {
        return data.bar.position;
    }
    function getBarDensityForScreen(screenName) {
        return data.bar.density;
    }
    function getBarDisplayModeForScreen(screenName) {
        return "always_visible";
    }
    function getBarWidgetsForScreen(screenName) {
        return { left: [], center: [], right: [] };
    }
    function isScreenOverrideEnabled(screenName) {
        return false;
    }
    function hasScreenOverride(screenName, property) {
        return false;
    }
    function getScreenOverrideEntry(screenName) {
        return null;
    }
    function setScreenOverride(screenName, property, value) {}
    function clearScreenOverride(screenName, property) {}
    function saveImmediate() {}

    FileView {
        id: defaultsFile
        path: Quickshell.shellDir + "/Compat/Noctalia/Assets/settings-default.json"
        blockLoading: true
        printErrors: false
    }
}
