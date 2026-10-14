import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services

// What a plugin's bar widget gets as `api` (docs/plugins.md). Plugin files live
// outside the shell, so instead of importing its modules they use this object.
QtObject {
    id: api

    property string pluginId: ""
    readonly property string dir: (Plugins.find(pluginId)?.dir) ?? ""

    // look and data
    readonly property var theme: Theme
    readonly property var time: Time
    readonly property var media: Media
    readonly property var audio: Audio
    readonly property var niri: Niri
    readonly property var network: Network
    readonly property var power: Power
    readonly property var weather: Weather
    readonly property var stats: SystemStats
    readonly property var notifications: Notifs

    // this plugin's own settings, kept in settings.json
    readonly property var settings: (Settings.data.plugins.config || {})[pluginId] ?? ({})
    function setSetting(key, value) {
        const all = Object.assign({}, Settings.data.plugins.config || {});
        all[pluginId] = Object.assign({}, all[pluginId] || {}, { [key]: value });
        Settings.data.plugins.config = all;
    }

    // run a command (no output), or run it and get its output: exec(["date"], out => …)
    function run(cmd) {
        Quickshell.execDetached(cmd);
    }
    function exec(cmd, callback) {
        const p = runner.createObject(api, { command: cmd, callback: callback });
        p.running = true;
    }
    function notify(title, body) {
        Quickshell.execDetached(["notify-send", "-a", Plugins.find(pluginId)?.name ?? pluginId, title, body || ""]);
    }
    // open a Flamenco panel: launcher, control, calendar, notifications, wallpaper, notepad, assistant…
    function openPanel(name, screenName) {
        Panels.toggle(name, screenName || "");
    }

    property Component runner: Component {
        Process {
            id: proc
            property var callback: null
            stdout: StdioCollector {
                onStreamFinished: {
                    if (proc.callback)
                        proc.callback(text);
                    proc.destroy();
                }
            }
        }
    }
}
