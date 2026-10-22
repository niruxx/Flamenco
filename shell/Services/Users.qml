pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// The accounts on this computer (`flamenco users list`), for Settings → Users and
// the profile card at the top of Settings. Changes go through `flamenco users …`:
// your own name and picture directly (AccountsService), anything needing root or a
// password in a terminal (sudo / passwd), after which the list is read again.
Singleton {
    id: root

    property var users: []
    property string me: Paths.user
    property bool isAdmin: false
    property bool accounts: false            // AccountsService is there
    property string adminGroup: "wheel"
    property var shells: ["/bin/bash"]
    property bool loaded: false
    property string error: ""
    readonly property var self: users.find(u => u.me) ?? null
    readonly property string fullName: (self?.fullName ?? "") || me
    readonly property var others: users.filter(u => !u.me)
    readonly property bool busy: terminal.running || direct.running

    function refresh() {
        if (!lister.running)
            lister.running = true;
    }
    Component.onCompleted: refresh()

    // done right here: your own name and picture
    function setName(full) {
        // through AccountsService; without it, usermod in a terminal
        if (accounts)
            run([Paths.bin, "users", "name", full]);
        else
            inTerminal(["name", full]);
    }
    // pictures in Settings reload from this (the file keeps its name)
    property int avatarVersion: 0
    function setAvatar(path) {
        run([Paths.bin, "users", "avatar", path]);
    }
    function removeAvatar() {
        run([Paths.bin, "users", "avatar", "--remove"]);
    }
    function run(cmd) {
        error = "";
        direct.command = cmd;
        direct.running = true;
    }
    Process {
        id: direct
        stdout: StdioCollector {
            onStreamFinished: {
                const out = text.trim();
                // a new picture: the shell's avatar is that file, reloaded
                if (out.endsWith("/.face") || out === "picture removed") {
                    Settings.data.general.avatar = "";
                    Settings.data.general.avatar = "~/.face";
                    root.avatarVersion++;
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) root.error = text.trim().split("\n").pop().replace(/^flamenco: /, "")
        }
        // couldn't do it directly (no AccountsService): it falls back to the terminal itself,
        // but a failure is shown
        onExited: root.refresh()
    }

    // in a terminal: passwords, and anything needing root
    function inTerminal(args) {
        error = "";
        terminal.command = Paths.term(["env", "FLAMENCO_PAUSE=1", Paths.bin, "users"].concat(args));
        terminal.running = true;
    }
    function setNameOf(user, full) {
        inTerminal(["name", full, user]);
    }
    function changePassword(user) {
        inTerminal(user && user !== me ? ["password", user] : ["password"]);
    }
    function add(user, full, admin, shell, groups) {
        inTerminal(["add", user, full].concat(admin ? ["--admin"] : [], shell ? ["--shell", shell] : [], groups ? ["--groups", groups] : []));
    }
    function remove(user, keepHome) {
        inTerminal(["remove", user].concat(keepHome ? ["--keep-home"] : []));
    }
    function setAdmin(user, on) {
        inTerminal(["admin", user, on ? "on" : "off"]);
    }
    Process {
        id: terminal
        onExited: root.refresh()
    }

    Process {
        id: lister
        command: [Paths.bin, "users", "list", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    root.users = d.users ?? [];
                    root.me = d.me ?? root.me;
                    root.isAdmin = !!d.isAdmin;
                    root.accounts = !!d.accounts;
                    root.adminGroup = d.adminGroup ?? "wheel";
                    root.shells = d.shells ?? ["/bin/bash"];
                    root.loaded = true;
                } catch (e) {}
            }
        }
    }
}
