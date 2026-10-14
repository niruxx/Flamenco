# Flamenco Greeter: settings handoff

This describes what Flamenco Shell writes for [Flamenco Greeter](https://github.com/niruxx/flamenco-greeter), and where it writes it. It is the contract between the two projects. The shell side lives in `bin/flamenco` (`flamenco greeter …`) and in **Settings → Lock & Login**.

## How the greeter is started

greetd runs the greeter as its own user (normally `greeter`), much like dms-greeter. `/etc/greetd/config.toml`:

```toml
[terminal]
vt = 1

[default_session]
command = "flamenco-greeter --command niri"   # or: --command Hyprland
user = "greeter"
```

`--command` names the compositor the greeter runs inside. The Settings app offers these two presets, but any command can be typed in. The settings app won't write a `command` whose program isn't installed. That way a missing greeter can't leave the machine without a login screen.

## The settings folder

The greeter user can't read anyone's home folder. So when you click **Apply**, `flamenco greeter apply` copies everything into one folder, `/var/cache/flamenco-greeter/`:

| Path | Owner / mode | What |
|---|---|---|
| `./` | `greeter` (the `default_session` user), `0755` | The greeter may write its own state here, e.g. `memory.json` with the last user and session |
| `config.json` | `root`, `0644` | The settings, below |
| `wallpaper.<ext>` | `root`, `0644` | The background image, when `wallpaper.mode` is `"image"` |
| `avatars/<user>.<ext>` | `root`, `0644` | User pictures, keyed by login name |

Each Apply replaces `config.json`, `wallpaper.*` and `avatars/*`. Anything else in the folder, like the greeter's own state, is left alone.

## `config.json` (version 1)

```json
{
  "version": 1,
  "generator": "flamenco-shell 0.15.0",
  "appearance": {
    "dark": true,
    "colors": { "bg": "#…", "surface": "#…", "surfaceHigh": "#…", "surfaceHighest": "#…", "border": "#…",
                "text": "#…", "textDim": "#…", "accent": "#…", "onAccent": "#…", "accent2": "#…",
                "accent3": "#…", "error": "#…", "warning": "#…", "success": "#…" },
    "fontFamily": "Inter",
    "monoFamily": "JetBrains Mono",
    "fontScale": 1.0,
    "roundness": 1.0
  },
  "wallpaper": {
    "mode": "image",
    "file": "wallpaper.jpg",
    "fillMode": "crop",
    "blur": 0.0,
    "dim": 0.25,
    "color": "#16161e"
  },
  "clock": { "use24h": true, "showSeconds": false },
  "sessions": { "picker": true, "default": "niri.desktop", "hidden": ["gnome-classic.desktop"] },
  "users": { "list": true, "rememberLast": true, "default": "", "avatars": { "kyle": "avatars/kyle.png" } },
  "power": { "buttons": true }
}
```

| Key | Meaning |
|---|---|
| `version` | Schema version. Bumped only for incompatible changes. A greeter should ignore keys it doesn't know. |
| `appearance.colors` | The shell's palette roles at the time of Apply, as `#rrggbb` (or `#aarrggbb`). These are the same roles as the shell's `Theme`. |
| `appearance.fontScale` | A text size multiplier, 0.5–2.0. |
| `appearance.roundness` | The shell's corner-radius multiplier. |
| `wallpaper.mode` | `"image"` means draw `file` (relative to this folder). `"color"` means fill with `color`. |
| `wallpaper.fillMode` | `crop`, `fit` or `stretch`, the same as the shell's. |
| `wallpaper.blur`, `wallpaper.dim` | 0–1. |
| `sessions.default` | A session file name from `/usr/share/wayland-sessions` or `/usr/share/xsessions`. `""` means the last session used. |
| `sessions.hidden` | Session file names to leave out of the picker. |
| `sessions.picker` | `false` means always start `default` (or the last session used) without offering a choice. |
| `users.list` | `false` means ask for a user name instead of listing users. |
| `users.rememberLast` | Preselect the last user and session. The greeter keeps these in its own state file. |
| `users.avatars` | Login name → path relative to this folder. Users not listed fall back to AccountsService, then to an initial. |
| `power.buttons` | Show suspend, restart and shut down. |

If `config.json` is missing or unreadable, the greeter should use its own defaults.

## Commands (shell side)

```sh
flamenco greeter status [--json]        # greetd, the greeter, sessions, users, last applied config
flamenco greeter sessions               # id <TAB> name <TAB> Exec
flamenco greeter apply --json SPEC      # write /var/cache/flamenco-greeter (needs root)
flamenco greeter greetd --json SPEC     # edit /etc/greetd/config.toml (needs root, keeps backups)
flamenco greeter enable                 # systemctl enable --force greetd.service (needs root)
```

`greetd` keys:

| Key | Type | Meaning |
|---|---|---|
| `command` | string | The greeter command |
| `user` | string | The greeter user |
| `vt` | int or `next` / `current` / `none` | Which virtual terminal greetd uses |
| `autologin` | bool | `true` writes `initial_session` |
| `autologinUser` | string | The user to log in |
| `autologinCommand` | string | The session to start |

Before writing `/etc/greetd/config.toml`, the previous version is saved as `config.toml.bak-<date>`. The very first version is also kept as `config.toml.orig`. Sections and keys the Settings app doesn't manage, like `[general]`, are kept as they are.

For testing, `FLAMENCO_GREETD_CONFIG` and `FLAMENCO_GREETER_DIR` override the two paths.
