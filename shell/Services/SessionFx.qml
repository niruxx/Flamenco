pragma Singleton

import QtQuick
import Quickshell
import qs.Commons

// Login (intro) and logout (outro) animations. `cover` is how much of the
// screen the animation covers: intro runs 1 → 0, outro 0 → 1.
Singleton {
    id: root

    readonly property var cfg: Settings.data.session
    readonly property var presets: ["bloom", "curtain", "blinds", "zoom", "fade"]
    property string mode: ""            // "" | intro | outro
    property string preset: "fade"
    property string message: ""
    property string detail: ""
    property real cover: 0
    property bool preview: false
    property var pending: null          // action to run once an outro has covered the screen
    readonly property int duration: Theme.speed <= 0 ? 0 : Math.max(300, cfg.duration) / Theme.speed

    function greeting() {
        const h = new Date().getHours();
        return (h < 5 ? "Good night" : h < 12 ? "Good morning" : h < 18 ? "Good afternoon" : "Good evening") + ", " + Paths.user;
    }

    // at shell start: only when niri started us (not `flamenco restart`), and
    // only once per process (config hot-reloads re-run startup code)
    function startup() {
        if (Quickshell.env("FLAMENCO_INTRO") === "1" && !persist.introPlayed) {
            persist.introPlayed = true;
            introDelay.start();
        }
    }

    PersistentProperties {
        id: persist
        reloadableId: "flamenco-sessionfx"
        property bool introPlayed: false
    }

    function playIntro(isPreview) {
        const p = cfg.intro;
        if (p === "none" && !isPreview)
            return;
        anim.stop();
        preview = !!isPreview;
        preset = p === "none" || !presets.includes(p) ? "fade" : p;
        message = cfg.greeting ? greeting() : "";
        detail = cfg.greeting ? Qt.formatDate(new Date(), "dddd, d MMMM") : "";
        cover = 1;
        mode = "intro";
        hold.interval = 700;
        hold.start();
    }

    function playOutro(label, action, isPreview) {
        const p = cfg.outro;
        if ((p === "none" || duration === 0) && !isPreview) {
            if (action)
                action();
            return;
        }
        anim.stop();
        preview = !!isPreview;
        preset = p === "none" || !presets.includes(p) ? "fade" : p;
        message = cfg.greeting ? "See you soon, " + Paths.user : "";
        detail = label;
        pending = action ?? null;
        cover = 0;
        mode = "outro";
        anim.from = 0;
        anim.to = 1;
        anim.restart();
    }

    Timer {
        id: introDelay
        interval: 350
        onTriggered: root.playIntro(false)
    }

    // intro: show the greeting for a moment, then open up
    Timer {
        id: hold
        onTriggered: {
            if (root.mode === "intro") {
                anim.from = 1;
                anim.to = 0;
                anim.restart();
            } else if (root.mode === "outro") {
                const a = root.pending;
                root.pending = null;
                if (root.preview) {
                    // previews open back up instead of logging out
                    anim.from = 1;
                    anim.to = 0;
                    root.mode = "intro";
                    anim.restart();
                } else if (a) {
                    a();
                }
            }
        }
    }

    NumberAnimation {
        id: anim
        target: root
        property: "cover"
        duration: root.duration
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Theme.curves.emphasized
        onFinished: {
            if (root.mode === "outro" && root.cover >= 1) {
                hold.interval = 450;
                hold.start();
            } else if (root.cover <= 0) {
                root.mode = "";
            }
        }
    }
}
