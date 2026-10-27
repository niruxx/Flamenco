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
    // what browsers send (YouTube, YouTube Music in Firefox or Chrome) is messier
    // than a music app's: "Artist - Song (Official Video)" with the channel as the
    // artist. This makes it a plain artist and title.
    function clean(artist, title) {
        let a = String(artist || "").replace(/\s*-\s*Topic$/i, "").replace(/VEVO$/i, "").replace(/\s*(Official|Music)$/i, "").trim();
        let t = String(title || "")
            .replace(/\s*[([](official|lyric|lyrics|audio|video|music video|visualizer|hd|4k|remaster(ed)?[^)\]]*|live[^)\]]*)[^)\]]*[)\]]/gi, "")
            .replace(/\s*[([](feat|ft)\.?[^)\]]*[)\]]/gi, "")
            .replace(/\s*\|.*$/, "").trim();
        // "Artist - Song" in the title (YouTube)
        const m = t.match(/^(.+?)\s+[-–—]\s+(.+)$/);
        const bare = v => v.toLowerCase().replace(/[^\p{L}\p{N}]/gu, "");
        if (m && (!a || bare(m[1]).includes(bare(a)) || bare(a).includes(bare(m[1])) || /youtube|music/i.test(a))) {
            a = m[1].trim();
            t = m[2].trim();
        }
        a = a.split(/\s*(?:,|&| x | feat\.?| ft\.?)\s*/i)[0].trim();
        t = t.replace(/\s+(feat|ft)\.?\s.*$/i, "").trim();
        return { artist: a, title: t };
    }
    function get(url, done) {
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            let d = null;
            try {
                if (xhr.status === 200)
                    d = JSON.parse(xhr.responseText);
            } catch (e) {}
            done(d);
        };
        xhr.open("GET", url);
        xhr.send();
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
        const c = clean(Media.artist, Media.title);
        const len = Math.round(Media.length);
        const base = "https://lrclib.net/api/";
        const q = "artist_name=" + encodeURIComponent(c.artist) + "&track_name=" + encodeURIComponent(c.title);
        const finish = got => {
            const all = Object.assign({}, cache);
            all[k] = got;
            cache = all;
            if (k === key) {
                lines = got;
                status = got.length ? "" : "none";
            }
        };
        // the best search hit: synced, and the closest length
        const pick = list => {
            const synced = (list || []).filter(x => x && x.syncedLyrics);
            if (len > 0)
                synced.sort((x, y) => Math.abs((x.duration || 0) - len) - Math.abs((y.duration || 0) - len));
            return synced[0] ? parse(synced[0].syncedLyrics) : [];
        };
        // exact (with the length, then without), then searches
        const steps = [
            d => len > 0 ? base + "get?" + q + "&duration=" + len : null,
            d => base + "get?" + q,
            d => base + "search?" + q,
            d => base + "search?q=" + encodeURIComponent((c.artist + " " + c.title).trim())
        ];
        const tryStep = i => {
            if (k !== key)
                return;
            if (i >= steps.length) {
                finish([]);
                return;
            }
            const url = steps[i]();
            if (!url) {
                tryStep(i + 1);
                return;
            }
            get(url, d => {
                const got = Array.isArray(d) ? pick(d) : d && d.syncedLyrics ? parse(d.syncedLyrics) : [];
                if (got.length)
                    finish(got);
                else
                    tryStep(i + 1);
            });
        };
        tryStep(0);
    }
}
