pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.Commons

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property real micVolume: source?.audio?.volume ?? 0
    readonly property bool micMuted: source?.audio?.muted ?? false

    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)
    readonly property var sources: Pipewire.nodes.values.filter(n => !n.isSink && !n.isStream && n.audio)
    // apps currently playing audio (playback streams)
    readonly property var streams: Pipewire.nodes.values.filter(n => n.isStream && !n.isSink && n.audio)

    // Apps recording audio: capture streams, minus ones that only listen to an
    // output's monitor (volume meters, visualizers like cava) and the shell itself.
    readonly property var captures: Pipewire.nodes.values.filter(n => n.isStream && n.isSink && n.audio)
    readonly property var recorders: captures.filter(n => {
        const p = n.properties ?? {};
        if (p["stream.monitor"] === "true" || p["stream.capture.sink"] === "true")
            return false;
        return !/quickshell/i.test(p["application.name"] ?? "") && !/quickshell/i.test(p["application.process.binary"] ?? "");
    })
    readonly property bool micInUse: recorders.length > 0
    readonly property string micUsers: [...new Set(recorders.map(n => streamName(n)))].join(", ")

    function streamName(n) {
        const p = n?.properties ?? {};
        if (/quickshell/i.test(p["application.name"] ?? "") || /quickshell/i.test(p["application.process.binary"] ?? ""))
            return "Flamenco sounds";
        return p["application.name"] || p["media.name"] || n?.description || n?.name || "App";
    }
    // what a stream is playing ("Song – Artist", a tab's title), when it says more than the app's name
    function streamTitle(n) {
        const p = n?.properties ?? {};
        const t = p["media.name"] ?? "";
        const app = streamName(n);
        return t && t !== app && !/^(playback|audio stream|output|record|capture)$/i.test(t) ? t : "";
    }
    function streamIcon(n) {
        const p = n?.properties ?? {};
        return p["application.icon-name"] || p["application.process.binary"] || "";
    }

    // ── the mixer ──
    // Apps' streams, one entry per app (a browser's tabs together): {key, name, icon, nodes}
    function groupsOf(nodes) {
        const out = [];
        for (const n of nodes) {
            const p = n.properties ?? {};
            const key = p["application.process.binary"] || p["application.name"] || n.name || String(n.id);
            let g = out.find(x => x.key === key);
            if (!g) {
                g = { key: key, name: streamName(n), icon: streamIcon(n) || streamName(n).toLowerCase(), nodes: [] };
                out.push(g);
            }
            g.nodes.push(n);
        }
        return out.sort((a, b) => a.name.localeCompare(b.name));
    }
    readonly property var streamGroups: groupsOf(streams)
    readonly property var recorderGroups: groupsOf(recorders)
    readonly property real maxAppVolume: Settings.data.sound.mixerBoost ? 1.5 : 1

    function streamVolume(n) {
        return n?.audio?.volume ?? 0;
    }
    function setStreamVolume(n, v) {
        if (!n?.audio)
            return;
        n.audio.muted = false;
        n.audio.volume = Math.max(0, Math.min(maxAppVolume, v));
    }
    function toggleStreamMute(n) {
        if (n?.audio)
            n.audio.muted = !n.audio.muted;
    }
    // an app's volume is its loudest stream's; setting it sets them all
    function groupVolume(g) {
        return Math.max(0, ...g.nodes.map(n => streamVolume(n)));
    }
    function groupMuted(g) {
        return g.nodes.length > 0 && g.nodes.every(n => n.audio?.muted);
    }
    function setGroupVolume(g, v) {
        for (const n of g.nodes)
            setStreamVolume(n, v);
    }
    function toggleGroupMute(g) {
        const m = !groupMuted(g);
        for (const n of g.nodes)
            if (n.audio)
                n.audio.muted = m;
    }
    // send an app's streams to another output (or, for a recording app, take them from another input).
    // pipewire-pulse's indices are object serials; without it, WirePlumber's target metadata.
    function moveGroup(g, device) {
        const target = device?.properties?.["object.serial"] ?? "";
        for (const n of g.nodes) {
            const serial = n.properties?.["object.serial"] ?? "";
            const pulse = n.isSink ? "move-source-output" : "move-sink-input";
            Quickshell.execDetached(["sh", "-c", 'pactl "$1" "$2" "$3" 2>/dev/null || pw-metadata "$4" target.object "$5"', "sh", pulse, String(serial), device.name, String(n.id), String(target || device.name)]);
        }
    }

    readonly property string icon: muted || volume <= 0 ? "volume_off" : volume < 0.34 ? "volume_mute" : volume < 0.67 ? "volume_down" : "volume_up"

    function nodeName(n) {
        return n?.description || n?.nickname || n?.name || "Unknown";
    }

    function setVolume(v) {
        if (!sink?.audio)
            return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1.5, v));
        Sounds.volumeChanged();
    }

    function step(delta) {
        setVolume(volume + delta);
    }

    function toggleMute() {
        if (sink?.audio)
            sink.audio.muted = !sink.audio.muted;
    }

    function setMicVolume(v) {
        if (!source?.audio)
            return;
        source.audio.muted = false;
        source.audio.volume = Math.max(0, Math.min(1.5, v));
    }

    function toggleMicMute() {
        if (source?.audio)
            source.audio.muted = !source.audio.muted;
    }

    function setDefaultSink(n) {
        Pipewire.preferredDefaultAudioSink = n;
    }

    function setDefaultSource(n) {
        Pipewire.preferredDefaultAudioSource = n;
    }

    PwObjectTracker {
        objects: [root.sink, root.source]
    }
    // bind app streams too, so their volume can be read and changed
    PwObjectTracker {
        objects: root.streams
    }
    // and capture streams, so their properties (who's recording) can be read
    PwObjectTracker {
        objects: root.captures
    }
}
