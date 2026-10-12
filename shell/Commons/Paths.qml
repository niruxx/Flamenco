pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME") || ""
    readonly property string user: Quickshell.env("USER") || "user"
    readonly property string configDir: (Quickshell.env("XDG_CONFIG_HOME") || home + "/.config") + "/flamenco"
    readonly property string cacheDir: (Quickshell.env("XDG_CACHE_HOME") || home + "/.cache") + "/flamenco"
    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || home + "/.local/state") + "/flamenco"

    // Path to the `flamenco` CLI, exported by `flamenco run`.
    readonly property string bin: Quickshell.env("FLAMENCO_BIN") || "flamenco"

    function expand(path) {
        if (!path)
            return "";
        return String(path).replace(/^~(?=\/|$)/, home);
    }

    function toUrl(path) {
        if (!path)
            return "";
        const p = expand(path);
        return p.startsWith("file://") || p.startsWith("image://") ? p : "file://" + p;
    }

    // Command line that runs `args` in the user's terminal. Terminals disagree
    // on how to pass a command (kitty/foot take it directly, wezterm wants
    // `start --`, gnome-terminal `--`, most others `-e`).
    function term(args) {
        const t = (Settings.data.general.terminal || "kitty").trim().split(/\s+/);
        const name = t[0].split("/").pop();
        if (!args || args.length === 0)
            return t;
        if (name === "kitty" || name === "foot")
            return t.concat(args);
        if (name === "wezterm")
            return t.concat(["start", "--"], args);
        if (name === "gnome-terminal" || name === "kgx")
            return t.concat(["--"], args);
        return t.concat(["-e"], args);
    }

    // Run a shell command in a terminal and keep the window open afterwards,
    // e.g. for sudo prompts.
    function termHold(shellCommand) {
        return term(["sh", "-c", shellCommand + "; echo; printf 'Press Enter to close'; read _"]);
    }

    // Quote a string for sh -c: wrap in single quotes, escaping embedded ones.
    function shellQuote(str) {
        return "'" + String(str).split("'").join("'\\''") + "'";
    }

    function fileName(path) {
        return String(path).split("/").pop();
    }
}
