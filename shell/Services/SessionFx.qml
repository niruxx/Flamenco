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

    // 0 → 1 as the bar, the dock and the desktop widgets slide in after logging in
    // (Settings → Lock & Login → Session); 1 otherwise, e.g. after `flamenco restart`
    property real revealBar: 1
    property real revealDock: 1
    property real revealDesk: 1
    readonly property int slideMs: Theme.speed <= 0 ? 0 : Math.max(100, cfg.slideDuration ?? 900) / Theme.speed
    readonly property int staggerMs: Theme.speed <= 0 ? 0 : Math.max(0, cfg.slideStagger ?? 180) / Theme.speed

    function startReveal() {
        if (revealBar >= 1 && revealDock >= 1 && revealDesk >= 1)
            return;
        reveal.restart();
    }
    // a preview from Settings: hide them and slide them back in
    function previewReveal() {
        reveal.stop();
        revealBar = 0;
        revealDock = 0;
        revealDesk = 0;
        Qt.callLater(() => reveal.restart());
    }

    ParallelAnimation {
        id: reveal
        NumberAnimation { target: root; property: "revealBar"; to: 1; duration: root.slideMs; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curves.emphasizedDecel }
        SequentialAnimation {
            PauseAnimation { duration: root.staggerMs }
            NumberAnimation { target: root; property: "revealDock"; to: 1; duration: root.slideMs; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curves.emphasizedDecel }
        }
        SequentialAnimation {
            PauseAnimation { duration: root.staggerMs * 2 }
            NumberAnimation { target: root; property: "revealDesk"; to: 1; duration: root.slideMs; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curves.emphasizedDecel }
        }
    }

    function greeting() {
        const h = new Date().getHours();
        return (h < 5 ? "Good night" : h < 12 ? "Good morning" : h < 18 ? "Good afternoon" : "Good evening") + ", " + Paths.user;
    }

    // at shell start: only when niri started us (not `flamenco restart`), and
    // only once per process (config hot-reloads re-run startup code)
    function startup() {
        if (Quickshell.env("FLAMENCO_INTRO") === "1" && !persist.introPlayed) {
            persist.introPlayed = true;
            // the desktop starts hidden and slides in once the welcome screen has opened up
            if (cfg.slideIn ?? true) {
                revealBar = 0;
                revealDock = 0;
                revealDesk = 0;
            }
            if ((cfg.welcome ?? true) && cfg.intro !== "none")
                introDelay.start();
            else
                revealDelay.start();
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
        if ((p === "none" || !(cfg.goodbye ?? true) || duration === 0) && !isPreview) {
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
        id: revealDelay
        interval: 300
        onTriggered: root.startReveal()
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
                root.startReveal();
            }
        }
    }
}
