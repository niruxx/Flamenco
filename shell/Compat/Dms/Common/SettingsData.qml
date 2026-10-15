pragma Singleton

import QtQuick
import Quickshell
import qs.Commons as F
import qs.Services as FS

// Flamenco shim for DMS's SettingsData: plugin settings (kept by Flamenco, per
// plugin) and the handful of shell settings plugins read, from Flamenco's.
Singleton {
    id: root

    enum Position { Top, Bottom, Left, Right }
    enum AnimationSpeed { None, Short, Medium, Long, Custom }

    readonly property var pluginSettings: FS.ThirdParty.dmsAll
    readonly property bool use24HourClock: F.Settings.data.general.use24h
    readonly property bool useFahrenheit: !!F.Settings.data.weather.fahrenheit
    readonly property string windSpeedUnit: useFahrenheit ? "mph" : "kmh"
    readonly property int animationSpeed: SettingsData.AnimationSpeed.Medium
    readonly property bool waveProgressEnabled: true
    readonly property bool m3ElevationEnabled: true
    readonly property bool frameEnabled: false
    readonly property real frameBarSize: 0
    readonly property bool dockEnabled: F.Settings.data.dock.enabled
    readonly property int dockPosition: ({ bottom: 1, left: 2, right: 3 })[F.Settings.data.dock.position] ?? 1
    readonly property real dockIconSize: F.Settings.data.dock.iconSize
    readonly property real dockSpacing: F.Settings.data.dock.spacing
    readonly property real dockMargin: F.Settings.data.dock.margin
    readonly property real dockBottomGap: 0
    readonly property bool dockBorderEnabled: F.Settings.data.dock.border
    readonly property real dockBorderThickness: 1
    readonly property var barConfigs: [{ id: "default", position: ({ top: 0, bottom: 1, left: 2, right: 3 })[F.Settings.data.bar.position] ?? 0, enabled: true, widgetPadding: 8, fontScale: 1, iconScale: 1 }]
    readonly property var screenPreferences: ({})
    readonly property var desktopWidgetInstances: []
    readonly property string notificationFocusedMonitor: ""
    readonly property bool trayPopupSingleLine: false

    function getPluginSettingsForPlugin(pluginId) {
        return FS.ThirdParty.data("dms/" + pluginId);
    }
    function getPluginSetting(pluginId, key, defaultValue) {
        const v = FS.ThirdParty.data("dms/" + pluginId)[key];
        return v === undefined ? defaultValue : v;
    }
    function setPluginSetting(pluginId, key, value) {
        FS.ThirdParty.setData("dms/" + pluginId, key, value);
    }
    function removePluginSettings(pluginId) {
        FS.ThirdParty.clearData("dms/" + pluginId);
    }
    function getBuiltInPluginSetting(pluginId, key, defaultValue) {
        return defaultValue;
    }
    function setBuiltInPluginSetting(pluginId, key, value) {}
    function set(key, value) {}
    function getScreenDisplayName(screen) {
        return screen?.name ?? String(screen ?? "");
    }
    // where a popout opens for a bar widget (x: its center along the bar)
    function getPopupTriggerPosition(globalPos, screen, barThickness, widgetWidth) {
        return { x: (globalPos?.x ?? 0) + (widgetWidth ?? 0) / 2, y: barThickness ?? F.Theme.barHeight, width: widgetWidth ?? 0 };
    }
    function updateDesktopWidgetInstance(id, changes) {}
    function updateDesktopWidgetInstanceConfig(id, changes) {}
}
