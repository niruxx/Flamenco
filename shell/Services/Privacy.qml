pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.Commons

// What's watching or listening: the microphone (Audio.recorders), the camera
// (programs with /dev/video* open, from `flamenco privacy watch`) and screen
// sharing (a screencast video source in PipeWire, and who's reading it).
Singleton {
    id: root

    // ── microphone ──
    readonly property bool mic: Audio.micInUse
    readonly property string micUsers: Audio.micUsers

    // ── camera ──
    property var cameraApps: []
    // apps reading a camera through PipeWire (portal camera access)
    readonly property bool camera: cameraApps.length > 0 || pwCamUsers.length > 0
    readonly property string cameraUsers: [...new Set(cameraApps.concat(pwCamUsers))].join(", ")

    // ── screen sharing ──
    readonly property var videoNodes: Pipewire.nodes.values.filter(n => !n.audio)
    // sources made on demand for a screencast (cameras carry device.api)
    readonly property var castSources: videoNodes.filter(n => {
        const p = n.properties ?? {};
        return p["media.class"] === "Video/Source" && !p["device.api"] && !n.isStream;
    })
    readonly property var videoReaders: videoNodes.filter(n => {
        const p = n.properties ?? {};
        return n.isStream && (p["media.class"] ?? "").startsWith("Stream/Input/Video");
    })
    readonly property bool screen: castSources.length > 0
    readonly property string screenUsers: [...new Set(videoReaders.filter(n => !root.isCameraReader(n)).map(n => root.appName(n)))].join(", ")
    readonly property var pwCamUsers: [...new Set(videoReaders.filter(n => root.isCameraReader(n)).map(n => root.appName(n)))]

    readonly property bool any: mic || camera || screen

    function appName(n) {
        const p = n.properties ?? {};
        return p["application.name"] || p["application.process.binary"] || p["node.name"] || "an app";
    }
    // a reader whose target is a real camera device
    function isCameraReader(n) {
        const p = n.properties ?? {};
        const target = String(p["target.object"] ?? p["node.target"] ?? "");
        return target !== "" && videoNodes.some(v => (v.properties ?? {})["device.api"] && (String(v.id) === target || v.name === target));
    }

    // bind video nodes so their properties can be read
    PwObjectTracker {
        objects: root.videoNodes
    }

    Process {
        id: watcher
        running: true
        command: [Paths.bin, "privacy", "watch"]
        stdout: SplitParser {
            onRead: line => {
                try {
                    root.cameraApps = JSON.parse(line).camera ?? [];
                } catch (e) {}
            }
        }
        // restart it if it ever stops
        onExited: restartWatch.start()
    }
    Timer {
        id: restartWatch
        interval: 5000
        onTriggered: watcher.running = true
    }
}
