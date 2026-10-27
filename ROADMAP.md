## Fixes
Bluetooth Settings Options - Bluetooth does not scan from the quicksettings and no way to pair - this will get fixed. (Done in 0.56.0: it searches while the Bluetooth page is open, nearby devices pair with a click (passkey and PIN questions in a card), and Settings → Bluetooth has it all)

## Features from Noctalia and DMS
What those two shells have that Flamenco doesn't yet, from their settings, widgets and modules (Noctalia's default settings and translations, DMS's source tree, October 2026). Flamenco already covers the rest (greeter, users, online accounts, wellbeing, printers, keybinds, displays, OSD, desktop widgets, clipboard, notepad, color picker, updates…). (N) Noctalia, (D) DMS.

### Most useful first
- [x] **Polkit authentication agent** (D) (done in 0.57.0): the "an app wants your password" dialog, in Flamenco's look. Today another agent (polkit-gnome, polkit-kde…) has to be running, and Flamenco's own pkexec actions depend on it.
- [ ] **Task manager** (D): a process list to search, sort by CPU or memory, and end or kill processes. The Performance panel only shows the top few.
- [x] **Toasts for changes** (N) (done in 0.57.0; airplane mode not yet): a small pop-up when Caps Lock or Num Lock, the keyboard layout, the power profile, Wi-Fi, Bluetooth, airplane mode, Do Not Disturb or night light change.
- [x] **Low and critical battery warnings** (N, D) (done in 0.57.0): a notification (and optionally a sound) at the low level, and before the battery runs out.
- [x] **Separate idle timers on battery and plugged in** (D), and **hibernate** after a while (N, D) (done in 0.57.0): lock, screen off and suspend times for each.
- [x] **Launcher additions** (N, D) (done in 0.58.0; file search uses plocate / fd, not dsearch):
  - file search (DMS uses dsearch);
  - a web-search entry;
  - open windows;
  - Flamenco settings;
  - session actions (lock, log out, restart);
  - pinned apps, and sorting by most used;
  - a grid / app-drawer view with categories.
- [x] **Notification rules** (D) (done in 0.58.0; markdown already rendered): per app, never pop up, always pop up, mute the sound, change the urgency or timeout. Also per-urgency timeouts and rich text / markdown in notifications (N).
- [x] **Window rules editor** (D) (done in 0.58.0): per app, open floating, at a size, on a workspace or screen, with an opacity (written as niri window rules).

### Bar widgets
- [ ] Caps Lock / Num Lock indicator (N, D) (the toasts show them; a bar widget is still to do)
- [ ] Network speed: upload and download (D)
- [ ] Disk usage (D)
- [ ] GPU usage and temperature on their own (D; the CPU/RAM widget has CPU temperature only)
- [ ] VPN status and toggle (D)
- [ ] Custom widget: runs your script, shows its output, runs a command on click (N)
- [ ] Spacer (N)
- [ ] Media: the current lyric line (D)
- [ ] Bar clicks: what scrolling, middle-click and right-click on the empty bar do (N)
- [ ] Bar: hide while the overview is open; show briefly when switching workspaces while it's auto-hidden (N)

### Desktop and panels
- [ ] Right-click menu on the desktop: change wallpaper, open Settings, add a widget, open a terminal (D)
- [ ] Dynamic island: a notch-style pill that grows for media, notifications and volume changes (D)
- [ ] Session menu: a countdown before the action, restart into firmware (UEFI) setup, number keys for each action, switch user (N, D)
- [ ] Hooks: run your own commands when the wallpaper or dark mode changes, on lock and unlock, at startup, after colors are generated (N)
- [ ] Changelog after an update: what's new, shown once (N, D)
- [ ] Browser picker: choose which browser opens a link (D)
- [ ] Share Wi-Fi as a QR code, and a QR code generator (D)
- [ ] Terminal sessions (tmux / zellij) to pick from and attach to (D)

### Settings additions
- [ ] Region and language: translations of the shell, and number and date formats (N, D) (0.59.0: Settings → Region & Language sets the system language and formats, adds languages, and the shell's date style and first day of the week; translating the shell's own text is still to do)
- [x] Wallpaper (N) (done in 0.59.0):
  - a solid color instead of a picture;
  - fill modes (fill, fit, center, tile);
  - a folder per screen;
  - favorites;
  - separate light and dark wallpapers.
- [x] Media: a preferred player, and players to ignore (N) (done in 0.59.0)
- [x] Bluetooth: signal strength, reconnecting known devices automatically, hiding unnamed devices (N) (done in 0.59.0)
- [x] Dock (N) (done in 0.59.0):
  - group an app's windows (with indicator styles);
  - icons tinted to the theme;
  - only the apps on this screen.
- [x] System monitor: warning and critical levels (with colors) for CPU, GPU, memory, temperature and disk (N) (done in 0.59.0)
- [x] Brightness: a lowest level it won't go below (N) (done in 0.59.0)
- [x] Plugins: a browser for the plugin registries, update notices, and a lock file to reproduce a setup (N, D) (done in 0.59.0; the browser was already there)
- [x] Shell themes from a registry, beside Get themes (D) (done in 0.59.0: Get themes → Palettes, DMS's 47 themes as Flamenco palettes)

### Bigger ones
- [ ] More compositors: Sway, MangoWC, labwc, Scroll (N, D; Flamenco does niri and Hyprland)
