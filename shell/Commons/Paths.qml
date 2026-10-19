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

    // Turn a path typed by a person into an absolute path: ~, $HOME, relative
    // to home, stray whitespace and trailing slashes.
    function normalize(path) {
        let p = String(path ?? "").trim();
        if (p.startsWith("file://"))
            p = decodeURIComponent(p.slice(7));
        if (!p)
            return "";
        p = p.replace(/^\$HOME(?=\/|$)/, home).replace(/^~(?=\/|$)/, home);
        if (!p.startsWith("/"))
            p = home + "/" + p;
        p = p.replace(/\/{2,}/g, "/");
        return p.length > 1 ? p.replace(/\/+$/, "") : p;
    }

    // Live wallpapers: videos play on the desktop (Background's LiveVideo), GIFs
    // animate. A video's still (its "poster", one frame, made by Wallpapers with
    // ffmpeg) stands in for it everywhere a picture is needed: thumbnails, the
    // transitions, the lock screen and colors from wallpaper.
    readonly property var videoExts: ["mp4", "webm", "mkv", "mov", "m4v", "avi"]
    function ext(path) {
        const m = String(path ?? "").toLowerCase().match(/\.([a-z0-9]+)$/);
        return m ? m[1] : "";
    }
    function isVideo(path) {
        return videoExts.includes(ext(path));
    }
    function isAnimated(path) {
        return isVideo(path) || ext(path) === "gif";
    }
    // where a video's poster goes (`flamenco` computes the same name: md5 of the path)
    function poster(path) {
        return cacheDir + "/live/" + Qt.md5(expand(path)) + ".jpg";
    }

    // file:// URL for a path. Each segment is percent-encoded, so names with
    // spaces, #, % or ? still load.
    function toUrl(path) {
        if (!path)
            return "";
        const s = String(path);
        if (s.startsWith("file://") || s.startsWith("image://") || s.startsWith("qrc:"))
            return s;
        return "file://" + expand(s).split("/").map(encodeURIComponent).join("/");
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
