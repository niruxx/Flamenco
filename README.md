# Flamenco Shell

A desktop shell for the [niri](https://github.com/YaLTeR/niri) compositor, built with [Quickshell](https://quickshell.org). It's structured like Noctalia and DMS: a QML shell plus a small `flamenco` program that launches it, talks to it over IPC, and themes your Qt and GTK applications to match.

- [Screenshots](#screenshots)
- [Features](#features)
- [Getting started](#getting-started)
- [Using the shell](#using-the-shell)
- [Network, printers and power](#network-printers-and-power)
- [System check](#system-check)
- [Displays](#displays)
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
| **Dashboard** | Opens from the bar clock. Tabs: Overview (clock, calendar, user, weather and media cards), Media (full player), Wallpapers (picker and folder), Weather (configurable forecast), and a shortcut to Settings |
| **Performance** | Opens from the CPU/RAM widget: CPU history, load and frequency, temperatures from every sensor, memory and swap, disks, network speed, top processes |
| **Network & VPN** | Wi-Fi, plus NetworkManager VPNs (WireGuard, OpenVPN): connect from the control center, import `.conf`/`.ovpn` files in Settings |
| **Printers** | CUPS: start and enable the service, set the default printer, print test pages, manage the queue |
| **Power** | Power-saver / Balanced / Performance profiles in the control center and Settings |
| **System check** | Runs `flamenco doctor` in Settings, shows what's missing and gives the exact `pacman` command |
| **Dock** | Optional. Pinned and running apps, magnification, auto-hide with an adjustable reveal edge, app picker for pinning |
| **Displays** | Per-display resolution, refresh rate, scale, orientation (rotate and flip) and VRR; drag-to-arrange layout; live apply with 15-second auto-revert; saved to niri's config |
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

```sh
flamenco niri-config [--print]  write a complete ~/.config/niri/config.kdl (old one backed up)
flamenco logs [-f]              background log of the shell
flamenco printers [--json] | default NAME | test NAME | cancel ID|all | service ACTION | add
flamenco doctor --install-command
```

This **replaces `~/.config/niri/config.kdl` with a complete config for Flamenco**:
- **Kept from your old config:** your `input` block (keyboard layout, touchpad), your display (`output`) blocks and your cursor.
- **Added:** everything else. That's Flamenco starting with niri, the full set of standard niri keybindings plus the Flamenco ones, the Qt theming environment, rounded windows, and the wallpaper behind the overview.
- **Backup:** your previous config is saved next to it as `config.kdl.bak-<date>`.
- **Validation:** the new config is checked with `niri validate` first. If niri rejects it, nothing is changed.

The new config never starts another shell. If you had `dms`, `waybar`, `swaybg` or similar starting before, they're gone; two shells would fight over notifications, the bar area and the wallpaper. Use `flamenco niri-config --print` to see the config without writing it.

The config keeps working even if the shell fails to start:
- `Mod+T` opens a terminal
- the volume, brightness and media keys fall back to `wpctl`, `brightnessctl` and `playerctl`
- `Mod+Shift+E` or `Ctrl+Alt+Delete` quits niri

Log out and choose **niri** at the login screen. To start or restart the shell by hand:

```sh
flamenco run --fg       # foreground, prints errors; Ctrl+C to stop
flamenco run            # background, logs to ~/.cache/flamenco/shell.log
flamenco restart        # after an upgrade
flamenco logs           # show the background log (-f to follow)
```

## Using the shell

### Keybindings

These come from `flamenco niri-config`; change them in `~/.config/niri/config.kdl`. `Mod+Shift+/` shows every binding.

| Key | Action |
|---|---|
| `Mod+Space` | App launcher |
| `Mod+A` | Control center |
| `Mod+N` | Notification center |
| `Mod+W` | Wallpaper picker |
| `Mod+Comma` | Settings |
| `Mod+Escape` | Power menu |
| `Super+Alt+L` | Lock screen |
| `Mod+T` / `Mod+Return` | Terminal |
| `Mod+O` | niri overview |
| `Mod+Q` | Close window |
| `Mod+Shift+E` | Quit niri |

Every panel closes with `Esc` or a click outside it.

**Flamenco Settings** is also a regular app. Find it in the launcher, or any other app launcher, under that name. It starts the shell first if it isn't running.

### Bar

| Widget | Click | Other |
|---|---|---|
| Launcher (apps icon) | open launcher | |
| Workspaces | go to that workspace | scroll to switch workspaces |
| Clock | dashboard (Overview, Media, Wallpapers, Weather) | |
| Media | control center | middle-click play/pause, right-click next track |
| System tray | activate the app | right-click app menu, middle-click secondary action, scroll is passed to the app, hover for tooltip |
| CPU / RAM | performance popout | middle-click opens `btop` |
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

Start typing to search apps. **Settings → Launcher** sets where it opens: center, top, bottom, any corner, or next to the bar. It also sets the launcher's width. Results are ranked by match quality and how often you launch each app.

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
- **VPN tile:** connects your VPN, or disconnects it if it's already on. Its `›` arrow lists all your VPNs with on/off switches.
- **Power tile:** click to cycle power profiles. Its `›` arrow opens a page with Power saver, Balanced and Performance, plus battery details.
- **Header:** settings, lock and power buttons.
- **Media card:** appears while something is playing. Click the progress bar to seek; use the swap button to switch between players.

### Dashboard

Click the clock in the bar to open the dashboard. It opens on the tab chosen in **Settings → Clock & Weather**, Overview by default:

| Tab | Shows |
|---|---|
| **Overview** | Big clock, month calendar, your user card, and summary cards for the weather and the current track (click them for the full tab) |
| **Media** | The current track with large cover art, a seek bar, previous/play/next, and shuffle/repeat where the player supports them. With several players, chips let you switch between them. Shows "No media playing" otherwise |
| **Wallpapers** | The wallpaper folder (edit it right there), the picker grid, shuffle and rescan |
| **Weather** | Now (temperature, feels like, wind, humidity, sunrise and sunset), the next 12 hours, and a 1–7 day forecast with rain chance and temperature range |
| **Settings** | Opens the Settings app |

What the Overview and Weather tabs show is set in **Settings → Clock & Weather**:
- the weather location and units
- forecast length
- which weather details appear
- whether the user, media and weather cards show on Overview

### Performance

Click the CPU/RAM widget for the performance popout:
- **CPU:** usage with a one-minute history graph, load average, cores and frequency
- **Temperatures:** every hardware sensor, colored by how hot it is
- **Memory:** RAM and swap
- **Disks:** usage for each mounted disk
- **Network:** download and upload speed with a graph
- **Processes:** the busiest few

The **btop** button opens a full monitor in your terminal. Sensors, disks and processes are only read while the popout is open.

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

The dock is off by default. Turn it on in **Settings → Dock**. That page also has:
- auto-hide, and how close to the bottom edge the pointer must be to reveal the dock
- whether running apps that aren't pinned appear
- magnification and icon size
- the pinned-app list: pin apps from a dropdown of everything installed, reorder them, or remove them

Pinned apps that aren't installed are hidden. A dock with auto-hide off reserves its space, and sits above a bottom bar.

| Click | Action |
|---|---|
| Left | focus the app's window; click again to cycle through its windows |
| Middle | open a new instance |
| Right | pin or unpin |

With auto-hide on, move the pointer to the bottom edge to reveal the dock.

## Network, printers and power

**Settings → Network**
- **Wi-Fi:** on/off.
- **VPNs:** your NetworkManager VPNs, with connect switches and delete buttons.
- **Import:** a WireGuard `.conf` or OpenVPN `.ovpn` file. OpenVPN needs `networkmanager-openvpn`.
- **Connection editor:** a button that opens `nm-connection-editor` for everything else.

**Settings → Printers** manages CUPS:
- **Not installed:** an **Install** button sets up `cups`, `cups-pdf` and `system-config-printer`, and enables the service.
- **Service:** start or stop CUPS, and enable or disable it at boot. These need your password, so they open in a terminal.
- **Printers:** the list, with a star to make one the default, and a **Test page** button. **Add printer** opens `system-config-printer`, or the CUPS web page if that isn't installed.
- **Queue:** waiting jobs, with cancel buttons.

The same actions are available as `flamenco printers …`.

**Settings → Power** switches between Power saver, Balanced and Performance. Performance appears only if your hardware offers it. The page also shows battery status. The control center's Power tile does the same.

## System check

**Settings → System check** (also reachable from About) runs `flamenco doctor` and lists, by category, everything Flamenco uses:
- **Core:** Quickshell, niri, the icon font, a terminal.
- **Session:** the niri config is valid, Flamenco starts with niri, no other shell is started, the screen-sharing portal, XWayland, and the GPU. In a virtual machine, it also checks for 3D acceleration.
- **Features:** NetworkManager and VPN plugins, PipeWire, brightness, power profiles, Bluetooth, CUPS, clipboard, and so on.
- **Theming:** qt5ct/qt6ct, the Qt environment variable, adw-gtk3, WebP support, matugen.

Anything missing shows the package that provides it. The page builds one command for all of it, which you can **Install in terminal** or **Copy**. From a terminal:

```sh
flamenco doctor                    # grouped report
flamenco doctor --install-command  # just the pacman/paru command
```

The page also has buttons to view the shell log and to write the niri config.

## Displays

**Settings → Displays** (or `flamenco settings displays`) configures your monitors through niri.

1. **Arrange:** drag screens on the canvas to position them. They snap to each other's edges. Click a screen to select it. Displays that are switched off are listed below the canvas.
2. **Configure the selected display:**
   - turn it on or off
   - resolution (the native one is marked)
   - refresh rate, from the rates available at that resolution
   - scale, with the effective size shown
   - orientation (normal, 90°, 180°, 270°) and the flip button
   - variable refresh rate, on displays that support it
3. **Apply:** changes take effect immediately. A **Keep these display settings?** prompt appears on every screen. Press **Keep changes** (or `Enter`) to save them, or **Revert** (or `Esc`). If you do nothing for 15 seconds, the previous settings come back on their own, so a mode your monitor can't show won't strand you.

**Identify** shows each display's name on its screen.

**Where it's saved:** keeping changes writes `output "NAME" { mode …; scale …; transform …; position …; }` blocks into `~/.config/niri/config.kdl`.
- Existing `output` blocks are edited in place. Only those lines change; your other lines and comments are kept.
- A display that's switched off gets just `off`, so its other settings survive for next time.
- niri validates the file first.
- A copy of your config from before the first change is kept at `~/.local/state/flamenco/backup/niri-config.before-displays.kdl`.

The same operations are available from the command line:

```sh
flamenco display list          # current state of every display
flamenco display list --json
flamenco display apply --json '[{"name":"DP-1","mode":{"w":2560,"h":1440,"r":143998},"scale":1,"transform":"normal","x":0,"y":0}]'
flamenco display save  --json '…'    # same format; writes niri's config
```

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
| Dock never appears | Check **Show dock** in **Settings → Dock**. With auto-hide on, push the pointer against the bottom edge, or raise **Reveal edge**; on some VM displays the pointer can't reach the last few pixels |
| Display change left a blank screen | Wait 15 seconds; it reverts on its own. If you already kept it, restore `~/.local/state/flamenco/backup/niri-config.before-displays.kdl` |
| Locked in by an SDDM theme | Press **Ctrl+Alt+Shift+L** on the lock screen to switch to the built-in lock |
| Tray menu misplaced or not opening | Turn on **Settings → Bar → Native Qt menus** |
| **Black screen after logging in to niri** | Switch to a text console (`Ctrl+Alt+F3`), log in, and run `flamenco doctor`.<br>**In a virtual machine** this is almost always missing 3D acceleration: niri has no software renderer, so without it nothing is drawn. Turn on 3D in the VM settings (virt-manager: Video *VirtIO* with *3D acceleration*, and *OpenGL* on the Spice display; VirtualBox: *VMSVGA* with *3D acceleration*). The check *VM 3D acceleration* shows whether it's on.<br>**Otherwise:** if niri runs (`Mod+T` opens a terminal) but there's no bar or wallpaper, the shell didn't start. Check `flamenco logs` or run `flamenco run --fg` |
| The shell crashes on start | Run `flamenco run --fg` and read the error. The crash report is under `~/.cache/quickshell/crashes/` |

## Reference

### The `flamenco` command

```
flamenco run [--fg]             start (daemonized unless --fg)
flamenco kill | restart
flamenco launcher | control | notifications | calendar | wallpapers | power
flamenco settings [page]        appearance, apps, bar, dock, displays, wallpaper, notifications, launcher, lock, clock, about
flamenco lock
flamenco volume up|down|mute|mic-mute|set N
flamenco brightness up|down|set N
flamenco media toggle|next|previous
flamenco wallpaper [set PATH | random | next]
flamenco theme PALETTE | dark | light | toggle | list | apply-apps
flamenco apps-theme --json SPEC | --restore
flamenco display list | apply --json SPEC | save --json SPEC
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
