import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services
import qs.Widgets

// Runs an SDDM greeter theme as the lock screen.
//
// SDDM themes expect a handful of globals that the greeter injects as context
// properties: `sddm`, `config`, `userModel`, `sessionModel`, `screenModel`,
// `keyboard`, `primaryScreen`. They're declared as properties on this root
// item, which is the context object the loaded theme's lookups fall back to,
// so the theme sees them as if SDDM were running it. `sddm.login()` is routed
// to the lock's PAM check for the current user.
Item {
    id: host

    required property var ctx            // the Lock scope (buffer, submit, errors)
    required property string themeDir    // e.g. /usr/share/sddm/themes/sugar-candy
    signal failed(string reason)

    // ── theme metadata + config ──
    function parseIni(text) {
        const out = {};
        let section = "";
        for (const raw of text.split("\n")) {
            const line = raw.trim();
            if (!line || line.startsWith("#") || line.startsWith(";"))
                continue;
            const sec = line.match(/^\[(.+)\]$/);
            if (sec) {
                section = sec[1];
                continue;
            }
            const eq = line.indexOf("=");
            if (eq < 0)
                continue;
            let v = line.slice(eq + 1).trim();
            if (v.length >= 2 && v[0] === '"' && v[v.length - 1] === '"')
                v = v.slice(1, -1);
            out[(section ? section + "/" : "") + line.slice(0, eq).trim()] = v;
        }
        return out;
    }

    readonly property var meta: parseIni(metaFile.text())
    readonly property string mainScript: meta["SddmGreeterTheme/MainScript"] || "Main.qml"
    readonly property string configName: meta["SddmGreeterTheme/ConfigFile"] || "theme.conf"

    FileView { id: metaFile; path: host.themeDir + "/metadata.desktop"; blockLoading: true }
    FileView { id: confFile; path: host.themeDir + "/" + host.configName; blockLoading: true }
    FileView { id: userConfFile; path: host.themeDir + "/" + host.configName + ".user"; blockLoading: true }
    FileView { id: passwd; path: "/etc/passwd"; blockLoading: true }
    FileView { id: hostnameFile; path: "/etc/hostname"; blockLoading: true }

    // [General] keys, with theme.conf.user overriding theme.conf
    readonly property var configValues: {
        const merged = Object.assign({}, parseIni(confFile.text()), parseIni(userConfFile.text()));
        const out = {};
        for (const k in merged)
            out[k.startsWith("General/") ? k.slice(8) : k] = merged[k];
        return out;
    }

    readonly property string realName: {
        const line = passwd.text().split("\n").find(l => l.startsWith(Paths.user + ":"));
        const gecos = line ? (line.split(":")[4] || "").split(",")[0] : "";
        return gecos || Paths.user;
    }

    // ── globals the theme expects ──
    property var config: {
        const c = Object.assign({}, configValues);
        // SDDM ≥ 0.21 typed accessors
        c.stringValue = k => String(configValues[k] ?? "");
        c.boolValue = k => ["true", "1", "yes", "on"].includes(String(configValues[k] ?? "").toLowerCase());
        c.intValue = k => parseInt(configValues[k] ?? "0") || 0;
        c.realValue = k => parseFloat(configValues[k] ?? "0") || 0;
        return c;
    }

    property bool primaryScreen: true

    property QtObject sddm: QtObject {
        id: sddmObj

        signal loginSucceeded
        signal loginFailed
        signal informationMessage(string message)

        readonly property string hostName: hostnameFile.text().trim()
        readonly property bool canPowerOff: true
        readonly property bool canReboot: true
        readonly property bool canSuspend: true
        readonly property bool canHibernate: false
        readonly property bool canHybridSleep: false

        function login(user, password, sessionIndex) {
            if (user && user !== Paths.user) {
                loginFailed();
                return;
            }
            host.ctx.buffer = password;
            host.ctx.submit();
        }
        function powerOff() { Power.shutdown(); }
        function reboot() { Power.reboot(); }
        function suspend() { Power.suspend(); }
        function hibernate() { Quickshell.execDetached(["systemctl", "hibernate"]); }
        function hybridSleep() { Quickshell.execDetached(["systemctl", "hybrid-sleep"]); }
    }

    property ListModel userModel: ListModel {
        property string lastUser: Paths.user
        property int lastIndex: 0
        property int disableAvatarsThreshold: 7
        property bool containsAllUsers: true
    }

    property ListModel sessionModel: ListModel {
        property int lastIndex: 0
    }

    property ListModel screenModel: ListModel {
        property int primary: 0
    }

    property QtObject keyboard: QtObject {
        property bool capsLock: false
        property bool numLock: false
        property var layouts: []
        property int currentLayout: 0
    }

    Component.onCompleted: {
        const face = Paths.expand(Settings.data.general.avatar);
        userModel.append({ name: Paths.user, realName: host.realName, icon: face ? "file://" + face : "", homeDir: Paths.home, needsPassword: true });
        sessionModel.append({ name: "niri", file: "niri.desktop", comment: "Current session", exec: "niri-session" });
        screenModel.append({ name: "screen", primary: true });
        if (!metaFile.text())
            host.failed("no metadata.desktop in " + host.themeDir);
    }

    // PAM results → the theme's signals
    Connections {
        target: host.ctx
        function onShakeCountChanged() { sddmObj.loginFailed(); }
        function onUnlockingChanged() {
            if (host.ctx.unlocking)
                sddmObj.loginSucceeded();
        }
    }

    Loader {
        id: theme
        anchors.fill: parent
        focus: true
        active: metaFile.text() !== ""
        source: active ? "file://" + host.themeDir + "/" + host.mainScript : ""
        onStatusChanged: if (status === Loader.Error) host.failed("could not load " + source)
        onLoaded: item.forceActiveFocus()

        // fade out with the rest of the lock on unlock
        opacity: host.ctx.unlocking ? 0 : 1
        Behavior on opacity { Anim { duration: Theme.durLong } }
    }
}
