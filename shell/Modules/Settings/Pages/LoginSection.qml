import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services
import qs.Widgets

// Login screen: Flamenco Greeter's look and options, and greetd itself
// (/etc/greetd/config.toml). Both need root, so they're applied in a terminal
// with one sudo prompt, like the firewall page.
ColumnLayout {
    id: root

    Layout.fillWidth: true
    spacing: Theme.sp4

    readonly property var g: Settings.data.greeter
    property var st: ({ config: {}, sessions: [], users: [], greeters: [], applied: {} })
    property bool loaded: false

    readonly property var cfg: st.config ?? {}
    readonly property bool greeterInUse: String(cfg.command ?? "").split(" ")[0].endsWith("flamenco-greeter")
    readonly property string wallpaperPath: g.wallpaperMode === "custom" ? Paths.expand(g.wallpaper) : g.wallpaperMode === "desktop" ? Wallpapers.current : ""

    // greetd draft: loaded from the config, written with "Apply greetd settings"
    QtObject {
        id: draft
        property string command: ""
        property string user: "greeter"
        property string vt: "1"
        property bool autologin: false
        property string autologinUser: ""
        property string autologinSession: ""
        property bool dirty: false
    }

    function refresh() {
        if (!getter.running)
            getter.running = true;
    }

    function loadDraft() {
        draft.command = cfg.command ?? "";
        draft.user = cfg.user || "greeter";
        draft.vt = String(cfg.vt ?? 1);
        draft.autologin = !!cfg.autologin;
        draft.autologinUser = cfg.autologinUser || st.me || "";
        draft.autologinSession = (st.sessions.find(s => s.exec === cfg.autologinCommand) ?? {}).id ?? "";
        draft.dirty = false;
    }

    function inTerminal(args) {
        runner.command = Paths.termHold(Paths.shellQuote(Paths.bin) + " greeter " + args);
        runner.running = true;
    }

    function colorsHex() {
        const out = {};
        for (const k of ["bg", "surface", "surfaceHigh", "surfaceHighest", "border", "text", "textDim", "accent", "onAccent", "accent2", "accent3", "error", "warning", "success"])
            out[k] = String(Theme[k]);
        return out;
    }

    function applyGreeter() {
        const avatars = {};
        if (st.me && Settings.data.general.avatar)
            avatars[st.me] = Paths.expand(Settings.data.general.avatar);
        const spec = {
            wallpaper: { mode: g.wallpaperMode, path: wallpaperPath, color: g.color || String(Theme.bg), blur: g.blur, dim: g.dim, fillMode: Settings.data.wallpaper.fillMode },
            appearance: { dark: Theme.dark, colors: colorsHex(), fontFamily: g.fontFamily || Settings.data.appearance.fontFamily, monoFamily: g.monoFamily || Settings.data.appearance.monoFamily, fontScale: g.fontScale, roundness: Settings.data.appearance.roundness },
            clock: { use24h: Settings.data.general.use24h, showSeconds: Settings.data.general.showSeconds },
            sessions: { picker: g.sessionPicker, default: g.defaultSession, hidden: g.hiddenSessions },
            users: { list: g.userList, rememberLast: g.rememberUser },
            power: { buttons: g.powerButtons },
            auth: { fingerprint: g.fingerprint },
            avatars: avatars
        };
        inTerminal("apply --json " + Paths.shellQuote(JSON.stringify(spec)));
    }

    function applyGreetd() {
        const session = st.sessions.find(s => s.id === draft.autologinSession);
        const spec = { command: draft.command, user: draft.user, vt: draft.vt, autologin: draft.autologin && !!session, autologinUser: draft.autologinUser, autologinCommand: session?.exec ?? "" };
        inTerminal("greetd --json " + Paths.shellQuote(JSON.stringify(spec)));
    }

    Component.onCompleted: refresh()

    Process {
        id: getter
        command: [Paths.bin, "greeter", "status", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.st = JSON.parse(text);
                    root.loaded = true;
                    root.loadDraft();
                } catch (e) {}
            }
        }
    }

    // the terminal: re-read everything once it's closed
    Process {
        id: runner
        onExited: root.refresh()
    }

    // a file picker for the custom wallpaper
    Process {
        id: picker
        command: [Paths.bin, "pick", "image", Paths.expand(root.g.wallpaper) || Paths.home + "/Pictures"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim();
                if (p && p !== "@none")
                    root.g.wallpaper = p.startsWith(Paths.home + "/") ? "~" + p.slice(Paths.home.length) : p;
            }
        }
    }

    // ── Flamenco Greeter ──
    Group {
        title: "Login screen · Flamenco Greeter"

        SettingRow {
            title: root.st.greeterInstalled ? (root.greeterInUse ? "Flamenco Greeter is your login screen" : "Flamenco Greeter is installed") : "Flamenco Greeter isn't installed"
            subtitle: !root.loaded ? "Checking…"
                : !root.st.greeterInstalled ? "A login screen for greetd that looks like the shell. You can set it up here now and install it later (github.com/niruxx/flamenco-greeter)."
                : root.greeterInUse ? "Changes here show on the login screen after you click Apply."
                : "greetd isn't using it yet: pick it as the greeter in the greetd section below."
            icon: root.greeterInUse ? "check_circle" : "login"
        }

        ChoiceRow {
            title: "Wallpaper"
            subtitle: root.g.wallpaperMode === "desktop" ? "The one on your desktop now: " + (Paths.fileName(Wallpapers.current) || "none") : ""
            icon: "wallpaper"
            target: root.g
            key: "wallpaperMode"
            segWidth: 96
            options: [{ value: "desktop", label: "Desktop" }, { value: "custom", label: "Image" }, { value: "color", label: "Color" }]
        }
        SettingRow {
            visible: root.g.wallpaperMode === "custom"
            title: "Image"
            subtitle: "Copied for the greeter when you apply, since it can't read your home folder"
            icon: "image"
            Row {
                spacing: 8
                FTextField {
                    implicitWidth: 220
                    icon: "image"
                    placeholder: "~/Pictures/login.jpg"
                    text: root.g.wallpaper
                    onAccepted: root.g.wallpaper = text.trim()
                    onEditingFinished: root.g.wallpaper = text.trim()
                }
                FButton {
                    text: "Browse"
                    icon: "folder_open"
                    variant: "tonal"
                    implicitHeight: 38
                    disabled: picker.running
                    onClicked: picker.running = true
                }
            }
        }
        TextRow {
            visible: root.g.wallpaperMode === "color"
            title: "Background color"
            subtitle: "#rrggbb · empty uses the palette's background"
            icon: "format_color_fill"
            target: root.g
            key: "color"
            placeholder: String(Theme.bg)
        }
        SliderRow { visible: root.g.wallpaperMode !== "color"; title: "Blur"; icon: "blur_on"; target: root.g; key: "blur"; from: 0; to: 1; stepSize: 0.05; factor: 100; suffix: "%" }
        SliderRow { visible: root.g.wallpaperMode !== "color"; title: "Dim"; icon: "brightness_4"; target: root.g; key: "dim"; from: 0; to: 0.8; stepSize: 0.05; factor: 100; suffix: "%" }

        SettingRow {
            title: "Font"
            subtitle: "Colors always follow the shell's palette"
            icon: "font_download"
            FDropdown {
                implicitWidth: 280
                fontPreview: true
                options: [{ value: "", label: "Same as the shell (" + Settings.data.appearance.fontFamily + ")" }].concat(Sounds.fonts)
                current: root.g.fontFamily
                onSelected: v => root.g.fontFamily = v
            }
        }
        SettingRow {
            title: "Monospace font"
            icon: "code"
            FDropdown {
                implicitWidth: 280
                fontPreview: true
                options: [{ value: "", label: "Same as the shell (" + Settings.data.appearance.monoFamily + ")" }].concat(Sounds.monoFonts.length ? Sounds.monoFonts : Sounds.fonts)
                current: root.g.monoFamily
                onSelected: v => root.g.monoFamily = v
            }
        }
        SliderRow { title: "Text size"; icon: "format_size"; target: root.g; key: "fontScale"; from: 0.8; to: 1.5; stepSize: 0.05; factor: 100; suffix: "%" }

        SwitchRow { title: "Session picker"; subtitle: "Choose niri, Hyprland or another desktop when logging in"; icon: "desktop_windows"; target: root.g; key: "sessionPicker" }
        SettingRow {
            title: "Default session"
            subtitle: root.st.sessions.length ? "" : "No sessions found in /usr/share/wayland-sessions or /usr/share/xsessions"
            icon: "start"
            FDropdown {
                implicitWidth: 280
                options: [{ value: "", label: "The last one used" }].concat(root.st.sessions.map(s => ({ value: s.id, label: s.name + (s.type === "x11" ? " (X11)" : "") })))
                current: root.g.defaultSession
                onSelected: v => root.g.defaultSession = v
            }
        }
        Repeater {
            model: root.g.sessionPicker ? root.st.sessions : []
            SettingRow {
                required property var modelData
                title: "Show " + modelData.name
                subtitle: modelData.comment || modelData.id
                icon: "check_box_outline_blank"
                FSwitch {
                    checked: !root.g.hiddenSessions.includes(modelData.id)
                    onToggled: c => c ? Settings.listRemove(root.g, "hiddenSessions", modelData.id) : Settings.listAdd(root.g, "hiddenSessions", modelData.id)
                }
            }
        }

        SwitchRow { title: "List users"; subtitle: "Off: type a user name instead"; icon: "group"; target: root.g; key: "userList" }
        SwitchRow { title: "Remember the last user and session"; icon: "history"; target: root.g; key: "rememberUser" }
        SwitchRow { title: "Power buttons"; subtitle: "Suspend, restart and shut down on the login screen"; icon: "power_settings_new"; target: root.g; key: "powerButtons" }
        SwitchRow {
            title: "Fingerprint login"
            subtitle: !Fingerprint.enrolled ? "Enroll a finger in the Fingerprint section above first"
                : root.st.fingerprintPam ? "greetd's PAM setup asks fprintd, so the greeter can show a fingerprint prompt. Your keyring still needs your password the first time."
                : "greetd doesn't ask for fingerprints yet. Add this as the first auth line of /etc/pam.d/greetd: auth sufficient pam_fprintd.so"
            icon: "fingerprint"
            target: root.g
            key: "fingerprint"
        }
        SettingRow {
            visible: root.g.fingerprint && root.loaded && !root.st.fingerprintPam
            title: "Copy the PAM line"
            subtitle: "Flamenco doesn't edit PAM files itself: a mistake there can lock you out. Keep a root shell open while you try it."
            icon: "content_copy"
            FButton {
                text: "Copy"
                variant: "tonal"
                onClicked: Quickshell.execDetached(["wl-copy", "auth       sufficient   pam_fprintd.so"])
            }
        }

        SettingRow {
            title: "Apply to the login screen"
            subtitle: (root.st.applied?.generator ? "Last applied by " + root.st.applied.generator + ". " : "")
                + "Writes " + (root.st.appliedDir || "/var/cache/flamenco-greeter") + " in a terminal (asks for your password). Your avatar, wallpaper, palette and clock format go along."
            icon: "publish"
            FButton {
                text: "Apply"
                icon: "done"
                disabled: runner.running || (root.g.wallpaperMode !== "color" && !root.wallpaperPath)
                onClicked: root.applyGreeter()
            }
        }
    }

    // ── greetd ──
    Group {
        title: "greetd"

        SettingRow {
            title: !root.loaded ? "Checking greetd…"
                : !root.st.greetdInstalled ? "greetd isn't installed"
                : root.st.greetdEnabled ? "greetd starts at boot"
                : "greetd is installed but doesn't start at boot"
            subtitle: !root.loaded ? ""
                : (root.st.displayManager ? "Login manager at boot: " + root.st.displayManager + ". " : "No login manager starts at boot. ")
                + (root.cfg.error ? root.cfg.error : root.cfg.exists ? "Config: " + root.cfg.path : "No config yet at " + (root.cfg.path || "/etc/greetd/config.toml"))
            icon: root.st.greetdEnabled ? "check_circle" : "info"
            Row {
                spacing: 8
                FButton {
                    visible: root.loaded && !root.st.greetdInstalled
                    text: "Install greetd"
                    variant: "tonal"
                    onClicked: Quickshell.execDetached(Paths.termHold("sudo pacman -S --needed greetd"))
                }
                FIconButton {
                    icon: "refresh"
                    size: 32
                    onClicked: root.refresh()
                }
            }
        }

        SettingRow {
            visible: root.st.greetdInstalled ?? false
            title: "Greeter"
            subtitle: "The login screen greetd shows. Only installed greeters can be applied."
            icon: "login"
            FDropdown {
                implicitWidth: 280
                options: {
                    const o = [{ value: "flamenco-greeter --command niri", label: "Flamenco Greeter (in niri)" }, { value: "flamenco-greeter --command Hyprland", label: "Flamenco Greeter (in Hyprland)" }];
                    if ((root.st.greeters ?? []).includes("tuigreet"))
                        o.push({ value: "tuigreet --time --remember --remember-session", label: "tuigreet (text)" });
                    if ((root.st.greeters ?? []).includes("agreety"))
                        o.push({ value: "agreety --cmd $SHELL", label: "agreety (plain text)" });
                    if (draft.command && !o.some(x => x.value === draft.command))
                        o.push({ value: draft.command, label: draft.command });
                    return o;
                }
                current: draft.command
                placeholder: "Choose a greeter…"
                onSelected: v => {
                    draft.command = v;
                    draft.dirty = true;
                }
            }
        }
        TextRow {
            visible: root.st.greetdInstalled ?? false
            title: "Greeter command"
            subtitle: "Or any command; greetd runs it as the greeter user"
            icon: "terminal"
            target: draft
            key: "command"
            placeholder: "flamenco-greeter --command niri"
            onEdited: draft.dirty = true
        }
        TextRow {
            visible: root.st.greetdInstalled ?? false
            title: "Greeter user"
            subtitle: "greetd's package creates \"greeter\""
            icon: "person"
            target: draft
            key: "user"
            placeholder: "greeter"
            onEdited: draft.dirty = true
        }
        TextRow {
            visible: root.st.greetdInstalled ?? false
            title: "Virtual terminal"
            subtitle: "Usually 1. A number, or next / current"
            icon: "tv"
            target: draft
            key: "vt"
            placeholder: "1"
            onEdited: draft.dirty = true
        }
        SwitchRow {
            visible: root.st.greetdInstalled ?? false
            title: "Log in automatically"
            subtitle: "Starts a session at boot without the login screen (once; logging out shows the greeter)"
            icon: "bolt"
            target: draft
            key: "autologin"
            onEdited: draft.dirty = true
        }
        DropdownRow {
            visible: (root.st.greetdInstalled ?? false) && draft.autologin
            title: "As user"
            icon: "account_circle"
            target: draft
            key: "autologinUser"
            options: (root.st.users ?? []).map(u => ({ value: u.name, label: u.fullName !== u.name ? u.fullName + " (" + u.name + ")" : u.name }))
            onEdited: draft.dirty = true
        }
        DropdownRow {
            visible: (root.st.greetdInstalled ?? false) && draft.autologin
            title: "Into session"
            icon: "start"
            target: draft
            key: "autologinSession"
            options: (root.st.sessions ?? []).map(s => ({ value: s.id, label: s.name }))
            placeholder: "Choose a session…"
            onEdited: draft.dirty = true
        }

        SettingRow {
            visible: root.st.greetdInstalled ?? false
            title: "Apply greetd settings"
            subtitle: "Writes " + (root.cfg.path || "/etc/greetd/config.toml") + " in a terminal and keeps a backup. Refused if the greeter isn't installed, so you can't end up without a login screen."
            icon: "publish"
            Row {
                spacing: 8
                FButton {
                    text: "Revert"
                    variant: "text"
                    visible: draft.dirty
                    onClicked: root.loadDraft()
                }
                FButton {
                    text: "Apply"
                    icon: "done"
                    disabled: runner.running || !draft.command || (draft.autologin && !draft.autologinSession)
                    onClicked: root.applyGreetd()
                }
            }
        }
        SettingRow {
            visible: (root.st.greetdInstalled ?? false) && !root.st.greetdEnabled
            title: "Use greetd at boot"
            subtitle: "Replaces " + (root.st.displayManager || "your current login manager") + " from the next boot. Apply a greeter above first. To go back: sudo systemctl enable --force " + (root.st.displayManager || "sddm")
            icon: "power_settings_new"
            FButton {
                text: "Enable greetd"
                variant: "tonal"
                disabled: runner.running || !root.cfg.command
                onClicked: root.inTerminal("enable")
            }
        }
    }
}
