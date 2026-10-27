pragma Singleton

import QtQuick
import Quickshell
import qs.Commons

// The playing track's lyrics, line by line in time (synced lyrics from lrclib.net,
// a free lyrics database), for the bar's lyric widget. Looked up only while a
// widget shows it, once per track; nothing is sent but the artist, title and length.
Singleton {
    id: root

    property int users: 0
    property var lines: []                   // [{ t: seconds, text }]
    property string status: ""               // "" | "loading" | "none"
    readonly property string key: Media.artist + "\n" + Media.title
    property var cache: ({})
    // the line being sung now (what was sung last, until the next one starts)
    readonly property string line: {
        const pos = Media.position;
        let cur = "";
        for (const l of lines) {
            if (l.t > pos + 0.3)
                break;
            cur = l.text;
        }
        return cur;
    }

    onKeyChanged: load()
    onUsersChanged: if (users > 0) load()

    function parse(lrc) {
        const out = [];
        for (const raw of String(lrc || "").split("\n")) {
            const m = raw.match(/^\s*\[(\d+):(\d+(?:\.\d+)?)\]\s*(.*)$/);
            if (m)
                out.push({ t: parseInt(m[1]) * 60 + parseFloat(m[2]), text: m[3].trim() });
        }
        return out.sort((a, b) => a.t - b.t);
    }
    function load() {
        if (users <= 0 || !Media.active || !Media.title)
            return;
        const k = key;
        if (cache[k] !== undefined) {
            lines = cache[k];
            status = lines.length ? "" : "none";
            return;
        }
        lines = [];
        status = "loading";
        const q = "artist_name=" + encodeURIComponent(Media.artist) + "&track_name=" + encodeURIComponent(Media.title)
            + (Media.length > 0 ? "&duration=" + Math.round(Media.length) : "");
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            let got = [];
            try {
                if (xhr.status === 200)
                    got = parse(JSON.parse(xhr.responseText).syncedLyrics);
            } catch (e) {}
            const c = Object.assign({}, cache);
            c[k] = got;
            cache = c;
            if (k === key) {
                lines = got;
                status = got.length ? "" : "none";
            }
        };
        xhr.open("GET", "https://lrclib.net/api/get?" + q);
        xhr.send();
    }
}
