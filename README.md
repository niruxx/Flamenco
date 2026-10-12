# Flamenco Shell

A desktop shell for the [niri](https://github.com/YaLTeR/niri) compositor, built with [Quickshell](https://quickshell.org). It's structured like Noctalia and DMS: a QML shell plus a small `flamenco` program that launches it, talks to it over IPC, and themes your Qt and GTK applications to match.

- [Screenshots](#screenshots)
- [Features](#features)
- [Getting started](#getting-started)
- [Using the shell](#using-the-shell)
- [Wallpapers](#wallpapers)
- [Themes](#themes)
- [Troubleshooting](#troubleshooting)
- [Reference](#reference)

## TODO
Alternative Display Manager Support
Full Feature Parity
Quality of Life Improvements
First Time Run Setup Screen (dms checker)

## Screenshots

![Desktop](docs/screenshots/desktop.png)

| | |
|---|---|
| ![Launcher](docs/screenshots/launcher.png)<br>**Launcher** | ![Control center](docs/screenshots/control-center.png)<br>**Control center** |
| ![Notification center](docs/screenshots/notification-center.png)<br>**Notification center** | ![Notification popups](docs/screenshots/notification-popups.png)<br>**Notification popups** |
| ![Calendar](docs/screenshots/calendar.png)<br>**Calendar & weather** | ![Wallpaper picker](docs/screenshots/wallpaper-picker.png)<br>**Wallpaper picker** |
| ![Power menu](docs/screenshots/power-menu.png)<br>**Power menu** | ![Control center, light](docs/screenshots/control-center-light.png)<br>**Light mode** |
| ![Settings: appearance](docs/screenshots/settings-appearance.png)<br>**Settings → Appearance** | ![Settings: app theming](docs/screenshots/settings-app-theming.png)<br>**Settings → App Theming** |
| ![Settings: bar](docs/screenshots/settings-bar.png)<br>**Settings → Bar** | |

**Palettes**

| | |
|---|---|
| ![Catppuccin](docs/screenshots/palette-catppuccin.png)<br>Catppuccin | ![Rosé Pine](docs/screenshots/palette-rosepine.png)<br>Rosé Pine |
| ![Nord](docs/screenshots/palette-nord.png)<br>Nord | ![Gruvbox](docs/screenshots/palette-gruvbox.png)<br>Gruvbox |

To regenerate these, run `tools/screenshots.sh` inside a niri session with the shell running (needs `grim`).

## Features

| | |
|---|---|
| **Bar** | Floating, attached or "islands" style, on any screen edge (left/right give a vertical bar). Widgets are reorderable: launcher, niri workspaces (compact gliding indicator), active window, clock, media (spinning cover art), system tray, CPU/RAM, keyboard layout, network, Bluetooth, volume, brightness, battery, notifications, weather, power |
| **App indicators** | StatusNotifierItem / libappindicator tray with themed menus (submenus, check/radio items), tooltips, attention pulse, optional hiding of passive icons, overflow drawer. Native Qt menus available as a setting |
| **Control center** | Volume, mic and brightness sliders. Tiles for Wi-Fi, Bluetooth, DND, night light, caffeine, power profile, dark mode and wallpaper. Wi-Fi, Bluetooth and audio-device pages slide in. Media card with blurred album art |
| **Launcher** | Fuzzy app search ranked by how often you use each app. `=` calculator, `>` run command, `;` clipboard history (cliphist) |
| **Notifications** | Built-in daemon: popups with timeout bar, swipe to dismiss, actions, DND. History persists across restarts |
| **OSD** | Volume, brightness and mic popups |
| **Lock screen** | PAM auth, blurred wallpaper that clears as you unlock, media controls, auto-lock on idle, screen-off timer. Can run any **SDDM greeter theme** as the lock screen, or hand off to a command such as `hyprlock` |
| **Power menu** | Lock, suspend, log out, restart, shut down. Keyboard navigation; destructive actions need a second press |
| **Wallpaper** | Fade, zoom, circle-reveal and wipe transitions, picker grid, auto-cycle, colors from wallpaper (matugen) |
| **Calendar** | Month view with slide transitions, 5-day weather (Open-Meteo, no API key) |
| **Dock** | Optional. Pinned and running apps, magnification, auto-hide |
| **Settings app** | Its own window (`flamenco settings`) with a page for every module. Every change applies live |
| **App theming** | Qt 5/6 (qt5ct/qt6ct palette and generated QSS stylesheet, KDE color scheme) and GTK 3/4 (libadwaita color overrides plus optional styling), with stylesheet options and custom QSS/CSS in Settings |

Eight hand-tuned palettes, each with dark and light variants: Flamenco, Breeze, Catppuccin, Rosé Pine, Nord, Tokyo Night, Gruvbox and Everforest. You can also derive the palette from your wallpaper. Palette switches cross-fade across the whole shell.

## Getting started

### 1. Install dependencies

**Required:** `quickshell` (developed against 0.3.2 with Qt 6.12; 0.2 or newer should work), `niri`, `python3`. The *Material Symbols Rounded* icon font (Apache-2.0) is bundled in `shell/assets/fonts/`, so you don't need to install it.

**Optional** (each enables one feature):

| Package | Enables |
|---|---|
| `networkmanager` | network status and Wi-Fi control |
| `brightnessctl` | screen brightness slider and OSD |
| `matugen` | the "From wallpaper" palette |
| `cliphist` + `wl-clipboard` | clipboard history in the launcher, copying calculator results |
| `gammastep` | night light |
| `qt5ct`, `qt6ct` | theming Qt apps |
| `adw-gtk-theme` | GTK 3 apps that look like libadwaita apps |
| `qt6-imageformats` | `.webp` wallpapers |
| `power-profiles-daemon`, `upower`, `bluez` | power profile tile, battery, Bluetooth |

On Arch:

```sh
paru -S quickshell niri \
        networkmanager brightnessctl matugen-bin cliphist wl-clipboard gammastep \
        qt5ct qt6ct adw-gtk-theme qt6-imageformats power-profiles-daemon
```

### 2. Install Flamenco

Pick one:

```sh
# Arch package (built from this checkout)
cd packaging/arch && makepkg -si

# or install to ~/.local without a package
make install            # → ~/.local/share/flamenco-shell + ~/.local/bin/flamenco

# or run straight from this checkout while developing (edits hot-reload)
make dev
```

Then check that everything is found:

```sh
flamenco doctor
```

### 3. Configure niri

Run `flamenco niri-config` to print the snippet, which is also saved in [examples/niri-flamenco.kdl](examples/niri-flamenco.kdl). It has two parts:

1. **Top level** of `~/.config/niri/config.kdl`:
   - start the shell with `spawn-at-startup "flamenco" "run"`
   - set `QT_QPA_PLATFORMTHEME=qt6ct`
   - show the wallpaper behind niri's overview
   - make the settings window float
2. **Key bindings.** Paste these lines *inside your existing* `binds { }` block. niri allows only one `binds` block, so don't add a second one. Leave out any key you already use.

**Run only one shell.** If your config starts another shell or wallpaper program (`dms run`, `waybar`, `swaybg`, `swww`, …), remove or comment out that line. Two shells fight over notifications, the bar area and the wallpaper.

Check the config with `niri validate`, then log out and back in, or start the shell by hand:

```sh
flamenco run --fg       # foreground, prints errors; Ctrl+C to stop
flamenco run            # background
flamenco restart        # after an upgrade
```

## Using the shell

### Keybindings

These come from the niri snippet; change them in your niri config.

| Key | Action |
|---|---|
| `Mod+Space` | App launcher |
| `Mod+A` | Control center |
| `Mod+N` | Notification center |
| `Mod+W` | Wallpaper picker |
| `Mod+Comma` | Settings |
| `Mod+Escape` | Power menu |
| `Super+Alt+L` | Lock screen |

Every panel closes with `Esc` or a click outside it.

**Flamenco Settings** is also a regular app. Find it in the launcher, or any other app launcher, under that name. It starts the shell first if it isn't running.

### Bar

| Widget | Click | Other |
|---|---|---|
| Launcher (apps icon) | open launcher | |
| Workspaces | go to that workspace | scroll to switch workspaces |
| Clock | calendar and weather | |
| Media | control center | middle-click play/pause, right-click next track |
| System tray | activate the app | right-click app menu, middle-click secondary action, scroll is passed to the app, hover for tooltip |
| CPU / RAM | opens `btop` in your terminal | |
| Keyboard layout | next layout | only shown with more than one layout |
| Network | control center, Wi-Fi page | |
| Bluetooth | control center, devices page | |
| Battery | control center | |
| Volume | control center, output-device page | scroll to change volume, middle-click to mute |
| Brightness | control center | scroll to change brightness |
| Notifications (bell) | notification center | right-click toggles Do Not Disturb |
| Weather | calendar and weather | |
| Quick settings (menu icon) | control center | |
| Power | power menu | |

Rearrange, add or remove widgets in **Settings → Bar**. The same page sets the bar's position, style and thickness, the workspace indicator style, and the tray options. Widgets with nothing to show, like battery on a desktop, hide themselves and leave no gap.

### Launcher

Start typing to search apps. Results are ranked by match quality and how often you launch each app.

| Prefix | Mode |
|---|---|
| *(none)* | apps |
| `=` | calculator, e.g. `= 2^10 / 3`; `Enter` copies the result |
| `>` | run a shell command; the second result runs it in your terminal |
| `;` | search clipboard history; `Enter` copies the entry back |

Move with `↑`/`↓` (or `Ctrl+N`/`Ctrl+P`), launch with `Enter`, close with `Esc`.

### Control center

- **Sliders:** volume, microphone, brightness. Click a slider's icon to mute; click `›` to choose the output or input device.
- **Tiles:** click to toggle. Wi-Fi and Bluetooth have a `›` arrow that opens a list of networks or devices. Click a secured network to enter its password.
- **Header:** settings, lock and power buttons.
- **Media card:** appears while something is playing. Click the progress bar to seek; use the swap button to switch between players.

### Notifications

Popups appear in the corner chosen in **Settings → Notifications**.
- Hovering a popup pauses its timer.
- Drag a popup sideways to dismiss it.
- Action buttons appear when the app provides them.

Past notifications stay in the notification center (`Mod+N`). It also has buttons to toggle Do Not Disturb and to clear everything. With DND on, only critical notifications pop up.

### Lock screen and power menu

- **Lock** (`Super+Alt+L`, or automatically after the idle time in **Settings → Lock & Idle**): type your password and press `Enter`. `Esc` clears what you typed. See [Lock screen options](#lock-screen-options) to use an SDDM theme or another locker instead.
- **Power menu** (`Mod+Escape`): choose with the arrow keys or `h`/`l` and press `Enter`. Log out, restart and shut down need a second press to confirm. Suspend locks the screen first.

### Lock screen options

**Settings → Lock & Idle → Lock screen** picks what locks your session. This applies everywhere: the idle timeout, `Super+Alt+L`, `flamenco lock`, and the power menu.

| Option | What it does |
|---|---|
| **Flamenco** | The built-in lock screen (the default) |
| **SDDM theme** | Runs an SDDM login theme as your lock screen |
| **Command** | Runs another locker instead, e.g. `hyprlock` or `swaylock -f` |

**Using an SDDM theme.** SDDM itself is a login manager and can't lock a running niri session. Its themes are plain QML, though, so Flamenco loads them inside its own secure lock.
- **Picking a theme:** choose one from the dropdown, which lists `/usr/share/sddm/themes` and `~/.local/share/sddm/themes`. For a theme you've downloaded but not installed, put its folder in **Theme folder**.
- **Logging in:** the theme's login form checks your password through PAM, just like the built-in lock. Its power buttons work too.
- **Compatibility:** themes made for Qt 6 (`QtVersion=6` in `metadata.desktop`) work best. Qt 5-only themes are labeled; some load, and others fail on missing Qt 5 modules.
- **Safety net:** if a theme fails to load, the built-in lock takes over automatically. If a theme loads but won't let you in, press **Ctrl+Alt+Shift+L** on the lock screen to switch to the built-in lock.

Use **Lock now** on the same page to preview your choice.

### Dock

The dock is off by default. Turn it on in **Settings → Dock**.

| Click | Action |
|---|---|
| Left | focus the app's window; click again to cycle through its windows |
| Middle | open a new instance |
| Right | pin or unpin |

With auto-hide on, move the pointer to the bottom edge to reveal the dock.

## Wallpapers

Flamenco draws the wallpaper itself, so **you don't need `swaybg`, `swww` or any other wallpaper program**. Remove those from your niri config, or they'll cover the shell's wallpaper.

**Where images come from:** the folder `~/Pictures/Wallpapers` by default, searched up to 3 levels deep. Supported formats are `.jpg`, `.jpeg`, `.png`, `.bmp` and `.webp`; `.webp` needs `qt6-imageformats`. On first start the first image found is used. With no images you get a plain background in the palette's color.

**Setting a wallpaper**, any of these:

- **Picker:** `Mod+W` (or `flamenco wallpapers`). Click a thumbnail; the shuffle button picks a random one.
- **Settings → Wallpaper:**
  - change the folder
  - choose the transition (*Fade*, *Zoom*, *Circle*, *Wipe*, or *Mix* for a random one) and its duration
  - set the fill mode (*Crop*, *Fit*, *Stretch*)
  - turn on cycling every N minutes
- **Command line:**
  ```sh
  flamenco wallpaper set ~/Pictures/Wallpapers/sunset.jpg
  flamenco wallpaper random
  flamenco wallpaper next
  flamenco wallpaper              # print the current wallpaper
  ```
- **Settings file:** `wallpaper.current` in `~/.config/flamenco/settings.json`.

The same wallpaper is used on every screen. It also appears blurred on the lock screen, and behind niri's overview thanks to the snippet's `layer-rule`.

**Colors from your wallpaper:** pick *From wallpaper* in **Settings → Appearance → Palette**. This needs `matugen`. The palette is regenerated whenever the wallpaper changes, and it flows through to your Qt and GTK apps too.

## Themes

Theming has two layers: the **shell palette**, which colors the shell itself, and **app theming**, which pushes that palette to your Qt and GTK applications.

### Shell palette

In **Settings → Appearance**:

- **Color mode:** dark or light.
- **Palette:** Flamenco, Breeze, Catppuccin, Rosé Pine, Nord, Tokyo Night, Gruvbox, Everforest, or *From wallpaper*.
- **Shape and surfaces:** corner roundness, panel opacity, shadows, dimming behind panels.
- **Motion:** animation speed; 0% turns animations off.
- **Typography:** interface font, monospace font, UI scale.

From the command line, or bound to keys in niri:

```sh
flamenco theme list             # available palettes
flamenco theme catppuccin       # switch palette
flamenco theme dark             # or: light, toggle
```

Dark mode can also be toggled from a control-center tile.

### Qt and GTK apps

With app theming on, which is the default, the shell re-themes your apps every time the palette or an app-theming option changes. One-time setup:

1. Install `qt6ct` and `qt5ct`. For GTK 3 apps that match libadwaita, also install `adw-gtk-theme`.
2. Make sure `QT_QPA_PLATFORMTHEME=qt6ct` is set. The niri snippet does this, but it only takes effect after you log in again. `flamenco doctor` shows whether it's set.
3. Open **Settings → App Theming** and press **Apply now** once.

Options on that page:

| Group | Options |
|---|---|
| General | apply automatically, sync fonts, **icon theme**, **cursor theme** and cursor size (see below) |
| Stylesheet (Qt + GTK) | corner radius (match the shell or set your own), button style (soft / flat / outlined), scrollbars (thin / overlay / classic), accent selections and focus rings, surface contrast |
| Qt | on/off, **widget style**, **Kvantum theme** (when the style is Kvantum), generated stylesheet, KDE color scheme, custom QSS |
| GTK | on/off, **base GTK theme**, GTK 3, GTK 4 / libadwaita, extra styling, custom CSS |

The bold options are dropdowns listing what's installed on your system. Press the refresh button on that page after installing new themes, or check from a terminal:

```sh
flamenco list-themes
```

**Cursor theme:** on niri, the pointer over your desktop and most windows is drawn by **niri itself**, from the `cursor { }` block in `~/.config/niri/config.kdl`. When you pick a cursor theme, Flamenco updates that block too:
- If there's no `cursor` block, it adds a marked one at the end of the file. If there is one, it changes only `xcursor-theme` and `xcursor-size`.
- It runs `niri validate` first and leaves the file alone if niri rejects the change.
- niri reloads the cursor immediately.
- It also sets the default cursor for X11 and XWayland apps.

Apps that were already open may keep the old cursor until you restart them. **Restore originals** puts back your previous cursor lines, or removes the block Flamenco added. It never touches the rest of your niri config.

The **Custom QSS** and **Custom GTK CSS** boxes are added after the generated stylesheet, so your rules win. They save when you click away or press `Ctrl+S`.

**When changes show up:**
- **GTK 4 / libadwaita apps** reload immediately.
- **GTK 3 and Qt apps** pick up changes when you restart them.

**Undo everything:** press **Restore originals**, or run `flamenco apps-theme --restore`. The first time Flamenco changes one of your own files, it saves a copy in `~/.local/state/flamenco/backup/`. It also records your previous gsettings values. Restore puts all of these back.

Files written:

| Toolkit | Files |
|---|---|
| Qt 5 / Qt 6 | `~/.config/qt{5,6}ct/colors/flamenco.conf` (full QPalette for active, inactive and disabled states)<br>`~/.config/qt{5,6}ct/qss/flamenco.qss` (generated stylesheet)<br>`qt{5,6}ct.conf` (palette, stylesheet, widget style, fonts, icons)<br>`~/.config/Kvantum/kvantum.kvconfig` (only when using Kvantum) |
| KDE apps | `~/.local/share/color-schemes/Flamenco.colors` and the color groups in `~/.config/kdeglobals` |
| Cursor | the `cursor { }` block in `~/.config/niri/config.kdl`, and `~/.local/share/icons/default/index.theme` |
| GTK 3 / 4 | `~/.config/gtk-{3,4}.0/gtk.css` (libadwaita and classic named colors, plus optional styling)<br>`settings.ini`<br>gsettings: `color-scheme`, `accent-color`, `gtk-theme`, fonts, icon and cursor themes |

## Troubleshooting

| Symptom | Fix |
|---|---|
| Icons show as words ("apps", "settings") | The icon font didn't load. Make sure `shell/assets/fonts/MaterialSymbolsRounded.ttf` exists in the installed shell (`flamenco doctor` checks for it) and restart the shell |
| Plain colored background, no wallpaper | `~/Pictures/Wallpapers` is missing or empty. Add images, or point **Settings → Wallpaper → Folder** at another folder |
| Wallpaper hidden or flickering | Another wallpaper program or shell is running (`swaybg`, `swww`, DMS). Remove it from your niri config |
| niri says `duplicate node binds` | Move the Flamenco key lines into your existing `binds { }` block |
| Qt apps ignore the theme | `QT_QPA_PLATFORMTHEME` isn't `qt6ct`. Set it (the niri snippet does), log in again, and restart the app |
| Cursor theme doesn't change | Press **Apply now** in **Settings → App Theming** and check `~/.config/niri/config.kdl` for the `cursor { }` block. Restart apps that were already open |
| Locked in by an SDDM theme | Press **Ctrl+Alt+Shift+L** on the lock screen to switch to the built-in lock |
| Tray menu misplaced or not opening | Turn on **Settings → Bar → Native Qt menus** |
| The shell crashes on start | Run `flamenco run --fg` and read the error. The crash report is under `~/.cache/quickshell/crashes/` |

## Reference

### The `flamenco` command

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
flamenco list-themes [--json]   installed icon / cursor / GTK / Qt-style / Kvantum / SDDM themes
flamenco ipc TARGET FUNCTION [ARGS...]
flamenco doctor [--json]
flamenco niri-config
```

### Settings file

All settings live in `~/.config/flamenco/settings.json`. The shell watches the file, so edits made by hand apply immediately. Deleting the file resets everything to defaults on the next start.

### Layout

```
bin/flamenco                 CLI: launcher, IPC client, Qt/GTK theme generator
shell/shell.qml              root: modules + IPC handlers
shell/Commons/               Theme (tokens + motion curves), Settings (JSON), Palettes, ColorGen, Paths
shell/Services/              Niri, Audio, Brightness, Network, BluetoothState, Power, Media, Notifs,
                             Wallpapers, Weather, Apps, SystemStats, Time, Toggles, Panels, AppTheming
shell/Widgets/               F* component library (buttons, switch, slider, dropdown, tiles, ripple, OverlayPanel…)
shell/Modules/               Bar, Background, ControlCenter, Launcher, Notifications, OSD, Lock,
                             Session, Calendar, WallpaperPicker, Dock, Settings
data/                        desktop entry and icon for Flamenco Settings
packaging/arch/              PKGBUILD and a makepkg-free build script
tools/qmlcheck.py            static QML checks
tools/screenshots.sh         regenerates docs/screenshots/
```

### Development

`tools/qmlcheck.py` runs static checks over the QML without needing Qt (unknown types, unbalanced braces, and the `Behavior` patterns that crash Qt 6.12). Run it before building a package.

`tools/screenshots.sh` regenerates the README screenshots in `docs/screenshots/`. Run it inside a niri session with the shell running; it needs `grim`, and `notify-send` for the notification shots. It opens each panel in turn, captures it, and puts your palette and color mode back when it's done.

## TODO
- [x] Add dock options to change the top bar from top to each corner of the screen (Settings → Bar → Position: top / bottom / left / right)
- [x] Under app theming ensure a drop down can be used instead of typing in the theme - this should be able to select the ones installed.
- [x] Include app Indicators support
- [x] Improve the top left indicator as there's a lot of spaces between them.
