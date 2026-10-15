# Noctalia and DMS plugins in Flamenco

Flamenco can run plugins made for **Noctalia Shell 4** and **DankMaterialShell (DMS) 1.x**. Find them in **Settings → Plugins (3rd party)**:

- **Catalogs:** browse Noctalia's plugin repository and DMS's plugin registry, then install with one click.
- **From an address:** install from a git URL or a folder.
- **Status:** each installed plugin shows whether it should work fully, partly, or not at all, and why.
- **Settings:** a plugin's own settings page opens right there.

Like Flamenco's own plugins, these run with your permissions. Only turn on ones you trust.

## What works

| | Noctalia 4 | DMS 1.x |
|---|---|---|
| Bar widgets | ✓ | ✓ (with their popouts) |
| Panels | ✓ | ✓ (popouts) |
| Plugin settings | ✓ (Save button) | ✓ (saved as you change them) |
| Background parts | ✓ `Main.qml` | ✓ daemons |
| Context menus, tooltips, toasts | ✓ (toasts become notifications) | ✓ |
| Desktop widgets | not yet | not yet |
| Control center buttons | not yet | not yet |
| Launcher providers or extensions | not yet | not yet |

Some plugins also use parts of their shell that Flamenco doesn't have:

- DMS's own backend (`DMSService` and D-Bus through `dms`).
- Noctalia's desktop widget framework.
- DMS 1.7's newer `qs.DCommon` modules.

The check names these, and the plugin is marked *partly works* or *won't run*.

**Noctalia 5** replaced QML plugins with Luau scripts, which Flamenco can't run. The QML plugins in [noctalia-plugins](https://github.com/noctalia-dev/noctalia-plugins) are the Noctalia 4 kind.

Bar widgets from turned-on plugins appear in **Settings → Bar → Widgets** as "*name* (Noctalia)" or "*name* (DMS)".

## From a terminal

```sh
flamenco compat catalog noctalia            # or dms; --refresh to fetch it again
flamenco compat install noctalia:pomodoro
flamenco compat install dms:dankPomodoroTimer
flamenco compat install https://github.com/someone/dms-plugins#myPlugin   # #ID when a repository has several
flamenco compat install ~/src/my-plugin
flamenco compat list                         # each plugin, and what it uses that Flamenco doesn't have
flamenco compat update all
flamenco compat remove noctalia/pomodoro
```

## Where things are

| | |
|---|---|
| `~/.config/flamenco/compat/<kind>/<id>/` | the plugin as installed. Edit it here, then press Reload in Settings. |
| `~/.cache/flamenco/compat/<kind>/<id>/` | the copy the shell loads, with its imports pointed at the compatibility layer |
| `~/.config/flamenco/compat/settings.json` | each plugin's settings |
| `~/.local/state/flamenco/compat-state.json` | DMS plugins' saved state |
| `~/.cache/flamenco/compat-repos/` | downloaded catalogs and plugin repositories |

## How it works

A Noctalia plugin starts with `import qs.Commons` and `import qs.Widgets`, and uses Noctalia's `Color`, `Style`, `NText` and so on. A DMS plugin imports `qs.Common` and `qs.Widgets` for `Theme`, `StyledText`, `DankIcon` and `PluginComponent`. Those modules are each shell's own code, so Flamenco provides its own versions of them in `shell/Compat/`:

- **Copied as they are:** widgets, both shells' plugin settings components, Noctalia's Tabler icon font, and DMS's file browser. Both projects are MIT licensed, and the licences are kept next to the copies.
- **Written for Flamenco:** the parts that are about the shell itself:
  - **Colours and sizes:** Noctalia's `Color` and `Settings` and DMS's `Theme`, taken from Flamenco's palette, fonts, bar height and motion settings.
  - **Services:** bar, panels, toasts, battery, weather, compositor, audio, system stats and so on, backed by Flamenco's.
  - **Plugin roots:** DMS's `PluginComponent` and pill, and Noctalia's `pluginApi`.

When a plugin is installed, Flamenco copies it and rewrites `import qs.X` to `import qs.Compat.Noctalia.X` (or `.Dms.X`). The shell then loads the copy.

### Updating the copied parts (maintainers)

`tools/compat-vendor.py` copies the files and applies its small patches. Don't edit the copied files by hand: each `VENDORED` file lists which files are copies. Everything else in `shell/Compat/` is Flamenco's and is never overwritten.

```sh
git clone -b legacy-v4 https://github.com/noctalia-dev/noctalia-shell /tmp/noctalia
git clone --recurse-submodules -b v1.6.3 https://github.com/AvengeMedia/DankMaterialShell /tmp/dms
tools/compat-vendor.py noctalia /tmp/noctalia
tools/compat-vendor.py dms /tmp/dms
tools/compat-vendor.py --check    # types and singletons nothing provides
tools/qmlcheck.py
```
