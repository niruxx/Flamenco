#!/usr/bin/env bash
# Capture README screenshots of a running Flamenco Shell.
#
#   tools/screenshots.sh [output-dir]      (default: docs/screenshots)
#
# Run inside a niri session with the shell already running. Needs `grim`;
# `notify-send` (libnotify) is optional and fills the notification shots.
# Your palette and color mode are restored afterwards.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
out=${1:-$here/../docs/screenshots}
settle=${SETTLE:-1.2}   # seconds to let animations finish before each capture
settings=${XDG_CONFIG_HOME:-$HOME/.config}/flamenco/settings.json

command -v grim >/dev/null || { echo "screenshots: grim is not installed (pacman -S grim)" >&2; exit 1; }
command -v flamenco >/dev/null || { echo "screenshots: flamenco is not on PATH" >&2; exit 1; }
flamenco ipc theme list >/dev/null 2>&1 || { echo "screenshots: the shell isn't running (flamenco run)" >&2; exit 1; }

mkdir -p "$out"

# remember palette + mode so we can put them back
read -r orig_palette orig_mode < <(python3 - "$settings" <<'EOF'
import json, sys
try:
    a = json.load(open(sys.argv[1])).get("appearance", {})
except Exception:
    a = {}
print(a.get("palette", "flamenco"), a.get("mode", "dark"))
EOF
)

close_all() {
    for p in launcher control notifications calendar wallpapers power; do
        flamenco "$p" close >/dev/null 2>&1 || true
    done
    flamenco ipc settings close >/dev/null 2>&1 || true
}

restore() {
    close_all
    flamenco theme "$orig_palette" >/dev/null 2>&1 || true
    flamenco theme "$orig_mode" >/dev/null 2>&1 || true
}
trap restore EXIT

shot() {
    sleep "$settle"
    grim "$out/$1.png"
    echo "  $out/$1.png"
}

open_panel() {
    close_all
    sleep 0.4
    flamenco "$1" open
}

echo "Capturing to $out"

flamenco theme "$orig_palette"
flamenco theme dark
close_all
shot desktop

if command -v notify-send >/dev/null; then
    notify-send -a "Flamenco" "Welcome to Flamenco" "Popups slide in, pause on hover, and swipe away."
    notify-send -a "Music" "Now playing" "Bulerías por Soleá"
    shot notification-popups
fi

open_panel launcher;      shot launcher
open_panel control;       shot control-center
open_panel notifications; shot notification-center
open_panel calendar;      shot calendar
open_panel wallpapers;    shot wallpaper-picker
open_panel power;         shot power-menu

close_all
flamenco settings appearance; shot settings-appearance
flamenco settings apps;       shot settings-app-theming
flamenco settings bar;        shot settings-bar
close_all

# a light-mode look at the control center
flamenco theme light
open_panel control; shot control-center-light

# a few palettes on the desktop
for p in catppuccin rosepine nord gruvbox; do
    close_all
    flamenco theme dark
    flamenco theme "$p"
    sleep 0.6   # palette cross-fade
    shot "palette-$p"
done

echo "Done. The lock screen isn't captured: screenshot tools can't see it while the session is locked."
