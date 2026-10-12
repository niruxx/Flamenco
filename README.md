# Flamenco Shell

A desktop shell for the [niri](https://github.com/YaLTeR/niri) compositor, built with [Quickshell](https://quickshell.org). It's structured like Noctalia and DMS: a QML shell plus a small `flamenco` program that launches it, talks to it over IPC, and themes your Qt and GTK applications to match.

## Features

| | |
|---|---|
| **Bar** | Floating, attached or "islands" style, top or bottom. Widgets are reorderable: launcher, niri workspaces (gliding indicator), active window, clock, media (spinning cover art), tray (native Qt menus), CPU/RAM, keyboard layout, network, Bluetooth, volume, brightness, battery, notifications, weather, power |
| **Control center** | Volume, mic and brightness sliders. Tiles for Wi-Fi, Bluetooth, DND, night light, caffeine, power profile, dark mode and wallpaper. Wi-Fi, Bluetooth and audio-device pages slide in. Media card with blurred album art |
| **Launcher** | Fuzzy app search ranked by how often you use each app. `=` calculator, `>` run command, `;` clipboard history (cliphist) |
| **Notifications** | Built-in daemon: popups with timeout bar, swipe to dismiss, actions, DND. History persists across restarts |
| **OSD** | Volume, brightness and mic popups |
| **Lock screen** | PAM auth, blurred wallpaper that clears as you unlock, media controls, auto-lock on idle, screen-off timer |
| **Power menu** | Lock, suspend, log out, restart, shut down. Keyboard navigation; destructive actions need a second press |
| **Wallpaper** | Fade, zoom, circle-reveal and wipe transitions, picker grid, auto-cycle, colors from wallpaper (matugen) |
| **Calendar** | Month view with slide transitions, 5-day weather (Open-Meteo, no API key) |
| **Dock** | Optional. Pinned and running apps, magnification, auto-hide |
| **Settings app** | Its own window (`flamenco settings`) with a page for every module. Every change applies live |
| **App theming** | Qt 5/6 (qt5ct/qt6ct palette and generated QSS stylesheet, KDE color scheme) and GTK 3/4 (libadwaita color overrides plus optional styling), with stylesheet options and custom QSS/CSS in Settings |

Eight hand-tuned palettes, each with dark and light variants: Flamenco, Breeze, Catppuccin, Rosé Pine, Nord, Tokyo Night, Gruvbox and Everforest. You can also derive the palette from your wallpaper. Palette switches cross-fade across the whole shell.

## Install

**Required:** `quickshell` (≥ 0.2, built against Qt ≥ 6.7), `niri`, `python3`. The *Material Symbols Rounded* icon font (Apache-2.0) is bundled in `shell/assets/fonts/`.

**Optional:**
- `networkmanager` (nmcli): network status and Wi-Fi
- `brightnessctl`: screen brightness
- `matugen`: colors from wallpaper
- `cliphist` + `wl-clipboard`: clipboard history in the launcher
- `gammastep`: night light
- `qt5ct` / `qt6ct`: Qt app theming
- `adw-gtk3`: themes GTK3 apps like libadwaita apps
- `power-profiles-daemon`, `upower`, `bluez`: power profiles, battery, Bluetooth

On Arch:

```sh
paru -S quickshell niri \
        networkmanager brightnessctl matugen-bin cliphist wl-clipboard gammastep \
        qt5ct qt6ct adw-gtk-theme power-profiles-daemon
```

Then:

```sh
make install            # → ~/.local/share/flamenco-shell + ~/.local/bin/flamenco
# or: make dev          # symlink this checkout (edits hot-reload)
flamenco doctor         # check dependencies
flamenco niri-config    # binds/rules to paste into ~/.config/niri/config.kdl
```

The snippet in [examples/niri-flamenco.kdl](examples/niri-flamenco.kdl) starts the shell with niri, sets `QT_QPA_PLATFORMTHEME=qt6ct`, places the wallpaper in the overview backdrop, and binds keys.

## The `flamenco` command

```
flamenco run [--fg]             start (daemonized unless --fg)
flamenco kill | restart
flamenco launcher | control | notifications | calendar | wallpapers | power
flamenco settings [page]        appearance, apps, bar, dock, wallpaper, notifications, launcher, lock, clock, about
flamenco lock
flamenco volume up|down|mute|mic-mute|set N
flamenco brightness up|down|set N
flamenco media toggle|next|previous
flamenco wallpaper [set PATH | random | next]
flamenco theme PALETTE | dark | light | toggle | list | apply-apps
flamenco apps-theme --json SPEC | --restore
flamenco ipc TARGET FUNCTION [ARGS...]
flamenco doctor [--json]
```

## Qt & GTK theming

When the palette or any option under **Settings → App Theming** changes, the shell calls `flamenco apps-theme`. That command writes:

| Toolkit | Files |
|---|---|
| Qt 5 / Qt 6 | `~/.config/qt{5,6}ct/colors/flamenco.conf` (full QPalette for active, inactive and disabled states)<br>`~/.config/qt{5,6}ct/qss/flamenco.qss` (generated stylesheet)<br>`qt{5,6}ct.conf` (palette, stylesheet, widget style, fonts, icons) |
| KDE apps | `~/.local/share/color-schemes/Flamenco.colors` and the color groups in `~/.config/kdeglobals` |
| GTK 3 / 4 | `~/.config/gtk-{3,4}.0/gtk.css` (libadwaita and classic named colors, plus optional styling)<br>`settings.ini`<br>gsettings: `color-scheme`, `accent-color`, fonts, icon and cursor themes, and `adw-gtk3` if installed |

Stylesheet options shared by both toolkits:
- Corner radius (follow the shell, or set your own)
- Button style: soft, flat or outlined
- Scrollbars: thin, overlay or classic
- Accent-colored selections and focus rings
- Surface contrast

Qt also gets a widget style choice (Fusion, Breeze or Kvantum) and a KDE color scheme toggle. Both Qt and GTK get a free-form **custom QSS / CSS** box that's appended to the generated stylesheet.

**Backups:** the first time Flamenco touches a file you wrote yourself, it backs the file up to `~/.local/state/flamenco/backup/` and records the previous gsettings values. `flamenco apps-theme --restore`, or *Restore originals* in Settings, puts everything back.

Open Qt apps pick up the new palette when restarted. GTK 4 and libadwaita apps reload `gtk.css` live.

## Layout

```
bin/flamenco                 CLI: launcher, IPC client, Qt/GTK theme generator
shell/shell.qml              root: modules + IPC handlers
shell/Commons/               Theme (tokens + motion curves), Settings (JSON), Palettes, ColorGen, Paths
shell/Services/              Niri, Audio, Brightness, Network, BluetoothState, Power, Media, Notifs,
                             Wallpapers, Weather, Apps, SystemStats, Time, Toggles, Panels, AppTheming
shell/Widgets/               F* component library (buttons, switch, slider, tiles, ripple, OverlayPanel…)
shell/Modules/               Bar, Background, ControlCenter, Launcher, Notifications, OSD, Lock,
                             Session, Calendar, WallpaperPicker, Dock, Settings
```

Settings live in `~/.config/flamenco/settings.json`. The file is watched, so hand edits apply immediately.

## TODO
Add dock options to change the top bar from top to each corner of the screen

Under app theming ensure a drop down can be used instead of typing in the theme - this should be able to select the ones installed.

Include app Indicators support

Improve the top left indicator as there's a lot of spaces between them.