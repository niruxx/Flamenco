-- Hyprland (Lua) configuration for Flamenco Shell, written by `flamenco hyprland-config`.
-- Your previous config was backed up next to this file (hyprland.lua.bak-*).
-- Reference: https://wiki.hypr.land/Configuring/Start/
--
-- Flamenco Settings writes the files in ./flamenco/ (shortcuts, keyboard,
-- cursor, displays, window look). They're loaded with pcall, so a problem in one of them
-- is logged instead of breaking this config.

local function flamenco(module)
    local ok, err = pcall(require, "flamenco." .. module)
    if not ok then
        print("flamenco: could not load flamenco/" .. module .. ".lua: " .. tostring(err))
    end
end

-- keys taken by Flamenco shortcuts (filled in by flamenco/binds.lua)
flamenco_taken = flamenco_taken or {}

local function norm(keys)
    local parts = {}
    for p in string.gmatch(keys, "[^+]+") do
        parts[#parts + 1] = string.upper((p:gsub("^%s+", ""):gsub("%s+$", "")))
    end
    local key = table.remove(parts)
    table.sort(parts)
    parts[#parts + 1] = key
    return table.concat(parts, "+")
end

-- default bindings yield to Flamenco shortcuts on the same key
local function bind(keys, action, opts)
    if flamenco_taken[norm(keys)] then
        return
    end
    hl.bind(keys, action, opts)
end

------------------
---- MONITORS ----
------------------

-- any screen not configured in Settings → Displays
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

local terminal = "@@TERMINAL@@"

-------------------
---- AUTOSTART ----
-------------------

-- The shell: bar, wallpaper, notifications, launcher, lock screen…
-- Its log is at ~/.cache/flamenco/shell.log if it doesn't appear.
hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("flamenco run")
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- Qt apps follow the Flamenco palette through qt6ct; Electron apps run natively on Wayland.
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in  = 6,
        gaps_out = 12,
        border_size = 2,
        col = {
            active_border   = { colors = { "rgb(ff5d73)", "rgb(ffb867)" }, angle = 45 },
            inactive_border = "rgb(46343a)",
        },
        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle",
    },

    decoration = {
        rounding       = 12,
        rounding_power = 2,
        shadow = {
            enabled      = true,
            range        = 20,
            render_power = 3,
            color        = 0x70000000,
        },
        blur = {
            enabled = true,
            size    = 6,
            passes  = 3,
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
    },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
    },
})

hl.curve("emphasized", { type = "bezier", points = { {0.05, 0.7}, {0.1, 1} } })
hl.curve("linear",     { type = "bezier", points = { {0, 0},      {1, 1}   } })
hl.curve("easy",       { type = "spring", mass = 1, stiffness = 238.1191, dampening = 24.21279333 })

hl.animation({ leaf = "global",     enabled = true, speed = 10,  bezier = "default" })
hl.animation({ leaf = "windowsIn",  enabled = true, speed = 4.1, spring = "easy",       style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.5, bezier = "linear",     style = "popin 87%" })
hl.animation({ leaf = "fade",       enabled = true, speed = 3,   bezier = "emphasized" })
hl.animation({ leaf = "layers",     enabled = true, speed = 3.8, bezier = "emphasized" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2,   bezier = "emphasized", style = "slide" })

---------------
---- INPUT ----
---------------

hl.config({
    input = {
        follow_mouse = 1,
        touchpad = {
            natural_scroll = true,
        },
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})

-- Flamenco shortcuts first, so the defaults below can step aside for them
flamenco("binds")

---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"

bind(mainMod .. " + T",      hl.dsp.exec_cmd(terminal))
bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
bind(mainMod .. " + Q",      hl.dsp.window.close())
bind(mainMod .. " + V",      hl.dsp.window.float({ action = "toggle" }))
bind(mainMod .. " + P",      hl.dsp.window.pseudo())
bind(mainMod .. " + J",      hl.dsp.layout("togglesplit"))
bind(mainMod .. " + SHIFT + E", hl.dsp.exit())

bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

for i = 1, 10 do
    local key = i % 10
    bind(mainMod .. " + " .. key,          hl.dsp.focus({ workspace = i }))
    bind(mainMod .. " + CTRL + " .. key,   hl.dsp.window.move({ workspace = i }))
end

bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- screenshots (grim + slurp)
bind("Print",        hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy"))
bind("CTRL + Print", hl.dsp.exec_cmd("grim - | wl-copy"))

-- media keys: the shell's OSD, plain tools if it isn't running
bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("flamenco volume up || wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("flamenco volume down || wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),    { locked = true, repeating = true })
bind("XF86AudioMute",         hl.dsp.exec_cmd("flamenco volume mute || wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),   { locked = true })
bind("XF86AudioMicMute",      hl.dsp.exec_cmd("flamenco volume mic-mute || wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("flamenco brightness up || brightnessctl --class=backlight set +5%"),   { locked = true, repeating = true })
bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("flamenco brightness down || brightnessctl --class=backlight set 5%-"), { locked = true, repeating = true })
bind("XF86AudioPlay",         hl.dsp.exec_cmd("flamenco media toggle || playerctl play-pause"), { locked = true })
bind("XF86AudioNext",         hl.dsp.exec_cmd("flamenco media next || playerctl next"),         { locked = true })
bind("XF86AudioPrev",         hl.dsp.exec_cmd("flamenco media previous || playerctl previous"), { locked = true })

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

hl.window_rule({
    name  = "flamenco-floating",
    match = { title = "^(Flamenco Settings|Flamenco Setup)$" },
    float = true,
})

hl.window_rule({
    name  = "pip-floating",
    match = { title = "^(Picture-in-Picture)$" },
    float = true,
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

-- managed by Flamenco Settings (loaded last so they win)
flamenco("monitors")
flamenco("input")
flamenco("cursor")
flamenco("layout")
