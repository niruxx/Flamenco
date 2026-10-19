pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Singleton {
    id: root

    property var files: []
    readonly property var cfg: Settings.data.wallpaper
    readonly property string dir: Paths.normalize(cfg.dir)
    readonly property string current: Paths.expand(cfg.current)

    // scan state, for the folder field and the grid's empty message
    property bool scanning: scanner.running
    property string status: ""          // "" | "missing" | "empty" | "ok"
    property string scannedDir: ""
    property bool pending: false

    onDirChanged: rescan()

    function setDir(path) {
        const p = Paths.normalize(path);
        if (!p)
            return;
        // store it the way the person would write it
        cfg.dir = p.startsWith(Paths.home + "/") ? "~" + p.slice(Paths.home.length) : p === Paths.home ? "~" : p;
    }

    function rescan() {
        if (!dir)
            return;
        // a scan is already running: run again for the latest folder when it ends
        if (scanner.running) {
            pending = true;
            return;
        }
        pending = false;
        scannedDir = dir;
        // `test -d` first so a missing folder is reported, not shown as "no images".
        // Hidden files and folders are skipped: macOS leaves "._name.jpg" metadata
        // files (not images) on USB drives and shares, plus .Trashes etc.
        scanner.command = ["sh", "-c", 'test -d "$1" || { echo "@missing"; exit 0; }; find -L "$1" -mindepth 1 -maxdepth 4 \\( -name ".*" -prune \\) -o \\( -type f \\( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.bmp" -o -iname "*.gif" -o -iname "*.avif" -o -iname "*.jxl" -o -iname "*.mp4" -o -iname "*.webm" -o -iname "*.mkv" -o -iname "*.mov" -o -iname "*.m4v" -o -iname "*.avi" \\) -print \\) 2>/dev/null', "sh", dir];
        scanner.running = true;
    }

    // ── live wallpapers ──
    // A video's poster (one frame) stands in for it wherever a picture is needed;
    // `still(path)` is that picture ("" until the poster is made), or the path itself
    // for anything else. Posters are made with ffmpeg into ~/.cache/flamenco/live.
    property var posters: ({})               // video path → poster path, once it exists
    readonly property bool canPoster: ffprobe.found
    // Qt Multimedia, which plays them (without it they show their still)
    property bool canPlay: false
    readonly property int liveCount: files.filter(f => Paths.isAnimated(f)).length
    Component.onCompleted: {
        try {
            Qt.createQmlObject("import QtMultimedia\nMediaPlayer {}", root, "probe").destroy();
            canPlay = true;
        } catch (e) {
            canPlay = false;
        }
        rescan();
    }
    property var posterQueue: []

    function still(path) {
        if (!path)
            return "";
        if (!Paths.isVideo(path))
            return path;
        return posters[Paths.expand(path)] ?? "";
    }
    function stillUrl(path) {
        return Paths.toUrl(still(path));
    }

    function makePosters(list) {
        const want = list.filter(f => f && Paths.isVideo(f) && !posters[Paths.expand(f)] && !posterQueue.includes(f));
        if (want.length === 0)
            return;
        posterQueue = posterQueue.concat(want);
        if (!posterMaker.running)
            nextPosters();
    }
    function nextPosters() {
        if (posterQueue.length === 0)
            return;
        const batch = posterQueue.slice(0, 24);
        posterQueue = posterQueue.slice(24);
        // already made posters are just reported; md5 of the path, as Paths.poster()
        posterMaker.command = ["sh", "-c", 'd="$1"; shift; mkdir -p "$d"; for f; do o="$d/$(printf %s "$f" | md5sum | cut -c1-32).jpg"; '
            + 'if [ ! -s "$o" ] && command -v ffmpeg >/dev/null; then '
            + 'ffmpeg -nostdin -loglevel error -y -ss 1 -i "$f" -frames:v 1 -vf "scale=min(2560\\,iw):-2" -q:v 3 "$o"; [ -s "$o" ] || ffmpeg -nostdin -loglevel error -y -i "$f" -frames:v 1 -q:v 3 "$o"; fi; '
            + '[ -s "$o" ] && printf "%s\\t%s\\n" "$f" "$o"; done', "sh", Paths.cacheDir + "/live"].concat(batch.map(f => Paths.expand(f)));
        posterMaker.running = true;
    }

    // what every screen shows, so their posters are made even outside the folder
    readonly property var showing: Quickshell.screens.map(s => forScreen(s.name)).concat([current])
    onShowingChanged: makePosters(showing)

    Process {
        id: posterMaker
        stdout: SplitParser {
            onRead: line => {
                const [f, o] = line.split("\t");
                if (!f || !o)
                    return;
                const all = Object.assign({}, root.posters);
                all[f] = o;
                root.posters = all;
                // colors from wallpaper wait for the poster of a live one
                if (f === root.current)
                    ColorGen.generate();
            }
        }
        onExited: Qt.callLater(root.nextPosters)
    }
    // whether ffmpeg is there (for Settings and the doctor)
    Process {
        id: ffprobe
        property bool found: false
        running: true
        command: ["sh", "-c", "command -v ffmpeg"]
        onExited: code => found = code === 0
    }

    // the first screen's wallpaper is the main one (`current`, used for colors)
    readonly property string primary: Quickshell.screens[0]?.name ?? ""

    // what a screen shows: its own wallpaper in per-screen mode, else the main one
    function forScreen(name) {
        const own = cfg.perScreen && name ? (cfg.screens || {})[name] : "";
        return own ? Paths.expand(own) : current;
    }

    // screen "" (or per-screen mode off) sets it everywhere
    function set(path, screen) {
        if (cfg.perScreen && screen) {
            const all = Object.assign({}, cfg.screens || {});
            all[screen] = path;
            cfg.screens = all;
            if (screen === primary)
                cfg.current = path;
        } else {
            cfg.current = path;
            if (cfg.perScreen)
                cfg.screens = {};
        }
    }

    function pick(exclude) {
        const pool = files.filter(f => !exclude.includes(f));
        return pool.length ? pool[Math.floor(Math.random() * pool.length)] : (files[0] ?? "");
    }

    // a random wallpaper; in per-screen mode without a screen, a different one on each
    function random(screen) {
        if (files.length === 0)
            return;
        if (cfg.perScreen && !screen) {
            const used = [];
            for (const s of Quickshell.screens) {
                const f = pick(used.concat([forScreen(s.name)]));
                used.push(f);
                set(f, s.name);
            }
            return;
        }
        set(pick([forScreen(screen)]), screen);
    }

    function next(screen) {
        if (files.length === 0)
            return;
        const step = s => files[(files.indexOf(forScreen(s)) + 1) % files.length];
        if (cfg.perScreen && !screen) {
            for (const s of Quickshell.screens)
                set(step(s.name), s.name);
            return;
        }
        set(step(screen), screen);
    }

    Process {
        id: scanner
        stdout: StdioCollector {
            onStreamFinished: {
                // results for a folder that's no longer selected are dropped
                if (root.scannedDir !== root.dir)
                    return;
                if (text.trim() === "@missing") {
                    root.files = [];
                    root.status = "missing";
                    return;
                }
                root.files = text.split("\n").filter(Boolean).sort((a, b) => a.localeCompare(b, undefined, { numeric: true, sensitivity: "base" }));
                root.status = root.files.length ? "ok" : "empty";
                root.makePosters(root.files);
                // also replaces a "._name" metadata file picked before they were skipped
                if ((!root.current || Paths.fileName(root.current).startsWith("._")) && root.files.length > 0)
                    root.set(root.files[0]);
            }
        }
        onExited: if (root.pending || root.scannedDir !== root.dir) Qt.callLater(root.rescan)
    }

    Timer {
        running: root.cfg.cycle
        interval: Math.max(1, root.cfg.cycleMinutes) * 60000
        repeat: true
        onTriggered: root.random()
    }
}
