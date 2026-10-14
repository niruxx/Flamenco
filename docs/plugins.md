# Writing Flamenco plugins

A plugin can add a **bar widget**, a **launcher extension**, or both. Plugins are folders in `~/.config/flamenco/plugins/`. Each one is off until it's turned on in **Settings → Plugins**, because a plugin runs with your permissions.

The quickest start is the example, which creates a working plugin to edit:

```sh
flamenco plugins new my-plugin
```

That creates `~/.config/flamenco/plugins/my-plugin/` with a `manifest.json`, a `BarWidget.qml` and a `launcher.py`.

## manifest.json

```json
{
  "name": "My plugin",
  "version": "1.0",
  "author": "you",
  "description": "What it does",
  "homepage": "https://github.com/you/flamenco-my-plugin",
  "bar": "BarWidget.qml",
  "barLabel": "My widget",
  "launcher": { "prefix": "!", "script": "launcher.py", "hint": "! something to search" }
}
```

| Key | Meaning |
|---|---|
| `bar` | A QML file in the plugin folder: the bar widget. It appears in **Settings → Bar** as "*barLabel* (plugin)". |
| `launcher.prefix` | 1–3 characters that switch the launcher to your extension. `=`, `>`, `;`, `:` and `#` are taken by Flamenco. |
| `launcher.script` | An executable in the plugin folder (any language). Remember `chmod +x`. |
| `launcher.hint` | Shown before anything is typed after the prefix. |

The folder name is the plugin's id: lowercase letters, digits, `.`, `_` and `-`.

## Bar widgets

A bar widget is a plain QtQuick file. It can't import Flamenco's own modules, because it lives outside the shell. Instead, Flamenco sets an `api` property on it:

```qml
import QtQuick

Rectangle {
    property var api                 // set by Flamenco
    property string screenName       // the screen this bar is on
    property int barLevel: 0         // 0 = roomy … 3 = very tight bar: show less
    property bool barVisible: true   // false hides the widget and frees its space

    implicitWidth: 80
    implicitHeight: api ? api.theme.barHeight - 10 : 30
    radius: height / 2
    color: "transparent"

    Text {
        anchors.centerIn: parent
        text: api ? api.media.title : ""
        color: api ? api.theme.text : "white"
        font.family: api ? api.theme.fontFamily : ""
        font.pixelSize: api ? api.theme.fsSm : 12
    }
}
```

`api` is `null` for a moment while the widget loads, so guard with `api ? … : …`.

### What `api` has

| | |
|---|---|
| `api.theme` | Colors: `bg`, `surface`, `surfaceHigh`, `text`, `textDim`, `accent`, `onAccent`, `accent2`, `error`, `warning`, `success`, `border`. Fonts: `fontFamily`, `monoFamily`, `iconFont` (Material Symbols). Sizes: `fsXs` to `fsXxl`, `barHeight`, `rSm`, `rMd`, `rLg`. Whether the bar is vertical: `barVertical`. `dark`. |
| `api.time` | `now`, `time`, `date`, `use24h` |
| `api.media` | `title`, `artist`, `art`, `playing`, `toggle()`, `next()`, `previous()` |
| `api.audio` | `volume`, `muted`, `micMuted`, `setVolume(v)`, `toggleMute()` |
| `api.niri` | `workspaces`, `windows`, `focusedWindow`, `action(name)`; works on Hyprland too |
| `api.network` | `connected`, `ssid`, `signal`, `ethernet` |
| `api.power` | `hasBattery`, `percent`, `charging`, `profileName` |
| `api.weather` | `temp`, `unit`, `description`, `icon` |
| `api.stats` | `cpu`, `mem` (0–1), `temp` |
| `api.notifications` | `unread`, `dnd` |
| `api.settings` | This plugin's saved settings (an object). Change them with `api.setSetting(key, value)`. |
| `api.run(["cmd", "arg"])` | Starts a command, ignoring its output. |
| `api.exec(["cmd", "arg"], out => …)` | Runs a command and calls back with its output. |
| `api.notify(title, body)` | Shows a notification. |
| `api.openPanel(name)` | Opens a Flamenco panel: `launcher`, `control`, `calendar`, `notifications`, `wallpaper`, `notepad`, `assistant`, `keys`. |
| `api.dir` | The plugin's folder. Load images with `"file://" + api.dir + "/icon.png"`. |

If the QML file has an error, the bar shows a small warning icon in its place. The error is in the shell's log (`flamenco logs`).

## Launcher extensions

When the launcher's text starts with your prefix, Flamenco runs your script with what follows the prefix as its argument. That happens 150 ms after typing stops. The script prints **one JSON object per line**:

```json
{"title": "Search the web for “cats”", "subtitle": "Opens your browser", "icon": "travel_explore", "open": "https://duckduckgo.com/?q=cats"}
```

| Key | |
|---|---|
| `title`, `subtitle` | What the row shows. |
| `icon` | A [Material Symbols](https://fonts.google.com/icons) name. |
| `exec` | A shell command to run on `Enter`. |
| `copy` | Text to copy to the clipboard on `Enter`. |
| `open` | A URL or file to open with `xdg-open` on `Enter`. |

Give each result one action. Lines that aren't valid JSON are skipped.

## Sharing a plugin

Put the folder in a git repository. Others can then install it from **Settings → Plugins → Install**, or with `flamenco plugins install https://…`. A `flamenco-` prefix on the repository name is dropped from the id, so `flamenco-weather-pro` becomes `weather-pro`.

```sh
flamenco plugins list
flamenco plugins install https://github.com/you/flamenco-my-plugin
flamenco plugins remove my-plugin
```
