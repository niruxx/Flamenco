<a id="top"></a>

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/assets/banner-dark.svg">
  <source media="(prefers-color-scheme: light)" srcset="docs/assets/banner-light.svg">
  <img alt="Flamenco Shell: a Material 3 desktop shell for niri and Hyprland, built with Quickshell" src="docs/assets/banner-dark.svg" width="100%">
</picture>

<p align="center">
  <img src="https://img.shields.io/badge/version-0.19.0-E8466F?style=for-the-badge" alt="Version 0.19.0">
  <img src="https://img.shields.io/badge/Quickshell-0.3.2-FF5722?style=for-the-badge&logo=qt&logoColor=white" alt="Quickshell 0.3.2">
  <img src="https://img.shields.io/badge/niri%20%7C%20Hyprland-supported-00BCD4?style=for-the-badge" alt="niri and Hyprland">
  <img src="https://img.shields.io/badge/Material%20Design-3-6750A4?style=for-the-badge&logo=materialdesign&logoColor=white" alt="Material Design 3">
  <img src="https://img.shields.io/badge/Arch%20Linux-package-1793D1?style=for-the-badge&logo=archlinux&logoColor=white" alt="Arch Linux package">
</p>

<p align="center">
  <a href="#gallery"><b>📸 Gallery</b></a> &nbsp;·&nbsp;
  <a href="#features"><b>✨ Features</b></a> &nbsp;·&nbsp;
  <a href="#getting-started"><b>🚀 Install</b></a> &nbsp;·&nbsp;
  <a href="#using-the-shell"><b>🎛️ Guide</b></a> &nbsp;·&nbsp;
  <a href="#wallpapers-and-themes"><b>🎨 Themes</b></a> &nbsp;·&nbsp;
  <a href="#troubleshooting"><b>🛟 Help</b></a> &nbsp;·&nbsp;
  <a href="#reference"><b>📚 Reference</b></a>
</p>

<a id="about"></a>

## 💃 About

Flamenco Shell is a complete desktop shell built with [Quickshell](https://quickshell.org): bar, launcher, control center, notifications, lock screen, wallpaper, dock and a full Settings app. It's made for the [niri](https://github.com/YaLTeR/niri) scrolling compositor and also runs on [Hyprland](https://hyprland.org). Everything follows one Material Design 3 look: 13 palettes or colors from your wallpaper (`matugen`), carried through to your Qt and GTK apps, with animated panels and dashboards.

<table>
  <tr>
    <td width="33%" valign="top">
      <h3>🎨 One look, everywhere</h3>
      13 palettes in dark and light, your own accent, or colors from your wallpaper. Qt, GTK, KDE colors, cursors and icons follow along.
    </td>
    <td width="33%" valign="top">
      <h3>⚙️ A real Settings app</h3>
      28 pages, from keyboard shortcuts and displays to firewall, printers and Flatpak permissions. Every change applies live.
    </td>
    <td width="33%" valign="top">
      <h3>🧭 Made for niri</h3>
      Writes a complete, validated niri config, and works on Hyprland too (Lua or classic config).
    </td>
  </tr>
  <tr>
    <td width="33%" valign="top">
      <h3>🛡️ Safe by default</h3>
      Config edits are checked with <code>niri validate</code> and backed up first. Display changes revert on their own after 15 seconds.
    </td>
    <td width="33%" valign="top">
      <h3>📐 Fits any screen</h3>
      The bar measures itself and compacts step by step on narrow or rotated screens. Popouts scroll instead of overflowing.
    </td>
    <td width="33%" valign="top">
      <h3>🔋 Batteries included</h3>
      Notification daemon, lock screen, wallpaper, OSD, hot corners and screenshots, with no extra daemons to wire up.
    </td>
  </tr>
</table>

<details>
<summary><b>📑 Table of contents</b></summary>

- [📸 Gallery](#gallery)
- [✨ Features](#features)
- [🚀 Getting started](#getting-started)
- [🎛️ Using the shell](#using-the-shell): keybindings, bar, launcher, control center, dashboard, notifications, lock, dock
- [⚙️ System settings](#system-settings): sound, keyring, firewall, network, printers, power, screen sharing, system check
- [⌨️ Input & displays](#input-and-displays): keyboard & shortcuts, mouse & touchpad, displays
- [🪟 Desktop & apps](#desktop-and-apps): windows, workspaces, screen edges, screenshots, default apps, auto-start, Flatpak
- [🎨 Wallpapers & themes](#wallpapers-and-themes)
- [🛟 Troubleshooting](#troubleshooting)
- [📚 Reference](#reference)
- [📝 TODO](#todo)

</details>

<a id="gallery"></a>

## 📸 Gallery

<p align="center">
  <img src="docs/screenshots/desktop.png" alt="The Flamenco desktop" width="100%">
</p>

<table>
  <tr>
    <td width="50%" align="center"><img src="docs/screenshots/launcher.png" alt="Launcher"><br><b>🔍 Launcher</b></td>
    <td width="50%" align="center"><img src="docs/screenshots/control-center.png" alt="Control center"><br><b>🎛️ Control center</b></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/notification-center.png" alt="Notification center"><br><b>🔔 Notification center</b></td>
    <td align="center"><img src="docs/screenshots/notification-popups.png" alt="Notification popups"><br><b>💬 Notification popups</b></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/calendar.png" alt="Calendar and weather"><br><b>📅 Calendar & weather</b></td>
    <td align="center"><img src="docs/screenshots/wallpaper-picker.png" alt="Wallpaper picker"><br><b>🖼️ Wallpaper picker</b></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/power-menu.png" alt="Power menu"><br><b>⚡ Power menu</b></td>
    <td align="center"><img src="docs/screenshots/control-center-light.png" alt="Control center in light mode"><br><b>☀️ Light mode</b></td>
  </tr>
</table>

### ⚙️ The Settings app

<table>
  <tr>
    <td width="33%" align="center"><img src="docs/screenshots/settings-appearance.png" alt="Settings: Appearance"><br><b>🎨 Appearance</b></td>
    <td width="33%" align="center"><img src="docs/screenshots/settings-app-theming.png" alt="Settings: App theming"><br><b>🖌️ App theming</b></td>
    <td width="33%" align="center"><img src="docs/screenshots/settings-bar.png" alt="Settings: Bar"><br><b>📊 Bar</b></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/settings-windows.png" alt="Settings: Windows & layout"><br><b>🪟 Windows & layout</b></td>
    <td align="center"><img src="docs/screenshots/settings-workspaces.png" alt="Settings: Workspaces"><br><b>🗂️ Workspaces</b></td>
    <td align="center"><img src="docs/screenshots/settings-edges.png" alt="Settings: Screen edges"><br><b>↖️ Screen edges</b></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/settings-keyboard.png" alt="Settings: Keyboard"><br><b>⌨️ Keyboard</b></td>
    <td align="center"><img src="docs/screenshots/settings-displays.png" alt="Settings: Displays"><br><b>🖥️ Displays</b></td>
    <td align="center"><img src="docs/screenshots/settings-screenshots.png" alt="Settings: Screenshots"><br><b>📷 Screenshots</b></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/settings-defaults.png" alt="Settings: Default apps"><br><b>📦 Default apps</b></td>
    <td align="center"><img src="docs/screenshots/settings-autostart.png" alt="Settings: Auto-start"><br><b>🚀 Auto-start</b></td>
    <td align="center"><img src="docs/screenshots/settings-flatpak.png" alt="Settings: Flatpak permissions"><br><b>🔐 Flatpak permissions</b></td>
  </tr>
</table>

### 🌈 Palettes on the desktop

<table>
  <tr>
    <td width="25%" align="center"><img src="docs/screenshots/palette-catppuccin.png" alt="Catppuccin"><br>Catppuccin</td>
    <td width="25%" align="center"><img src="docs/screenshots/palette-rosepine.png" alt="Rosé Pine"><br>Rosé Pine</td>
    <td width="25%" align="center"><img src="docs/screenshots/palette-nord.png" alt="Nord"><br>Nord</td>
    <td width="25%" align="center"><img src="docs/screenshots/palette-gruvbox.png" alt="Gruvbox"><br>Gruvbox</td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/palette-dracula.png" alt="Dracula"><br>Dracula</td>
    <td align="center"><img src="docs/screenshots/palette-kanagawa.png" alt="Kanagawa"><br>Kanagawa</td>
    <td align="center"><img src="docs/screenshots/palette-tokyonight.png" alt="Tokyo Night"><br>Tokyo Night</td>
    <td align="center"><img src="docs/screenshots/palette-everforest.png" alt="Everforest"><br>Everforest</td>
  </tr>
</table>

> [!NOTE]
> The screenshots are captured by `tools/screenshots.sh` and the artwork is drawn by `tools/readme-assets.py`; see [Development](#development).

<p align="right"><a href="#top">⬆️ Back to top</a></p>

<a id="features"></a>

## ✨ Features

#### 🖥️ On the desktop

| | |
|---|---|
| **📊 Bar** | Floating, attached or "islands" style, on any screen edge (left/right give a vertical bar). Widgets are reorderable: launcher, niri workspaces (compact gliding indicator), active window (click for a window menu), a taskbar of running apps (right-click for the same menu), clock, media (spinning cover art), system tray, CPU/RAM, keyboard layout, network, Bluetooth, volume, brightness, battery, notifications, weather, power |
| **🔔 App indicators** | StatusNotifierItem / libappindicator tray with themed menus (submenus, check/radio items), tooltips, attention pulse, optional hiding of passive icons, overflow drawer. Native Qt menus available as a setting |
| **🎛️ Control center** | Volume, mic, screen and keyboard brightness sliders. Tiles for Wi-Fi, Bluetooth, DND, night light, caffeine, power profile, dark mode and wallpaper. Wi-Fi, Bluetooth and audio-device pages slide in. Media card with blurred album art |
| **🔍 Launcher** | Fuzzy app search ranked by how often you use each app. `=` calculator, `>` run command, `;` clipboard history (cliphist) |
| **💬 Notifications** | Built-in daemon: popups with timeout bar, swipe to dismiss, actions, DND. History persists across restarts |
| **📢 OSD** | Volume, screen brightness, keyboard backlight and mic popups |
| **🗓️ Dashboard** | Opens from the bar clock. Tabs: Overview (clock, calendar, user, weather and media cards), Media (full player), Wallpapers (picker and folder), Weather (configurable forecast), and a shortcut to Settings |
| **📈 Performance** | Opens from the CPU/RAM widget: CPU history, load and frequency, temperatures from every sensor, memory and swap, disks, network speed, top processes |
| **📌 Dock** | Optional. Bottom, left or right edge; pinned and running apps, magnification, auto-hide, app names on hover, running indicators, and its size, spacing, background and corners |
| **🧩 Desktop widgets** | Clock, weather, system stats, now playing, calendar and notes on the desktop, under your windows. Drag them in from a sidebar opened from quick settings; move, resize or remove them; card, glass or bare style |
| **🖼️ Wallpaper** | Animated transitions (Mosaic, Ripple, Sweep, Blinds, Circle, Wipe, Focus, Fade, or Mix) with soft edges and an accent glow, a blurred copy behind niri's overview, picker grid, auto-cycle, colors from wallpaper (matugen) |
| **🔒 Lock screen** | PAM auth with password or **fingerprint** (enroll fingers in Settings), blurred wallpaper that clears as you unlock, media controls, auto-lock on idle, screen-off timer. Can run any **SDDM greeter theme** as the lock screen, or hand off to a command such as `hyprlock` |
| **🚪 Login screen** | Set up **Flamenco Greeter** (greetd) from Settings: wallpaper, blur and dim, fonts, the session picker, user list and power buttons, in the shell's palette. Edits greetd itself too: greeter, VT and auto-login |
| **⚡ Power menu** | Lock, suspend, log out, restart, shut down. Keyboard navigation; log out, restart and shut down must be held for 3 seconds |
| **✨ Login & logout animations** | Bloom, Curtain, Blinds, Zoom or Fade over your blurred wallpaper with a greeting; separate choices for login and logout, with previews |

#### 🪟 Windows, input & displays

| | |
|---|---|
| **🪟 Windows & Layout** | Gaps, edge margins, new-window width, column centering, corner radius, focus ring and border (colors follow the theme or your own), shadows, focus follows mouse, pointer warping, cursor hiding; written to the niri or Hyprland config |
| **🗂️ Workspaces** | Named workspaces pinned to a screen, switch back and forth, and bar switcher options: hide empty, scroll to switch (or reversed), window count |
| **↖️ Screen edges** | Hot corners on every screen: overview, launcher, control center, notifications, dashboard, power menu, settings, screenshot, workspace up/down or lock, with an adjustable delay and size |
| **📷 Screenshots** | niri's own area / screen / window screenshots (grim + slurp on Hyprland) from Settings, the keyboard or `flamenco screenshot`: pointer on/off, save to disk or clipboard only, delay, file name |
| **⌨️ Keyboard** | Layouts, variants, layout switching, Caps Lock / Compose, key repeat, and shortcuts that open apps, run commands, call Flamenco functions or niri actions. Keys are recorded or typed, and per-shortcut or full resets to the defaults are available. Written to niri's config |
| **🖱️ Mouse & Touchpad** | Pointer speed, flat or adaptive acceleration, scroll speed, natural scrolling, left-handed, tap to click, disable while typing; written to the niri or Hyprland config |
| **🖥️ Displays** | Per-display resolution, refresh rate, scale, orientation (rotate and flip) and VRR; drag-to-arrange layout; live apply with 15-second auto-revert; saved to niri's config. Turns the laptop screen back on if every screen would otherwise be off |

#### ⚙️ System

| | |
|---|---|
| **🌐 Network & VPN** | Wi-Fi and wired connections edited right in Settings (addresses, DNS, security, MAC, metered…), or in your own network app if you prefer, plus NetworkManager VPNs (WireGuard, OpenVPN) |
| **🔊 Sound** | Pick an installed sound theme (shared with GTK, GNOME and KDE apps), notification, volume and brightness sounds, output/input devices |
| **🔑 Keyring** | Choose which keyring stores app passwords: GNOME Keyring, KDE Wallet, KeePassXC, oo7, or none. Shows what's running and whether it unlocks at login |
| **🛡️ Firewall** | Detects ufw or firewalld: turn it on/off, default policies or zones, add/remove ports, services and rules (applied with one sudo prompt) |
| **🖥️ Screen sharing** | Choose the xdg-desktop-portal backend for screen sharing, screenshots and file pickers. The lightweight wlr setup avoids GNOME; also a screen picker and frame-rate limit |
| **🖨️ Printers** | CUPS: start and enable the service, set the default printer, print test pages, manage the queue |
| **🔋 Power** | Power profiles, sleep on/off, idle suspend (battery / plugged in), lock before sleep, lid actions (battery / plugged in / docked) and the power button |
| **🩺 System check** | Runs `flamenco doctor` in Settings, shows what's missing and gives the exact `pacman` command |
| **ℹ️ About** | OS, hardware, memory, disk, kernel, compositor, Quickshell and package counts, with a copy button for bug reports |

#### 🎨 Look & apps

| | |
|---|---|
| **⚙️ Settings app** | Its own window (`flamenco settings`) with a page for every module. Every change applies live |
| **🎨 App theming** | Qt 5/6 (qt5ct/qt6ct palette and generated QSS stylesheet, KDE color scheme) and GTK 3/4 (libadwaita color overrides plus optional styling), with stylesheet options and custom QSS/CSS in Settings |
| **📦 Default apps** | Browser, file manager, email, text editor, images, video, music, PDF, archives and terminal, written to `mimeapps.list` |
| **🚀 Auto-start** | XDG autostart entries: turn them on or off, add apps or plain commands; Flamenco runs them at login unless systemd already does |
| **🔐 Flatpak permissions** | Per-app overrides for files and folders, network, display, sound, devices and features: app default, allow, read-only or deny |

### 🌈 Thirteen palettes, dark and light

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/assets/palettes-dark.svg">
  <source media="(prefers-color-scheme: light)" srcset="docs/assets/palettes-light.svg">
  <img alt="The 13 Flamenco palettes" src="docs/assets/palettes-dark.svg" width="100%">
</picture>

Flamenco, Breeze, Catppuccin, Rosé Pine, Nord, Tokyo Night, Gruvbox, Everforest, Dracula, Kanagawa, Solarized, One Dark and Monochrome, each hand-tuned in dark and light. You can also derive the palette from your wallpaper, swap in your own accent color, and pick a whole layout preset (Modern, Minimal, Classic, Dock & menu bar, Vertical). Palette switches cross-fade across the whole shell.

<p align="right"><a href="#top">⬆️ Back to top</a></p>


<a id="getting-started"></a>

## 🚀 Getting started

### 1️⃣ Install dependencies

**Required:** `quickshell` (developed against 0.3.2 with Qt 6.12; 0.2 or newer should work), `niri`, `python3`. The *Material Symbols Rounded* icon font (Apache-2.0) and the default fonts, *Google Sans Flex* and *Google Sans Code* (OFL-1.1), are bundled in `shell/assets/fonts/`, so you don't need to install them. The Arch package also links the Google Sans fonts into `/usr/share/fonts`, so GTK apps and the login screen can use them too.

**Optional** (each enables one feature):

| Package | Enables |
|---|---|
| `networkmanager` | network status and Wi-Fi control |
| `brightnessctl` | screen and keyboard brightness sliders and OSD |
| `matugen` | the "From wallpaper" palette |
| `cliphist` + `wl-clipboard` | clipboard history in the launcher, copying calculator results |
| `gammastep` | night light |
| `qt5ct`, `qt6ct` | theming Qt apps |
| `adw-gtk-theme` | GTK 3 apps that look like libadwaita apps |
| `qt6-imageformats` | `.webp` wallpapers |
| `power-profiles-daemon`, `upower`, `bluez` | power profile tile, battery, Bluetooth |
| `python-gobject` + `xdg-desktop-portal-gtk` (or `-gnome` / `-kde`) | the **Browse** folder picker (falls back to kdialog, zenity or yad) |
| `fprintd` | fingerprints: enrolling, and unlocking the lock screen |

On Arch:

```sh
paru -S quickshell niri \
        networkmanager brightnessctl matugen-bin cliphist wl-clipboard gammastep \
        qt5ct qt6ct adw-gtk-theme qt6-imageformats power-profiles-daemon
```

### 2️⃣ Install Flamenco

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

### 3️⃣ Configure niri

```sh
flamenco niri-config [--print]  write a complete ~/.config/niri/config.kdl (old one backed up)
flamenco hyprland-config [--lua|--conf] [--print]   same for Hyprland (hyprland.lua or hyprland.conf)
flamenco setup                  open the first-run setup
flamenco logs [-f]              background log of the shell
flamenco printers [--json] | default NAME | test NAME | cancel ID|all | service ACTION | add
flamenco doctor --install-command
```

This **replaces `~/.config/niri/config.kdl` with a complete config for Flamenco**:
- **Kept from your old config:** your `input` block (keyboard layout, touchpad), your display (`output`) blocks and your cursor.
- **Added:** everything else. That's Flamenco starting with niri, the full set of standard niri keybindings plus the Flamenco ones, the Qt theming environment, rounded windows, and the wallpaper behind the overview.
- **Backup:** your previous config is saved next to it as `config.kdl.bak-<date>`.
- **Validation:** the new config is checked with `niri validate` first. If niri rejects it, nothing is changed.

> [!WARNING]
> The new config never starts another shell. If you had `dms`, `waybar`, `swaybg` or similar starting before, they're gone; two shells would fight over notifications, the bar area and the wallpaper. Use `flamenco niri-config --print` to see the config without writing it.

The config keeps working even if the shell fails to start:
- `Mod+T` opens a terminal
- the volume, brightness, keyboard backlight and media keys fall back to `wpctl`, `brightnessctl` and `playerctl`
- `Mod+Shift+E` or `Ctrl+Alt+Delete` quits niri

Log out and choose **niri** at the login screen. To start or restart the shell by hand:

```sh
flamenco run --fg       # foreground, prints errors; Ctrl+C to stop
flamenco run            # background, logs to ~/.cache/flamenco/shell.log
flamenco restart        # after an upgrade
flamenco logs           # show the background log (-f to follow)
```

### 4️⃣ First-run setup

The first time the shell starts, the **Flamenco Setup** window opens just after the login animation. Its steps:
- **Welcome**
- **Displays**
- **Look & colors** (palette, mode, fonts)
- **Icons & cursors**
- **Wallpaper**
- **Sound**
- **Bluetooth** (turn it on, scan, connect)
- **Screen sharing & files**
- **Keyring**
- **All set:** "Welcome to Flamenco", with your shortcuts shown as keycaps, and **Start using Flamenco** plays the login animation.

Each step is the real Settings page, so changes apply immediately. Move between steps with Back/Next or the step list, use **Skip for now** to leave, and drag the step list's background to move the window. To run it again: **Settings → About → Open setup**, or `flamenco setup`.

### 🌀 Using Hyprland instead of niri

Flamenco also runs on Hyprland, with either config format:

```sh
flamenco hyprland-config            # picks the format you use (see below); old config backed up
flamenco hyprland-config --lua      # force hyprland.lua (newer Hyprland, `hl.*` API)
flamenco hyprland-config --conf     # force hyprland.conf (classic hyprlang)
flamenco hyprland-config --print    # show it without writing
```

**Which format:** it writes **`hyprland.lua`** when you already have one, or when there's no Hyprland config yet, since that's what newer Hyprland uses. It writes `hyprland.conf` only if that's your only config.

**Both formats include:**
- Flamenco starting with Hyprland, and Qt theming
- decoration and animations
- window and workspace keys, and media keys with fallbacks
- floating rules for the Flamenco windows

The parts Flamenco Settings manages live in separate files:

| | Lua config | Classic config |
|---|---|---|
| Shortcuts | `hypr/flamenco/binds.lua` | `hypr/flamenco-binds.conf` |
| Keyboard | `hypr/flamenco/input.lua` | `hypr/flamenco-input.conf` |
| Cursor | `hypr/flamenco/cursor.lua` | `hypr/flamenco-cursor.conf` |
| Displays | `hypr/flamenco/monitors.lua` | `hypr/flamenco-monitors.conf` |

**In the Lua config:**
- **Safe includes:** Flamenco's files are loaded with `pcall`, so an error in one is logged and the rest of your config still loads.
- **Taking over keys:** the default bindings go through a helper that skips any key a Flamenco shortcut has claimed. That's how Ctrl+Q-instead-of-Super+Q and *Disable key* work without an `unbind`.
- **Runtime actions** (workspace clicks, log out, screen off) use `flamenco hypr-dispatch`. It tries the Lua dispatchers (`hl.dsp.*`) first, then the classic ones.
- **Unverified Lua forms:** a few are best guesses: focusing a specific window, turning screens off, and monitor rotation/disable. If one is wrong, it's logged and nothing else breaks.

**What works on Hyprland:**
- **The bar:** workspaces, the window title and the keyboard layout come from Hyprland's event socket and `hyprctl`.
- **Settings → Keyboard:** Flamenco functions, apps and commands bind directly. niri actions with a Hyprland equivalent are translated (close window, focus/move to workspace, floating, focus direction, quit, screenshots, layout switching); the rest are skipped with a comment.
- **Settings → Displays and the cursor theme** write their files and reload Hyprland.
- **Screen sharing** uses `hyprland-portals.conf`.
- **`flamenco doctor`** shows Hyprland checks.

<p align="right"><a href="#top">⬆️ Back to top</a></p>

<a id="using-the-shell"></a>

## 🎛️ Using the shell

### 🎹 Keybindings

Change the Flamenco shortcuts in **Settings → Keyboard** (see [Keyboard & shortcuts](#keyboard--shortcuts)); niri's own bindings live in `~/.config/niri/config.kdl`. `Mod+Shift+/` shows every binding.

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

**Flamenco Settings** is also a regular app. Move its window by dragging the title bar, or with Super+drag anywhere. Scroll pages with the wheel or touchpad (scrolling glides, and a fast flick keeps going a little), or grab the scrollbar on the right and drag it; clicking the track jumps there. Find it in the launcher, or any other app launcher, under that name. It starts the shell first if it isn't running.

### 📊 Bar

| Widget | Click | Other |
|---|---|---|
| Launcher (apps icon) | open launcher | |
| Workspaces | go to that workspace | scroll to switch workspaces |
| Active window | window menu: move to another workspace or monitor, float/tile, fullscreen, maximize or center the column, new window, pin to dock, switch to another open window, close, force quit (click twice) | right-click opens the same menu, middle-click closes the window |
| Taskbar | focus the app; click again to cycle through its windows | right-click opens the window menu (move to a workspace or monitor, float, fullscreen, pin, close all, force quit…), middle-click opens a new window |
| Clock | dashboard (Overview, Media, Wallpapers, Weather) | |
| Media | dashboard, Media tab (click again to close) | middle-click play/pause, right-click next track |
| System tray | activate the app | right-click app menu, middle-click secondary action, scroll is passed to the app, hover for tooltip |
| CPU / RAM | performance popout | middle-click opens `btop` |
| Keyboard layout | next layout | only shown with more than one layout |
| Network | control center, Wi-Fi page | |
| Bluetooth | control center, devices page | |
| Battery | control center | |
| Volume | volume popout: slider, output devices, per-app volume, microphone | scroll to change volume, middle-click to mute |
| Brightness | control center | scroll to change brightness |
| Notifications (bell) | notification center | right-click toggles Do Not Disturb |
| Weather | calendar and weather | |
| Quick settings (menu icon) | control center | |
| Power | power menu | |

**Fits any screen.** Each screen's bar measures itself. On narrow or heavily scaled screens, a rotated monitor for example, it compacts step by step until everything fits:
1. Text labels go: the window title and media become icons, the clock drops its date, the stats show CPU only, and the tray shows up to 3 icons.
2. Low-priority widgets hide: window title, stats and weather. Workspaces become dots, and the tray shows 1 icon.
3. Minimal: media and Bluetooth hide, and the tray collapses to its overflow arrow.

The center section stays centered when there's room and otherwise slides so it never overlaps its neighbours. The bar recomputes whenever the screen, scale or widget layout changes. Popouts never grow taller than the screen; their content scrolls instead.

Rearrange, add or remove widgets in **Settings → Bar**. The same page sets the bar's position, style and thickness, the workspace indicator style, and the tray options. Widgets with nothing to show, like battery on a desktop, hide themselves and leave no gap.

### 🔍 Launcher

Start typing to search apps. **Settings → Launcher** sets where it opens: center, top, bottom, any corner, or next to the bar. It also sets the launcher's width. Results are ranked by match quality and how often you launch each app.

| Prefix | Mode |
|---|---|
| *(none)* | apps |
| `=` | calculator, e.g. `= 2^10 / 3`; `Enter` copies the result |
| `>` | run a shell command; the second result runs it in your terminal |
| `;` | search clipboard history; `Enter` copies the entry back |

Move with `↑`/`↓` (or `Ctrl+N`/`Ctrl+P`), launch with `Enter`, close with `Esc`.

### 🎛️ Control center

- **Sliders:** volume, microphone, brightness, and keyboard backlight when the keyboard has one. Click a slider's icon to mute (or switch the keyboard backlight off); click `›` to choose the output or input device.
- **Tiles:** click to toggle. Wi-Fi and Bluetooth have a `›` arrow that opens a list of networks or devices. Click a secured network to enter its password.
- **VPN tile:** connects your VPN, or disconnects it if it's already on. Its `›` arrow lists all your VPNs with on/off switches.
- **Power tile:** click to cycle power profiles. Its `›` arrow opens a page with Power saver, Balanced and Performance, plus battery details.
- **Header:** your name and uptime on the left; settings, lock and power buttons in the top-right corner.
- **Media card:** appears while something is playing. Drag the seek bar to move through the track (a bubble shows where you'll land), or click it to jump. Use the swap button to switch between players.

### 🔈 Volume

Click the volume icon in the bar for the volume popout:
- **Volume:** the volume slider; click its icon to mute.
- **Output:** your output devices; click one to switch to it.
- **Apps:** a volume slider and mute button for each app that's currently playing.
- **Microphone:** level and input device.
- **Sound settings:** a link to that page.

`flamenco ipc volume panel` opens it from a keybinding.

### 🗓️ Dashboard

Click the clock in the bar to open the dashboard. It opens on the tab chosen in **Settings → Clock & Weather**, Overview by default:

| Tab | Shows |
|---|---|
| **Overview** | Big clock, month calendar, your user card, and summary cards for the weather and the current track (click them for the full tab) |
| **Media** | The current track with large cover art, a seek bar you can drag or click, previous/play/next, and shuffle/repeat where the player supports them. With several players, chips let you switch between them. Shows "No media playing" otherwise |
| **Wallpapers** | The wallpaper folder (edit it right there), the picker grid, shuffle and rescan |
| **Weather** | Now (temperature, feels like, wind, humidity, sunrise and sunset), the next 12 hours, and a 1–7 day forecast with rain chance and temperature range |
| **Settings** | Opens the Settings app |

What the Overview and Weather tabs show is set in **Settings → Clock & Weather**:
- the weather location and units
- forecast length
- which weather details appear
- whether the user, media and weather cards show on Overview

### 📈 Performance

Click the CPU/RAM widget for the performance popout:
- **CPU:** usage with a one-minute history graph, load average, cores and frequency
- **Temperatures:** every hardware sensor, colored by how hot it is
- **Memory:** RAM and swap
- **Disks:** usage for each mounted disk
- **Network:** download and upload speed with a graph
- **Processes:** the busiest few

The **btop** button opens a full monitor in your terminal. Sensors, disks and processes are only read while the popout is open.

### 🔔 Notifications

Popups appear in the corner chosen in **Settings → Notifications**.
- Hovering a popup pauses its timer.
- Drag a popup sideways to dismiss it.
- Action buttons appear when the app provides them.

Past notifications stay in the notification center (`Mod+N`). It also has buttons to toggle Do Not Disturb and to clear everything. With DND on, only critical notifications pop up.

### 🔒 Lock screen and power menu

- **Lock** (`Super+Alt+L`, or automatically after the idle time in **Settings → Lock & Login**): type your password and press `Enter`. `Esc` clears what you typed. See [Lock screen options](#lock-screen-options) to use an SDDM theme or another locker instead.
- **Power menu** (`Mod+Escape`): choose with the arrow keys or `h`/`l` and press `Enter`.
  - **Lock and Suspend** act immediately. Suspend locks the screen first.
  - **Log out, Restart and Shut down** must be **held for 3 seconds** (mouse button, or `Enter`/`Space`). The button fills up and shows the seconds left, and the action runs when it's full. Let go early to cancel.

### ✨ Login & logout animations

**Login:** when niri starts the shell at login, a short intro plays. It covers your screen with your wallpaper, blurred and dimmed, plus the flame badge and "Good evening, *you*" with the date, then opens to reveal the desktop. `flamenco restart` and live config reloads skip it.

**Log out, restart, shut down:** after you hold the button in the power menu, an outro covers the screen ("See you soon…", "Restarting…") before the action runs.

**Settings → Appearance → Login & logout** picks each one separately:

| Preset | |
|---|---|
| Bloom | A soft circle opens from the center (or closes in on it), with an accent ring |
| Curtain | Two panels slide apart or together, with lit edges |
| Blinds | Staggered vertical slats |
| Zoom | The cover zooms and fades |
| Fade | A simple cross-fade |
| None | Off |

The same page has a duration slider, a greeting on/off switch, and **Preview** buttons that play either animation without logging you out (also `flamenco ipc session previewIntro` / `previewOutro`).

<a id="lock-screen-options"></a>

### 🔐 Lock screen options

**Settings → Lock & Login → Lock screen** picks what locks your session. This applies everywhere: the idle timeout, `Super+Alt+L`, `flamenco lock`, and the power menu.

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

<a id="fingerprint"></a>

### 👆 Fingerprints

With `fprintd` installed and a supported reader, go to **Settings → Lock & Login → Fingerprint**:
- **Add a fingerprint:** pick a finger, click **Add**, then touch the reader until the bar fills. The page tells you when to lift your finger or move it a little.
- **Remove:** each enrolled finger has its own **Remove** button.
- **Unlock the lock screen with a fingerprint:** on by default once a finger is enrolled. The lock screen shows "Or touch the fingerprint reader" under the password field, and both work. This uses a PAM file inside the shell (`shell/assets/pam/fingerprint`), so nothing in `/etc/pam.d` changes. It works with the built-in lock and SDDM themes, not with a lock command.
- **At the login screen:** turn on **Fingerprint login** in the Flamenco Greeter group. The check itself runs in greetd's PAM setup, which Flamenco doesn't edit. Settings shows the line to add to `/etc/pam.d/greetd` and copies it for you.

> [!NOTE]
> A fingerprint can't unlock your keyring (gnome-keyring, KWallet), which needs your password. If you log in with a finger, the keyring asks for your password the first time an app needs it. Unlocking the lock screen with a finger doesn't have this problem, because the keyring is already open.

<a id="login-screen"></a>

### 🚪 Login screen (greetd)

The login screen at boot is separate from the lock screen. Flamenco uses [greetd](https://sr.ht/~kennylevinsen/greetd/) with **[Flamenco Greeter](https://github.com/niruxx/flamenco-greeter)**, a login screen that looks like the shell. Both are set up in **Settings → Lock & Login**.

**Flamenco Greeter section:**
- **Wallpaper:** your desktop wallpaper, another image (with **Browse**) or a plain color. Blur and dim apply to images.
- **Fonts:** the shell's fonts or others, plus a text size. Colors always follow the shell's palette.
- **Sessions:** turn the session picker on or off, pick the default session (or the last one used), and hide sessions you never use.
- **Users:** list users or type a name, remember the last user and session, and show or hide the power buttons.
- **Fingerprint login:** see [Fingerprints](#fingerprint).
- **Apply:** opens a terminal and asks for your password once. The greeter runs as its own user and can't read your home folder, so the settings, wallpaper and your avatar are copied to `/var/cache/flamenco-greeter`. Your clock format and palette go along too.

**greetd section:**
- **Status:** whether greetd is installed and starts at boot, and which login manager starts now.
- **Greeter:** Flamenco Greeter (inside niri or Hyprland), tuigreet or agreety when installed, or any command. Also the greeter user and the virtual terminal.
- **Auto-login:** start a session for a user at boot without the login screen. Logging out still shows the greeter.
- **Apply:** writes `/etc/greetd/config.toml` and keeps the previous version as `config.toml.bak-<date>` (the very first as `config.toml.orig`). Sections it doesn't manage are kept.
- **Enable greetd:** makes greetd the login manager from the next boot, replacing SDDM, GDM, ly or whatever ran before.

> [!WARNING]
> Settings refuses to write a greeter that isn't installed, so greetd can't be left without a login screen. If a greeter still fails at boot, switch to another TTY (`Ctrl+Alt+F2`), log in, and run `sudo cp /etc/greetd/config.toml.orig /etc/greetd/config.toml`. Or go back to your old login manager with `sudo systemctl enable --force sddm` (or gdm, ly…).

What Settings writes for the greeter is described in [docs/greeter.md](docs/greeter.md).

### 🧩 Desktop widgets

Widgets sit on the desktop, above the wallpaper and under your windows.

**Adding and arranging:** open **quick settings → Desktop widgets** (or `flamenco widgets`, or **Edit desktop** in **Settings → Desktop widgets**). A sidebar opens on that screen:
- **Add:** drag a widget from the sidebar onto the desktop, or click it to drop it near the top left.
- **Move:** drag a placed widget.
- **Resize or remove:** hover a widget for **S / M / L** sizes and a remove button.
- **Style:** pick **Card**, **Glass** or **Bare** (straight on the wallpaper, with a soft shadow) at the bottom of the sidebar. Opacity is on the Settings page.
- **Done:** press **Done**, `Esc`, or click the empty desktop.

**The widgets:**

| Widget | Shows |
|---|---|
| Clock | the time, large, and the date |
| Weather | now, and the next 3 days (5 when large); needs weather on in **Settings → Clock & Weather** |
| System | processor, memory and temperature bars, and the uptime |
| Now playing | cover art, title, artist, and play / previous / next |
| Calendar | this month, with today marked |
| Note | text you type right on the desktop; saved as you type |

**Where they're kept:** in `desktop.widgets` in `~/.config/flamenco/settings.json`. Positions are stored as a share of the screen, so they survive resolution changes. Widgets saved for a screen that isn't connected show on the first screen.

**Clicks:** only the widgets take clicks; the rest of the desktop is untouched.

### 📌 Dock

The dock is off by default. Turn it on in **Settings → Dock**. That page also has:
- **Position:** the bottom, left or right edge, and on a setup with several screens, every screen or just one.
- **Apps:** whether running apps that aren't pinned appear, and a line separating them from pinned ones.
- **Hover and indicators:** app names on hover, and the running indicator as a line, dots or nothing.
- **Hiding:** auto-hide, how close to the edge the pointer must be to reveal the dock, and how long it stays after the pointer leaves.
- **Size:** icon size, spacing, and magnification with how much it zooms.
- **Look:** distance from the screen edge, background opacity, corner roundness, and a border.
- **Pinned apps:** pin apps from a dropdown of everything installed, reorder them, or remove them.

Pinned apps that aren't installed are hidden. A dock with auto-hide off reserves its space, and sits above a bottom bar.

| Click | Action |
|---|---|
| Left | focus the app's window; click again to cycle through its windows |
| Middle | open a new instance |
| Right | a menu: move the window to another workspace or monitor, float, fullscreen, new window, pin or unpin, switch to another window, close (or close all of the app's windows), force quit. For a pinned app that isn't running: Open and Unpin |

With auto-hide on, move the pointer to the bottom edge to reveal the dock.

<p align="right"><a href="#top">⬆️ Back to top</a></p>

<a id="system-settings"></a>

## ⚙️ System settings

<a id="sound"></a>

### 🔊 Sound

**Settings → Sound**
- **Sound theme:** the bundled **Flamenco** theme (the default) or any installed freedesktop sound theme (`/usr/share/sounds`, `~/.local/share/sounds`), with **Preview** buttons for common events. The theme also goes to apps: gsettings for GNOME/GTK, `settings.ini`, and `kdeglobals` for KDE.
- **Event sounds:** a sound when a notification pops up (silent in Do Not Disturb), a click on every volume key press or slider move, a tick on every brightness key press (screen or keyboard), and whether apps play event sounds.
- **Devices:** output and input device and volume.

Sounds are looked up in the chosen theme, then the themes it inherits from, then `freedesktop`, then the bundled `flamenco` theme, so the shell has sounds even with no theme installed. Events a theme lacks fall back to similar ones (for example `brightness-change` → `audio-volume-change`). Sounds are played with `pw-play`. From a terminal: `flamenco sound themes`, `flamenco sound play message-new-instant`.

### 🔑 Keyring

Apps (browsers, mail clients, Git, VS Code…) save passwords through the **Secret Service** (`org.freedesktop.secrets`). Whichever keyring daemon answers it is "your keyring".

**Settings → Keyring** shows which one is answering right now and lets you pick:

| Keyring | Package | Notes |
|---|---|---|
| GNOME Keyring | `gnome-keyring` (+ `seahorse`) | The common choice; COSMIC uses it too |
| KDE Wallet | `kwallet` (+ `kwalletmanager`) | Flamenco turns on its Secret Service support (`kwalletrc`) |
| KeePassXC | `keepassxc` | Also enable *Secret Service Integration* inside KeePassXC |
| oo7 | `oo7` | A newer Rust implementation |
| None | | No keyring starts |

**How the choice sticks:** your choice is written to `~/.local/share/dbus-1/services/org.freedesktop.secrets.service`. That per-user D-Bus activation file overrides the system ones, so the chosen keyring is the one started when an app asks. Choosing one also stops whichever other keyring is running, and keeps GNOME Keyring's own startup out of the way when it isn't chosen. **Reset** goes back to the system default. From a terminal: `flamenco keyring get`, `flamenco keyring use kde`.

> [!NOTE]
> **Unlock at login:** this is done by PAM in `/etc/pam.d`, not by Flamenco. The page shows whether your login manager unlocks the keyring. If it doesn't, the page gives the exact line to add. Flamenco won't edit PAM files itself, because a mistake there can lock you out.

### 🛡️ Firewall

**Settings → Firewall** finds **ufw** or **firewalld**: whichever is running, else whichever is installed. If both are running it warns you, because their rules clash. If neither is installed, it offers to install one.

| | ufw | firewalld |
|---|---|---|
| On / off | ✓ (and at boot) | ✓ (and at boot) |
| Defaults | incoming / outgoing policy, logging level | default zone, which zone each network interface is in |
| Rules | list with delete; add port or range, TCP/UDP/both, allow/deny/reject/limit, optional source address and comment | per zone: open ports and services, add or remove them |

**Applying changes:**
- Changes queue up in a **pending changes** bar at the top, and **Apply** runs them all in a terminal with a single `sudo` prompt. Inputs are validated first, so a bad port or address never reaches the firewall.
- firewalld changes are made permanent and then reloaded.
- ufw only shows its rules to root, so the page reads them via **Load rules** (one `sudo`) and keeps a copy that refreshes after each change.

From a terminal: `flamenco firewall status`, `flamenco firewall apply --json '{"backend":"ufw","ops":[{"op":"add","port":"8080/tcp"}]}'`.

### 📡 Network, printers and power

**Settings → Network**
- **Wi-Fi:** on/off, your saved networks (connect, disconnect, edit), and joining a hidden network.
- **Wired:** each adapter with its cable state, address, speed and MAC, your wired connections, and adding another.
- **Editing a connection:**
  - **General:** name, connecting automatically and its priority, metered, the MAC address shown to the network (the adapter's own, random, or random per network), and MTU.
  - **Wi-Fi only:** the network name, hidden, band (2.4 or 5 GHz), and security (open, WPA/WPA2 or WPA3 Personal) with a new password. Saved passwords are never shown, only replaced.
  - **IPv4 and IPv6:** automatic, manual (addresses and gateway), link-local, shared or off, plus DNS servers, search domains, and IPv6 privacy addresses.
  - **Saving:** a connected connection applies the change right away. Every value is checked before NetworkManager sees it.
  - **Live details:** the addresses, gateway and DNS in use.
- **Administrator rights:** if NetworkManager wants them for a change, **Use sudo** runs the same change in a terminal.
- **Your own app instead:** turn off **Use Flamenco's editor** and Edit opens `nm-connection-editor` (or any app you name) as before.
- **VPNs:** your NetworkManager VPNs, with connect switches and delete buttons.
- **Import:** a WireGuard `.conf` or OpenVPN `.ovpn` file. OpenVPN needs `networkmanager-openvpn`.

**Settings → Printers** manages CUPS:
- **Not installed:** an **Install** button sets up `cups`, `cups-pdf` and `system-config-printer`, and enables the service.
- **Service:** start or stop CUPS, and enable or disable it at boot. These need your password, so they open in a terminal.
- **Printers:** the list, with a star to make one the default, and a **Test page** button. **Add printer** opens `system-config-printer`, or the CUPS web page if that isn't installed.
- **Queue:** waiting jobs, with cancel buttons.

The same actions are available as `flamenco printers …`.

**Settings → Power**
- **Power profile:** Power saver, Balanced, or Performance (if your hardware offers it), plus battery status. The control center's Power tile does the same.
- **Sleep** (applies immediately):
  - **Allow the computer to sleep:** turning this off holds a systemd sleep inhibitor, so nothing can suspend the machine while Flamenco runs: not the lid, idle, the power menu or a sleep key.
  - **Lock before sleeping:** Flamenco watches logind's sleep signal, so closing the lid or a `systemctl suspend` from anywhere locks the screen first. `loginctl lock-session` locks it too.
  - **Suspend when idle:** separate timers for on battery and plugged in (0 = never). Caffeine pauses them.
- **Laptop lid:** what closing the lid does on battery, when plugged in, and with an external monitor: suspend, hibernate, suspend-then-hibernate, lock only, nothing, or power off.
- **Power button:** show Flamenco's power menu, suspend, hibernate, power off, or nothing.

Lid and power-button settings belong to systemd-logind. **Apply** writes `/etc/systemd/logind.conf.d/90-flamenco.conf` with `sudo` in a terminal, then has logind reload it without ending your session. **Back to system defaults** removes that file. *Show the power menu* tells logind to ignore the button and adds an `XF86PowerOff` shortcut instead.

### 🖥️ Screen sharing

Apps share your screen, take portal screenshots and open file pickers through **xdg-desktop-portal**, which hands each feature to a *backend*. On niri, screen capture works through two backends:

| Backend | On niri | |
|---|---|---|
| `xdg-desktop-portal-wlr` | ✓ whole screens | Small; no GNOME dependencies. Can't share a single window |
| `xdg-desktop-portal-gnome` | ✓ screens and single windows | Pulls in GNOME libraries |
| `xdg-desktop-portal-kde` | ✗ for capture | Its screen capture only works with KWin. Its **file chooser** is fine on niri |
| `xdg-desktop-portal-cosmic` | ✗ | Built for COSMIC's compositor |
| `xdg-desktop-portal-gtk` | n/a | File chooser, dark-mode preference and other basics |

**File picker:** choose the open/save dialog: **GTK**, **Qt (KDE)**, **COSMIC** or **GNOME**. Each row shows whether that portal is installed, with **Install** or **Use** buttons. Only the picker is taken from KDE or COSMIC, so their screen capture never comes into play.
- **Which apps follow it:** apps that use the portal do: Flatpaks, Firefox, Chromium and Electron apps.
- **All GTK apps:** turn on **Use it in every GTK app** to route regular GTK apps through it too. This sets `GTK_USE_PORTAL` and `GDK_DEBUG=portals` in niri's environment, and takes effect at your next login.
- **Qt apps** keep their own dialog, so qt6ct theming keeps working.

**Settings → Screen sharing & files** sets this up:
- **Lightweight** installs and uses wlr + gtk.
- **Full** uses gnome.
- **Per-feature dropdowns** cover screen sharing, screenshots, file chooser and everything else, listing only installed backends and marking which work on niri.
- **With wlr:** choose **Ask each time** (click the screen to share; needs `slurp`) or always share a specific screen, and optionally cap the frame rate.

**Apply** writes `~/.config/xdg-desktop-portal/niri-portals.conf`, plus `~/.config/xdg-desktop-portal-wlr/config` when wlr is used. It keeps a one-time copy of your previous files in `~/.local/state/flamenco/backup/portals/`, and restarts the portal service. Apps that were already open may need a restart. From a terminal: `flamenco portals get` / `flamenco portals apply --json '{"ScreenCast":"wlr","Screenshot":"wlr","FileChooser":"gtk"}'`.

### 🩺 System check

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

<p align="right"><a href="#top">⬆️ Back to top</a></p>

<a id="input-and-displays"></a>

## ⌨️ Input & displays

<a id="keyboard--shortcuts"></a>

### ⌨️ Keyboard & shortcuts

**Settings → Keyboard** edits your keyboard setup and shortcuts. Everything is written into `~/.config/niri/config.kdl` and niri applies it immediately.

#### Layout

| Setting | |
|---|---|
| Layouts | Add from the full XKB list, give each a variant, reorder or remove them. The first is the default. With none set, niri follows the system keymap (`localectl`) |
| Switch layouts with | Alt+Shift, Ctrl+Shift, Caps Lock, both Shifts… (shown with two or more layouts). The keyboard widget in the bar switches too |
| Caps Lock | Caps Lock, Escape, Ctrl, swap with Escape or Ctrl, Backspace, or off |
| Compose key | Right Alt, Right Ctrl, Menu, Caps Lock, Right Super |
| Other XKB options | Anything else, comma-separated |
| Repeat delay / rate | With a box to try them in |
| Num Lock | On at startup or not |
| Remember layout | Everywhere, or per window |

#### Shortcuts

Each shortcut is a key combination and one of:

| Kind | Example | Becomes in niri |
|---|---|---|
| **Shell function** | launcher, settings, control center, dashboard, performance, lock, power menu, volume, brightness, keyboard backlight, media, random wallpaper, dark/light, Do Not Disturb, caffeine, night light, restart the shell | `spawn "flamenco" …` |
| **Open app** | any installed app | `spawn "flamenco" "launch" "<app id>"` |
| **Run command** | `grim -g "$(slurp)" - \| wl-copy` | `spawn-sh "…"` |
| **niri action** | `toggle-overview`, `focus-workspace 3`, `screenshot` | `{ toggle-overview; }` |

- **Close windows with:** Super+Q (niri's default), Ctrl+Q, Alt+F4 or Super+Shift+Q. Any choice other than Super+Q *replaces* it, using a **Disable key** entry that comments out niri's `Mod+Q` line. Ctrl+Q is how many apps quit, and they won't receive it while it closes windows.
- **Disable key:** any shortcut can be of type **Disable key**, which switches off a niri binding you don't want (the original line is commented out, and comes back if you delete the entry).
- **Launcher key:** the **Open the launcher with** row switches between Super+Space, Ctrl+Space, Alt+Space and Super+D in one click. niri can't tell left Ctrl from right Ctrl, so Ctrl+Space works with either, and apps no longer receive Ctrl+Space.
- **Choosing keys:** click **Click to record** and press the combination, or type it (`Mod+Shift+S`, `Ctrl+Alt+T`, `XF86AudioPlay`). `Mod` is the Super key. niri catches combinations it already uses before they reach the settings window, so type those instead.
- **Options:** give a shortcut a name for niri's hotkey overlay, and let shell functions, apps and commands work on the lock screen.
- **Conflicts:** duplicates within Flamenco's shortcuts are blocked. If a shortcut takes a key one of your own niri bindings uses, the row says what it replaces.
- **Defaults:** **Reset all to defaults** (click twice) restores the default set. The ↺ button on a row restores just that key's default action.

**What happens in the config:**
- Flamenco keeps its shortcuts in a marked section at the top of the `binds { }` block. Only that section is rewritten; everything else in `binds` is yours.
- When a Flamenco shortcut takes a key you'd bound yourself, your line is commented out with `// flamenco: replaced by a Flamenco shortcut:`, not deleted. Remove the Flamenco shortcut and your binding comes back.
- Every change is checked with `niri validate` first; if niri rejects it, the config isn't touched and the page shows the error.
- A copy of your config from before the first keyboard change is kept at `~/.local/state/flamenco/backup/niri-config.before-keyboard.kdl`.

From a terminal:

```sh
flamenco keyboard get              # current layout settings + shortcuts (JSON)
flamenco keyboard defaults         # the default shortcuts
flamenco keyboard apply --json '{"shortcuts":[{"key":"Mod+B","type":"app","value":"firefox"}]}'
flamenco launch firefox            # what app shortcuts run
```

### 🖱️ Mouse & touchpad

**Settings → Mouse & Touchpad** sets, separately for mice and touchpads:
- **Pointer speed** (−100% to +100%; 0% is the default)
- **Acceleration:** adaptive, or flat (the same distance however fast you move)
- **Scroll speed** and **natural scrolling**
- **Mouse:** left-handed (swapped buttons)
- **Touchpad:** tap to click, disable while typing, and off while a mouse is plugged in

The first time you open the page, it reads what your config already has. Changes are written into `input { mouse { … } touchpad { … } }` in `~/.config/niri/config.kdl`, or into `flamenco-input.conf` / `flamenco/input.lua` on Hyprland, and apply right away. Hyprland has one pointer speed for every device, so the mouse speed is used for touchpads too.

```sh
flamenco pointer get
flamenco pointer apply --json '{"mouseSpeed":-0.3,"mouseAccel":"flat","tap":true}'
```

### 🖥️ Displays

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

**Never leave every screen off** (on by default, in the **Safety** group): if you switch the laptop screen off and later log in without the external display, you'd get a black screen. Instead, when no screen is on (at login, or when you unplug a display), Flamenco switches the laptop screen on for that session. When another display is connected again, it switches the laptop screen back off, so your saved layout is left as it was. Run it by hand with `flamenco display fallback`.

The same operations are available from the command line:

```sh
flamenco display list          # current state of every display
flamenco display list --json
flamenco display apply --json '[{"name":"DP-1","mode":{"w":2560,"h":1440,"r":143998},"scale":1,"transform":"normal","x":0,"y":0}]'
flamenco display save  --json '…'    # same format; writes niri's config
flamenco display fallback      # turn a screen on if none is on
```

<p align="right"><a href="#top">⬆️ Back to top</a></p>

<a id="desktop-and-apps"></a>

## 🪟 Desktop & apps

### 🪟 Windows, workspaces & screen edges

**Settings → Windows & Layout** controls how windows look and behave:
- **Layout:** gaps, an extra margin along the left and right edges, the width of new columns, when to center the focused column, and asking apps not to draw their own title bars.
- **Look:** corner radius, focus ring and border (on/off and width), shadows. The ring and border colors follow your palette's accent, or you can turn that off and type your own hex colors.
- **Focus & pointer:** focus follows the mouse, move the pointer to a window focused from the keyboard, hide the pointer while typing or after some idle seconds, and skipping niri's shortcut cheat sheet at login.

The first time you open the page, it reads what your config already has. On niri, changes are written into `layout { … }`, `cursor`, `input`, `gestures` and `hotkey-overlay` in `~/.config/niri/config.kdl`. Window corners and named workspaces go into a marked block at the end of the file. On Hyprland they go into `flamenco-layout.conf` (or `flamenco/layout.lua`), which the config sources. Run `niri validate` if you've edited the config by hand too.

**Settings → Workspaces:**
- **Named workspaces** always exist, keep their place, and can be pinned to a screen (niri `workspace "web" { open-on-output "DP-1"; }`). Add, rename, re-pin or delete them on the page.
- **Switch back and forth:** choosing the workspace you're on goes back to the previous one.
- **Bar switcher:** style (pills, dots, numbers), hide empty workspaces, scroll on the bar to switch (and reverse the direction), and show how many windows are on the current workspace.

**Settings → Screen edges** turns on hot corners. Each corner of every screen can run an action when the pointer rests there: the overview (niri), the app launcher, control center, notifications, calendar & dashboard, power menu, wallpapers, settings, a screenshot, the previous or next workspace, or locking the screen. You can set how long the pointer has to rest and how big the corner is.

On niri, this page also controls niri's own hot corners:
- **Overview corners:** a corner set to **Overview** becomes niri's own hot corner, so it works while you drag a window too. It reacts at once, so the delay and size don't apply.
- **Other corners:** niri's corner is turned off on every corner that isn't Overview, so it can't take the corner from the action you picked.
- **Older niri:** before niri 25.11, niri only has a top-left corner, so Overview on any other corner is done by Flamenco.
- **Your existing setup:** the first time this version starts, it reads the corners already in your niri config and shows them here as Overview.

```sh
flamenco compositor get
flamenco compositor apply --json '{"gaps":16,"cornerRadius":10,"workspaces":[{"name":"web","output":""}]}'
```

### 📷 Taking screenshots

Screenshots use niri's built-in tools (on Hyprland: `grim`, `slurp` and `wl-copy`). They're always copied to the clipboard.

| Key | Takes |
|---|---|
| `Print` | an area you select |
| `Ctrl+Print` | the whole screen |
| `Alt+Print` | the focused window |

**Settings → Screenshots** takes a screenshot from buttons (Settings gets out of the way first) and sets:
- whether the pointer is included
- whether to save a file or use the clipboard only
- a delay before capturing the screen or a window
- where the file is saved (niri's `screenshot-path`; strftime codes like `%Y-%m-%d` work)

You can rebind the keys under **Settings → Keyboard → Shortcuts**, where the three are listed as Flamenco functions. From a terminal or script:

```sh
flamenco screenshot             # select an area
flamenco screenshot screen --delay 3
flamenco screenshot window --no-save
```

### 📦 Apps: defaults, auto-start & Flatpak

**Settings → Default apps** picks the app for web links, files, email, text, images, video, music, PDFs and archives. The choice is written to `[Default Applications]` in `~/.config/mimeapps.list` for every file type in that group, so every app that opens files honors it. The terminal is saved to `~/.config/xdg-terminals.list` and is also the terminal the shell opens.

**Settings → Auto-start** lists the apps that start at login from `~/.config/autostart` and `/etc/xdg/autostart`:
- Turn entries on or off. A system entry is switched off with a `Hidden=true` copy in your own folder, and your copy is removed again when you switch it back on.
- Add an installed app, or a plain command with a name.
- Flamenco starts these entries a few seconds after the shell starts, once per login. It skips any app that's already running, and it skips everything when systemd's `xdg-desktop-autostart.target` is already handling them. You can turn this off at the top of the page.

**Settings → Flatpak permissions** picks an installed Flatpak app and shows each permission with what the app asks for and what it actually gets. Set each one to:
- **Default:** what the app asks for
- **Allow**
- **Read** (folders only): read-only access
- **Deny**

Changes are saved as your own overrides in `~/.local/share/flatpak/overrides/APP`, the same file `flatpak override --user` writes, and apply the next time the app starts. **Reset** removes them.

```sh
flamenco defaults get
flamenco defaults set browser firefox
flamenco autostart list
flamenco autostart add-command "Sync notes" "rclone sync ~/notes remote:notes"
flamenco flatpak info org.mozilla.firefox
flamenco flatpak set org.mozilla.firefox --json '{"filesystems":{"home":"deny","xdg-download":"rw"}}'
flamenco flatpak reset org.mozilla.firefox
```

**Settings → About** shows the system details (OS, computer, processor, graphics, memory, disk, kernel, compositor, Quickshell, packages, uptime) and copies them for bug reports. Also `flamenco about`.

<p align="right"><a href="#top">⬆️ Back to top</a></p>

<a id="wallpapers-and-themes"></a>

## 🎨 Wallpapers & themes

### 🖼️ Wallpapers

> [!TIP]
> Flamenco draws the wallpaper itself, so **you don't need `swaybg`, `swww` or any other wallpaper program**. Remove those from your niri config, or they'll cover the shell's wallpaper.

**Where images come from:** the folder `~/Pictures/Wallpapers` by default, including its subfolders (up to 4 levels deep).
- **Changing it:** type a path in the folder field (it applies a moment after you stop typing), or click **Browse** to pick one. Browse opens the portal's file chooser (the one picked on the Screen sharing page), or kdialog, zenity or yad when there's no portal; the button says **No file chooser** if none of them is installed. `~`, `$HOME` and paths relative to your home folder all work.
- **Feedback:** the field shows whether the folder was found and how many images it has. Supported formats are `.jpg`, `.jpeg`, `.png`, `.bmp`, `.gif`, `.webp`, `.avif` and `.jxl`; the last three need `qt6-imageformats` (and `kimageformats` for AVIF/JPEG XL). File names with spaces or symbols like `#` and `%` are fine. Hidden files and folders are skipped, including the `._name.jpg` metadata files macOS leaves on USB drives and shares. On first start the first image found is used. With no images you get a plain background in the palette's color.

**Setting a wallpaper**, any of these:

- **Picker:** `Mod+W` (or `flamenco wallpapers`). Click a thumbnail; the shuffle button picks a random one.
- **Settings → Wallpaper:**
  - change the folder
  - choose the transition and its duration, and preview it with **Try it**:
    - *Mosaic*: tiles bloom out from the center
    - *Ripple*: a circle led by rings
    - *Sweep*: a diagonal band with a glowing edge
    - *Blinds*: staggered slats
    - *Circle*, *Wipe*, *Focus* (sharpens out of a blur), *Fade*
    - *Mix*: a random one each time
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

The same wallpaper is used on every screen. Flamenco draws it twice: once on your workspaces, and once blurred and dimmed in niri's *backdrop*, which you see behind the workspaces in the overview and between them while switching. The niri config's `layer-rule` puts that second copy in the backdrop. It also appears blurred on the lock screen.

**Colors from your wallpaper:** pick *From wallpaper* in **Settings → Appearance → Palette**. This needs `matugen`. The palette is regenerated whenever the wallpaper changes, and it flows through to your Qt and GTK apps too.

### 🎨 Themes

Theming has two layers: the **shell palette**, which colors the shell itself, and **app theming**, which pushes that palette to your Qt and GTK applications.

#### 🌈 Shell palette

In **Settings → Appearance**:

- **Color mode:** dark or light.
- **Palette:** Flamenco, Breeze, Catppuccin, Rosé Pine, Nord, Tokyo Night, Gruvbox, Everforest, Dracula, Kanagawa, Solarized, One Dark, Monochrome, or *From wallpaper*.
- **Accent:** keep the palette's accent, pick a swatch, or type any hex color. It recolors the whole shell, the window focus ring and your themed apps.
- **Layout presets:** one click sets up the bar, dock, launcher and notifications:
  - *Modern*: floating top bar, centered clock
  - *Minimal*: slim islands with just the essentials
  - *Classic*: a Windows-style taskbar at the bottom, with running apps
  - *Dock & menu bar*: a thin top bar and a dock, macOS-style
  - *Vertical*: a bar on the left side
- **Shape and surfaces:** corner roundness, panel opacity, shadows, dimming behind panels, and **Connect panels to the bar**. With that last one, quick settings, the calendar and the other panels grow out of the bar as one surface, with curved joins and no gap showing the wallpaper. It doesn't apply to the Islands bar style. Panels opened from the bar open on the same side as the widget you clicked: a clock in the right section opens the calendar on the right, and one in the center opens it under the clock.
- **Motion:** animation speed; 0% turns animations off.
- **Typography:** interface and monospace fonts (Google Sans Flex and Google Sans Code by default), picked from dropdowns of installed fonts (system and `~/.local/share/fonts`) and shown in their own typeface, plus UI scale and a live preview.
- **Icons:** filled (the Material 3 Expressive look, the default) or outlined, and how heavy the strokes are.

From the command line, or bound to keys in niri:

```sh
flamenco theme list             # available palettes
flamenco theme catppuccin       # switch palette
flamenco theme dark             # or: light, toggle
```

Dark mode can also be toggled from a control-center tile.

#### 🧩 Qt and GTK apps

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

<p align="right"><a href="#top">⬆️ Back to top</a></p>

<a id="troubleshooting"></a>

## 🛟 Troubleshooting

> [!TIP]
> Start with `flamenco doctor` (or **Settings → System check**): it lists anything missing and gives the exact install command.

| Symptom | Fix |
|---|---|
| Icons show as words ("apps", "settings") | The icon font didn't load. Make sure `shell/assets/fonts/MaterialSymbolsRounded.ttf` exists in the installed shell (`flamenco doctor` checks for it) and restart the shell |
| Plain colored background, no wallpaper | `~/Pictures/Wallpapers` is missing or empty. Add images, or point **Settings → Wallpaper → Folder** at another folder (type a path, or use **Browse**). The icon next to the field shows whether the folder was found |
| Dark background on workspaces, wallpaper only visible while switching | A `layer-rule` with `place-within-backdrop` matches the desktop wallpaper. Only `flamenco-wallpaper` (the blurred backdrop copy) should be in the backdrop; don't add a rule for `flamenco-desktop` |
| Wallpaper hidden or flickering | Another wallpaper program or shell is running (`swaybg`, `swww`, DMS). Remove it from your niri config |
| niri says `duplicate node binds` | Move the Flamenco key lines into your existing `binds { }` block |
| Qt apps ignore the theme | `QT_QPA_PLATFORMTHEME` isn't `qt6ct`. Set it (the niri snippet does), log in again, and restart the app |
| Cursor theme doesn't change | Press **Apply now** in **Settings → App Theming** and check `~/.config/niri/config.kdl` for the `cursor { }` block. Restart apps that were already open |
| Bar widgets overlap or disappear on one screen | That screen's bar is compacting to fit. Remove widgets you don't need in **Settings → Bar**, lower **Thickness**/**Scale**, or move the bar to a longer edge |
| Dock never appears | Check **Show dock** in **Settings → Dock**. With auto-hide on, push the pointer against the bottom edge, or raise **Reveal edge**; on some VM displays the pointer can't reach the last few pixels |
| Display change left a blank screen | Wait 15 seconds; it reverts on its own. If you already kept it, restore `~/.local/state/flamenco/backup/niri-config.before-displays.kdl` |
| Screen sharing shows nothing to pick, or fails | Open **Settings → Screen sharing**: screen sharing must use **wlr** or **gnome** (kde and cosmic can't capture on niri). With wlr and **Ask each time**, install `slurp`. Restart the app afterwards |
| A shortcut does nothing | Check it in **Settings → Keyboard** and look at the status line for niri's error. `Mod+Shift+/` in niri shows what each key does. App shortcuts need the app's desktop file; try `flamenco launch <id>` in a terminal |
| Locked in by an SDDM theme | Press **Ctrl+Alt+Shift+L** on the lock screen to switch to the built-in lock |
| Tray menu misplaced or not opening | Turn on **Settings → Bar → Native Qt menus** |
| **Black screen after logging in to niri** | Switch to a text console (`Ctrl+Alt+F3`), log in, and run `flamenco doctor`.<br>**In a virtual machine** this is almost always missing 3D acceleration: niri has no software renderer, so without it nothing is drawn. Turn on 3D in the VM settings (virt-manager: Video *VirtIO* with *3D acceleration*, and *OpenGL* on the Spice display; VirtualBox: *VMSVGA* with *3D acceleration*). The check *VM 3D acceleration* shows whether it's on.<br>**Otherwise:** if niri runs (`Mod+T` opens a terminal) but there's no bar or wallpaper, the shell didn't start. Check `flamenco logs` or run `flamenco run --fg` |
| The shell crashes on start | Run `flamenco run --fg` and read the error. The crash report is under `~/.cache/quickshell/crashes/` |

<p align="right"><a href="#top">⬆️ Back to top</a></p>

<a id="reference"></a>

## 📚 Reference

### 💻 The `flamenco` command

<details>
<summary>Show every command</summary>


```
flamenco run [--fg]             start (daemonized unless --fg)
flamenco kill | restart
flamenco launcher | control | notifications | calendar | wallpapers | power
flamenco settings [page]        appearance, apps, bar, dock, windows, workspaces, edges, displays, screenshots,
                                defaults, autostart, flatpak, wallpaper, notifications, launcher, lock, clock, about
flamenco lock
flamenco volume up|down|mute|mic-mute|set N
flamenco brightness up|down|set N
flamenco brightness kbd up|down|set N|toggle   # keyboard backlight; no argument prints it
flamenco media toggle|next|previous
flamenco wallpaper [set PATH | random | next]
flamenco theme PALETTE | dark | light | toggle | list | apply-apps
flamenco apps-theme --json SPEC | --restore
flamenco pick folder|image [START]   # choose a folder or an image with the portal file chooser
flamenco greeter status | sessions | apply --json SPEC | greetd --json SPEC | enable   # login screen
flamenco fingerprint status [--json] | enroll FINGER | delete FINGER|all   # fprintd fingerprints
flamenco widgets [edit|done|toggle]   # arrange desktop widgets
flamenco net list | get UUID | set UUID --json SPEC | up|down|delete UUID | add-ethernet | add-wifi --json SPEC   # Wi-Fi and wired connections
flamenco portals get | apply --json SPEC
flamenco fonts [--json]
flamenco sound themes | play EVENT | find EVENT
flamenco firewall status [--json] | apply --json SPEC | load
flamenco keyring get | use gnome|kde|keepassxc|oo7|none|default
flamenco power logind get | apply --json SPEC | reset
flamenco keyboard get | defaults | functions | layouts | apply --json SPEC
flamenco pointer get | apply --json SPEC
flamenco launch APP_ID
flamenco display list | apply --json SPEC | save --json SPEC | fallback
flamenco compositor get | apply --json SPEC   gaps, focus ring, corners, cursor, named workspaces
flamenco screenshot [region|screen|window] [--delay N] [--no-save] [--pointer|--no-pointer]
flamenco defaults get | set CATEGORY APP_ID
flamenco autostart list | set ID on|off | add APP_ID | add-command NAME CMD | remove ID | run
flamenco flatpak list | info APP | set APP --json CHANGES | reset APP
flamenco about [--json]
flamenco list-themes [--json]   installed icon / cursor / GTK / Qt-style / Kvantum / SDDM themes
flamenco ipc TARGET FUNCTION [ARGS...]
flamenco doctor [--json]
flamenco niri-config
```

</details>

### 🗃️ Settings file

All settings live in `~/.config/flamenco/settings.json`. The shell watches the file, so edits made by hand apply immediately. Deleting the file resets everything to defaults on the next start.

### 🗂️ Repository layout

```
bin/flamenco                 CLI: launcher, IPC client, Qt/GTK theme generator
shell/shell.qml              root: modules + IPC handlers
shell/Commons/               Theme (tokens + motion curves), Settings (JSON), Palettes, ColorGen, Paths
shell/Services/              Niri, Audio, Brightness, Network, BluetoothState, Power, Media, Notifs,
                             Wallpapers, Weather, Apps, SystemStats, Time, Toggles, Panels, AppTheming,
                             Compositor, Edges
shell/Widgets/               F* component library (buttons, switch, slider, dropdown, tiles, ripple, OverlayPanel…)
shell/Modules/               Bar, Background, ControlCenter, Launcher, Notifications, OSD, Lock,
                             Session, Calendar, WallpaperPicker, Dock, Edges (hot corners), Settings
data/                        desktop entry and icon for Flamenco Settings
packaging/arch/              PKGBUILD and a makepkg-free build script
tools/qmlcheck.py            static QML checks
tools/screenshots.sh         regenerates docs/screenshots/
tools/readme-assets.py       draws the README artwork in docs/assets/
```

<a id="development"></a>

### 🛠️ Development

`tools/qmlcheck.py` runs static checks over the QML without needing Qt (unknown types, unbalanced braces, and the `Behavior` patterns that crash Qt 6.12). Run it before building a package.

`tools/screenshots.sh` regenerates the README screenshots in `docs/screenshots/`. Run it inside a niri session with the shell running; it needs `grim`, and `notify-send` for the notification shots. It opens each panel in turn, captures it, and puts your palette and color mode back when it's done.

`tools/readme-assets.py` draws the README banner and palette cards (`docs/assets/*.svg`, dark and light) from `shell/Commons/Palettes.qml`. Re-run it after changing a palette.

<p align="right"><a href="#top">⬆️ Back to top</a></p>

<a id="todo"></a>

## TODO
- [x] Add dock options to change the top bar from top to each corner of the screen (Settings → Bar → Position: top / bottom / left / right)
- [x] Under app theming ensure a drop down can be used instead of typing in the theme - this should be able to select the ones installed.
- [x] Include app Indicators support
- [x] Improve the top left indicator as there's a lot of spaces between them.
- [x] Sounds for Volume and Brightness are not functional.
- [X] Add Cursor control settings to manage speed
- [X] Alternative Display Manager Support
- [X] First Time Run Setup Screen (dms checker)
- [ ] Full Feature Parity
- [X] Quality of Life Improvements
- [ ] Flatpak Permissions Management
- [ ] About page
- [ ] Auto-start settings
- [ ] Workspaces Settings
- [ ] Default Applications Settings
- [ ] More Color scheme and theme settings for the niri/flamenco shell specific
- [ ] Other Quality of life settings entries.
- [ ] Screen Edges customization and more layout presets in personalization
