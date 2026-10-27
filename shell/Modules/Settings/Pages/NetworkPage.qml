import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services
import qs.Widgets

// Wi-Fi, wired and VPN connections through NetworkManager. Connections are
// edited right here (`flamenco net`), no nm-connection-editor needed.
Page {
    id: page
    title: I18n.tr("Wi-Fi & Network")
    subtitle: page.editing ? "" : I18n.tr("Wi-Fi, wired and VPN connections, through NetworkManager.")

    property var st: ({ connections: [], devices: [] })
    property string editing: ""              // uuid of the connection open in the editor
    property var ed: null                    // its settings, as last read
    property string error: ""
    property bool needsRoot: false           // the last change was refused for lack of rights
    property string lastArgs: ""             // …and this is what to retry with sudo
    property string armed: ""                // forget asks for a second click
    readonly property var wifi: st.connections.filter(c => c.type === "wifi")
    readonly property var wired: st.connections.filter(c => c.type === "ethernet")
    readonly property var dev: ed ? (st.devices.find(d => d.uuid === ed.uuid) ?? null) : null
    // for the inline components below, which can't see this file's ids
    readonly property QtObject d: draft
    readonly property bool busy: runner.running
    // Flamenco's own editor, or the app you used before (Settings → Network)
    readonly property bool inShell: Settings.data.general.nativeNetworkEditor
    readonly property string external: Settings.data.general.networkEditor.trim() || "nm-connection-editor"
    readonly property bool nmce: external.split(" ")[0].endsWith("nm-connection-editor")

    Component.onCompleted: {
        Network.refresh();
        refresh();
    }

    function refresh() {
        if (!lister.running)
            lister.running = true;
    }

    // the other app: nm-connection-editor can open one connection or create one
    // the editor command is yours (Settings); its arguments go separately ("$@"), never into the shell text
    function openExternal(extra) {
        Quickshell.execDetached(["sh", "-c", page.external + ' "$@"', "sh"].concat(nmce && extra ? extra : []));
    }

    function open(uuid) {
        if (!inShell) {
            if (/^[0-9a-fA-F-]{8,64}$/.test(String(uuid)))
                openExternal(["--edit=" + uuid]);
            return;
        }
        editing = uuid;
        ed = null;
        error = "";
        needsRoot = false;
        getter.command = [Paths.bin, "net", "get", uuid];
        getter.running = true;
    }

    function close() {
        editing = "";
        ed = null;
        error = "";
        needsRoot = false;
        refresh();
    }

    // runs `flamenco net ARGS…`; a refusal for lack of rights offers a sudo retry
    function run(args, then) {
        error = "";
        needsRoot = false;
        lastArgs = args.map(a => Paths.shellQuote(a)).join(" ");
        runner.then = then ?? null;
        runner.command = [Paths.bin, "net"].concat(args);
        runner.running = true;
    }

    function retryAsRoot() {
        termRunner.command = Paths.termHold(Paths.shellQuote(Paths.bin) + " net " + lastArgs + " --sudo");
        termRunner.running = true;
    }

    function list(v) {
        return (v ?? []).join(", ");
    }

    function loadDraft() {
        const e = ed;
        draft.name = e.name;
        draft.autoconnect = e.autoconnect;
        draft.priority = e.priority;
        draft.metered = e.metered;
        draft.mac = e.mac;
        draft.mtu = e.mtu;
        draft.ssid = e.ssid;
        draft.hidden = e.hidden;
        draft.band = e.band;
        draft.security = e.security;
        draft.password = "";
        pw.text = "";
        for (const f of [4, 6]) {
            const s = e["ip" + f];
            draft["ip" + f + "method"] = s.method;
            draft["ip" + f + "addresses"] = list(s.addresses);
            draft["ip" + f + "gateway"] = s.gateway;
            draft["ip" + f + "dns"] = list(s.dns);
            draft["ip" + f + "autoDns"] = s.autoDns;
            draft["ip" + f + "search"] = list(s.search);
            draft["ip" + f + "neverDefault"] = s.neverDefault;
        }
        draft.ip6privacy = e.ip6.privacy;
        draft.dirty = false;
    }

    function save() {
        const ip = f => ({
            method: draft["ip" + f + "method"], addresses: draft["ip" + f + "addresses"], gateway: draft["ip" + f + "gateway"],
            dns: draft["ip" + f + "dns"], autoDns: draft["ip" + f + "autoDns"], search: draft["ip" + f + "search"],
            neverDefault: draft["ip" + f + "neverDefault"]
        });
        const spec = { name: draft.name, autoconnect: draft.autoconnect, priority: draft.priority, metered: draft.metered, mac: draft.mac, mtu: draft.mtu, ip4: ip(4), ip6: Object.assign(ip(6), { privacy: draft.ip6privacy }) };
        if (ed.type === "wifi") {
            Object.assign(spec, { ssid: draft.ssid, hidden: draft.hidden, band: draft.band });
            if (draft.security !== ed.security || draft.password)
                Object.assign(spec, { security: draft.security, password: draft.password });
        }
        run(["set", ed.uuid, "--json", JSON.stringify(spec)], () => open(ed.uuid));
    }

    QtObject {
        id: draft
        property string name
        property bool autoconnect
        property int priority
        property string metered
        property string mac
        property string mtu
        property string ssid
        property bool hidden
        property string band
        property string security
        property string password
        property string ip4method
        property string ip4addresses
        property string ip4gateway
        property string ip4dns
        property bool ip4autoDns
        property string ip4search
        property bool ip4neverDefault
        property string ip6method
        property string ip6addresses
        property string ip6gateway
        property string ip6dns
        property bool ip6autoDns
        property string ip6search
        property bool ip6neverDefault
        property string ip6privacy
        property bool dirty: false
    }

    Process {
        id: lister
        command: [Paths.bin, "net", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    page.st = JSON.parse(text);
                } catch (e) {}
            }
        }
    }

    Process {
        id: getter
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    page.ed = JSON.parse(text);
                    page.loadDraft();
                } catch (e) {}
            }
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) page.error = text.trim().split("\n").pop().replace(/^flamenco: /, "")
        }
    }

    Process {
        id: runner
        property var then: null
        stdout: StdioCollector { id: runOut }
        stderr: StdioCollector { id: runErr }
        onExited: code => {
            if (code === 0) {
                if (runner.then)
                    runner.then(runOut.text.trim());
            } else {
                page.needsRoot = code === 3;
                page.error = (runErr.text.trim().split("\n").pop() || "nmcli failed").replace(/^flamenco: /, "");
            }
            page.refresh();
            Network.refresh();
        }
    }

    // the sudo retry runs in a terminal; reload once it's closed
    Process {
        id: termRunner
        onExited: {
            page.needsRoot = false;
            page.error = "";
            if (page.editing)
                page.open(page.editing);
            page.refresh();
            Network.refresh();
        }
    }

    // ───────────────────────────── lists ─────────────────────────────

    Group {
        visible: !page.editing
        title: I18n.tr("Editing connections")
        SwitchRow {
            title: I18n.tr("Use Flamenco's editor")
            subtitle: page.inShell ? I18n.tr("Wi-Fi and wired settings open right here") : I18n.tr("Edit opens ") + page.external + " instead"
            icon: "tune"
            target: Settings.data.general
            key: "nativeNetworkEditor"
        }
        TextRow {
            visible: !page.inShell
            title: I18n.tr("Network app")
            subtitle: I18n.tr("The app to open for editing connections")
            icon: "apps"
            target: Settings.data.general
            key: "networkEditor"
            placeholder: "nm-connection-editor"
        }
        SettingRow {
            visible: !page.inShell
            title: I18n.tr("Open ") + page.external
            subtitle: I18n.tr("Everything NetworkManager can do, including VPNs, bridges and 802.1X")
            icon: "open_in_new"
            FButton {
                text: I18n.tr("Open")
                variant: "tonal"
                onClicked: page.openExternal([])
            }
        }
    }

    Group {
        visible: !page.editing
        title: I18n.tr("Wi-Fi")
        SettingRow {
            title: I18n.tr("Wi-Fi")
            subtitle: Network.label
            icon: Network.icon
            FSwitch {
                checked: Network.wifiEnabled
                onToggled: c => Network.setWifi(c)
            }
        }
        SettingRow {
            visible: Network.ssid !== ""
            title: I18n.tr("Share this Wi-Fi")
            subtitle: I18n.tr("A QR code a phone can scan to join ") + Network.ssid + " (needs qrencode)"
            icon: "qr_code_2"
            FButton {
                text: I18n.tr("Show QR code")
                variant: "tonal"
                onClicked: {
                    Panels.settingsOpen = false;
                    Panels.qr = "@wifi";
                }
            }
        }
        SettingRow {
            title: I18n.tr("Networks nearby")
            subtitle: I18n.tr("Pick a network from the control center")
            icon: "wifi_find"
            FButton {
                text: I18n.tr("Show networks")
                variant: "tonal"
                onClicked: Panels.openControl("wifi", "")
            }
        }
        Repeater {
            model: page.wifi
            ConnRow { pg: page }
        }
        SettingRow {
            id: hiddenRow
            title: I18n.tr("Hidden network")
            subtitle: I18n.tr("Join a network that doesn't show its name")
            icon: "wifi_password"
            Row {
                spacing: 8
                FTextField { id: hSsid; implicitWidth: 150; placeholder: I18n.tr("Network name") }
                FTextField { id: hPw; implicitWidth: 150; placeholder: I18n.tr("Password"); password: true }
                FButton {
                    text: I18n.tr("Join")
                    disabled: hSsid.text === "" || runner.running
                    onClicked: page.run(["add-wifi", "--json", JSON.stringify({ ssid: hSsid.text, password: hPw.text, hidden: true })], () => {
                        hSsid.text = "";
                        hPw.text = "";
                    })
                }
            }
        }
    }

    Group {
        visible: !page.editing
        title: I18n.tr("Wired")
        Repeater {
            model: page.st.devices.filter(d => d.type === "ethernet")
            SettingRow {
                required property var modelData
                title: modelData.device + (modelData.speed && modelData.speed !== "unknown" ? " · " + modelData.speed : "")
                subtitle: modelData.state === "connected" ? (modelData.connection + " · " + (modelData.ip4[0] ?? "no IPv4 address"))
                    : modelData.state === "unavailable" ? "Cable unplugged" : modelData.state
                icon: modelData.state === "connected" ? "lan" : "settings_ethernet"
                FText { text: modelData.mac; dim: true; mono: true; font.pixelSize: Theme.fsXs }
            }
        }
        SettingRow {
            visible: page.st.devices.every(d => d.type !== "ethernet")
            title: I18n.tr("No wired network adapter")
            icon: "settings_ethernet"
        }
        Repeater {
            model: page.wired
            ConnRow { pg: page }
        }
        SettingRow {
            title: I18n.tr("Add a wired connection")
            subtitle: I18n.tr("A separate profile, e.g. a fixed address for one network")
            icon: "add"
            FButton {
                text: I18n.tr("Add")
                icon: "add"
                variant: "tonal"
                disabled: runner.running
                onClicked: if (!page.inShell) page.openExternal(["--create", "--type=802-3-ethernet"]); else page.run(["add-ethernet", "Wired connection " + (page.wired.length + 1)], out => {
                    if (/^[0-9a-f-]{36}$/i.test(out))
                        page.open(out);
                })
            }
        }
    }

    Group {
        visible: !page.editing
        title: I18n.tr("VPN")

        SettingRow {
            visible: Network.vpns.length === 0
            title: I18n.tr("No VPN connections yet")
            subtitle: I18n.tr("Import one below")
            icon: "vpn_key_off"
        }

        Repeater {
            model: Network.vpns
            SettingRow {
                id: vrow
                required property var modelData
                title: modelData.name
                subtitle: (modelData.type === "wireguard" ? I18n.tr("WireGuard") : I18n.tr("VPN")) + " · " + (Network.vpnBusy === modelData.name ? "working…" : modelData.active ? I18n.tr("Connected") : I18n.tr("Disconnected"))
                icon: modelData.active ? "vpn_lock" : "vpn_key"
                Row {
                    spacing: 6
                    FSwitch {
                        anchors.verticalCenter: parent.verticalCenter
                        checked: vrow.modelData.active
                        onToggled: c => Network.setVpn(vrow.modelData.name, c)
                    }
                    FIconButton {
                        icon: "delete"
                        size: 32
                        iconColor: Theme.error
                        onClicked: Network.deleteVpn(vrow.modelData.name)
                    }
                }
            }
        }

        SettingRow {
            title: I18n.tr("Import")
            subtitle: I18n.tr("WireGuard .conf or OpenVPN .ovpn file. OpenVPN needs networkmanager-openvpn.")
            icon: "upload_file"
            Row {
                spacing: 8
                FTextField {
                    id: importPath
                    implicitWidth: 240
                    icon: "description"
                    placeholder: "~/Downloads/wg0.conf"
                    onAccepted: if (text) Network.importVpn(text)
                }
                FButton {
                    text: I18n.tr("Import")
                    disabled: importPath.text === ""
                    onClicked: Network.importVpn(importPath.text)
                }
            }
        }

        SettingRow {
            visible: Network.lastError !== ""
            title: I18n.tr("Last error")
            subtitle: Network.lastError
            icon: "error"
        }
    }

    // ───────────────────────────── editor ─────────────────────────────

    Group {
        visible: !!page.editing
        title: page.ed ? (page.ed.type === "wifi" ? I18n.tr("Wi-Fi network") : I18n.tr("Wired connection")) : I18n.tr("Loading…")
        SettingRow {
            title: page.ed?.name ?? ""
            subtitle: !page.ed ? "" : page.ed.active ? I18n.tr("Connected") + (page.ed.device ? " on " + page.ed.device : "") : I18n.tr("Not connected")
            icon: page.ed?.type === "wifi" ? "wifi" : "lan"
            Row {
                spacing: 8
                FButton {
                    text: page.ed?.active ? I18n.tr("Disconnect") : I18n.tr("Connect")
                    variant: "tonal"
                    disabled: !page.ed || runner.running
                    onClicked: page.run([page.ed.active ? "down" : "up", page.ed.uuid], () => page.open(page.ed.uuid))
                }
                FButton {
                    text: I18n.tr("Back")
                    icon: "arrow_back"
                    variant: "text"
                    onClicked: page.close()
                }
            }
        }
    }

    Group {
        visible: !!page.ed
        title: I18n.tr("General")
        TextRow { title: I18n.tr("Name"); icon: "label"; target: draft; key: "name"; onEdited: draft.dirty = true }
        SwitchRow { title: I18n.tr("Connect automatically"); icon: "autorenew"; target: draft; key: "autoconnect"; onEdited: draft.dirty = true }
        SliderRow { visible: draft.autoconnect; title: I18n.tr("Priority"); subtitle: I18n.tr("Higher wins when several saved networks are around"); icon: "low_priority"; target: draft; key: "priority"; from: -10; to: 10; stepSize: 1; onEdited: draft.dirty = true }
        ChoiceRow {
            title: I18n.tr("Metered")
            subtitle: I18n.tr("Apps may hold back big downloads on a metered connection")
            icon: "data_usage"
            target: draft
            key: "metered"
            options: [{ value: "unknown", label: I18n.tr("Automatic") }, { value: "yes", label: I18n.tr("Yes") }, { value: "no", label: I18n.tr("No") }]
            onEdited: draft.dirty = true
        }
        DropdownRow {
            title: I18n.tr("MAC address")
            subtitle: I18n.tr("What this computer shows the network")
            icon: "fingerprint"
            target: draft
            key: "mac"
            options: {
                const o = [{ value: "", label: I18n.tr("Default") }, { value: "permanent", label: I18n.tr("The adapter's own") }, { value: "stable", label: I18n.tr("Random, the same for this network") }, { value: "random", label: I18n.tr("Random each time") }, { value: "preserve", label: I18n.tr("Keep what's set") }];
                if (draft.mac && !o.some(x => x.value === draft.mac))
                    o.push({ value: draft.mac, label: draft.mac });
                return o;
            }
            onEdited: draft.dirty = true
        }
        TextRow { title: I18n.tr("MTU"); subtitle: I18n.tr("Empty for automatic"); icon: "straighten"; target: draft; key: "mtu"; placeholder: I18n.tr("automatic"); onEdited: draft.dirty = true }
    }

    Group {
        visible: page.ed?.type === "wifi"
        title: I18n.tr("Wi-Fi")
        TextRow { title: I18n.tr("Network name (SSID)"); icon: "wifi"; target: draft; key: "ssid"; onEdited: draft.dirty = true }
        SwitchRow { title: I18n.tr("Hidden network"); subtitle: I18n.tr("Look for it even when it doesn't show its name"); icon: "visibility_off"; target: draft; key: "hidden"; onEdited: draft.dirty = true }
        ChoiceRow {
            title: I18n.tr("Band")
            icon: "settings_input_antenna"
            target: draft
            key: "band"
            options: [{ value: "", label: I18n.tr("Any") }, { value: "bg", label: I18n.tr("2.4 GHz") }, { value: "a", label: I18n.tr("5 GHz") }]
            onEdited: draft.dirty = true
        }
        DropdownRow {
            title: I18n.tr("Security")
            icon: "lock"
            target: draft
            key: "security"
            options: {
                const o = [{ value: "none", label: I18n.tr("None (open)") }, { value: "wpa-psk", label: I18n.tr("WPA/WPA2 Personal") }, { value: "sae", label: I18n.tr("WPA3 Personal") }];
                if (page.ed && !o.some(x => x.value === page.ed.security))
                    o.push({ value: page.ed.security, label: page.ed.security === "wpa-eap" ? I18n.tr("Enterprise (802.1X)") : page.ed.security });
                return o;
            }
            onEdited: draft.dirty = true
        }
        SettingRow {
            visible: draft.security === "wpa-psk" || draft.security === "sae"
            title: I18n.tr("Password")
            subtitle: page.ed?.security === draft.security ? I18n.tr("Leave empty to keep the saved one") : I18n.tr("Needed for this security type")
            icon: "password"
            FTextField {
                id: pw
                implicitWidth: 220
                password: true
                placeholder: page.ed?.security === draft.security ? I18n.tr("Unchanged") : I18n.tr("Password")
                onEdited: t => {
                    draft.password = t;
                    draft.dirty = true;
                }
            }
        }
        SettingRow {
            visible: page.ed?.security === "wpa-eap"
            title: I18n.tr("Enterprise sign-in")
            subtitle: "802.1X settings (certificates, identities) aren't edited here; the rest of this page is."
            icon: "badge"
        }
    }

    IpGroup { pg: page; fam: 4 }
    IpGroup { pg: page; fam: 6 }

    Group {
        visible: !!page.ed && !!page.dev
        title: I18n.tr("Details")
        SettingRow { title: I18n.tr("Device"); icon: "memory"; FText { text: (page.dev?.device ?? "") + (page.dev?.driver ? " · " + page.dev.driver : ""); dim: true } }
        SettingRow { title: I18n.tr("Hardware address"); icon: "fingerprint"; FText { text: page.dev?.mac ?? ""; dim: true; mono: true } }
        SettingRow { visible: (page.dev?.speed ?? "") !== "" && page.dev?.speed !== "unknown"; title: I18n.tr("Link speed"); icon: "speed"; FText { text: page.dev?.speed ?? ""; dim: true } }
        SettingRow { title: I18n.tr("IPv4"); icon: "public"; FText { text: page.list(page.dev?.ip4) || "none"; dim: true; mono: true } }
        SettingRow { visible: !!page.dev?.gateway4; title: I18n.tr("Gateway"); icon: "router"; FText { text: page.dev?.gateway4 ?? ""; dim: true; mono: true } }
        SettingRow { visible: (page.dev?.dns4 ?? []).length > 0; title: I18n.tr("DNS"); icon: "dns"; FText { text: page.list(page.dev?.dns4); dim: true; mono: true } }
        SettingRow { visible: (page.dev?.ip6 ?? []).length > 0; title: I18n.tr("IPv6"); icon: "public"; FText { text: page.list(page.dev?.ip6); dim: true; mono: true; elide: Text.ElideMiddle; Layout.maximumWidth: 320 } }
    }

    Group {
        visible: !!page.ed
        title: I18n.tr("Save")
        SettingRow {
            title: draft.dirty ? I18n.tr("Unsaved changes") : I18n.tr("Saved")
            subtitle: page.ed?.active ? I18n.tr("Saving applies the changes to the connection right away") : I18n.tr("Used the next time it connects")
            icon: draft.dirty ? "edit" : "check_circle"
            Row {
                spacing: 8
                FButton { visible: draft.dirty; text: I18n.tr("Revert"); variant: "text"; onClicked: page.loadDraft() }
                FButton { text: I18n.tr("Save"); icon: "done"; disabled: !draft.dirty || runner.running; onClicked: page.save() }
            }
        }
        SettingRow {
            title: I18n.tr("Forget this connection")
            subtitle: page.ed?.type === "wifi" ? I18n.tr("Removes the saved password and settings") : I18n.tr("Removes this profile")
            icon: "delete"
            FButton {
                text: page.armed === page.editing ? I18n.tr("Click again to forget") : I18n.tr("Forget")
                variant: "text"
                onClicked: {
                    if (page.armed !== page.editing) {
                        page.armed = page.editing;
                        return;
                    }
                    page.armed = "";
                    page.run(["delete", page.editing], () => page.close());
                }
            }
        }
    }

    // errors, wherever they came from
    Group {
        visible: page.error !== ""
        title: I18n.tr("Couldn't do that")
        SettingRow {
            title: page.needsRoot ? I18n.tr("NetworkManager wants administrator rights") : page.error
            subtitle: page.needsRoot ? I18n.tr("Run the same change in a terminal with sudo.") : ""
            icon: "error"
            FButton {
                visible: page.needsRoot
                text: I18n.tr("Use sudo")
                variant: "tonal"
                onClicked: page.retryAsRoot()
            }
        }
    }

    // one saved connection in a list
    component ConnRow: SettingRow {
        id: cr
        required property var modelData
        required property var pg
        title: modelData.name
        subtitle: (modelData.active ? I18n.tr("Connected") + (modelData.device ? " on " + modelData.device : "") : I18n.tr("Saved"))
            + (modelData.autoconnect ? "" : " · doesn't connect automatically")
        icon: modelData.type === "wifi" ? (modelData.active ? "wifi" : "wifi_lock") : (modelData.active ? "lan" : "settings_ethernet")
        Row {
            spacing: 4
            FIconButton {
                icon: cr.modelData.active ? "link_off" : "link"
                size: 32
                disabled: cr.pg.busy
                onClicked: cr.pg.run([cr.modelData.active ? "down" : "up", cr.modelData.uuid])
            }
            FIconButton {
                icon: "edit"
                size: 32
                onClicked: cr.pg.open(cr.modelData.uuid)
            }
        }
    }

    // IPv4 or IPv6 settings of the open connection
    component IpGroup: Group {
        id: ig
        required property var pg
        property int fam: 4
        readonly property string p: "ip" + fam
        visible: !!ig.pg.ed
        title: I18n.tr("IPv") + fam
        DropdownRow {
            title: I18n.tr("Method")
            icon: "settings_ethernet"
            target: ig.pg.d
            key: ig.p + "method"
            options: ig.fam === 4
                ? [{ value: "auto", label: I18n.tr("Automatic (DHCP)") }, { value: "manual", label: I18n.tr("Manual") }, { value: "link-local", label: I18n.tr("Link-local only") }, { value: "shared", label: I18n.tr("Share with other computers") }, { value: "disabled", label: I18n.tr("Off") }]
                : [{ value: "auto", label: I18n.tr("Automatic") }, { value: "dhcp", label: I18n.tr("Automatic, DHCP only") }, { value: "manual", label: I18n.tr("Manual") }, { value: "link-local", label: I18n.tr("Link-local only") }, { value: "ignore", label: I18n.tr("Ignore") }, { value: "disabled", label: I18n.tr("Off") }]
            onEdited: ig.pg.d.dirty = true
        }
        TextRow {
            visible: ig.pg.d[ig.p + "method"] === "manual"
            title: I18n.tr("Addresses")
            subtitle: I18n.tr("With the prefix length; separate several with commas")
            icon: "pin"
            target: ig.pg.d
            key: ig.p + "addresses"
            placeholder: ig.fam === 4 ? "192.168.1.50/24" : "2001:db8::50/64"
            onEdited: ig.pg.d.dirty = true
        }
        TextRow {
            visible: ig.pg.d[ig.p + "method"] === "manual"
            title: I18n.tr("Gateway")
            icon: "router"
            target: ig.pg.d
            key: ig.p + "gateway"
            placeholder: ig.fam === 4 ? "192.168.1.1" : "fe80::1"
            onEdited: ig.pg.d.dirty = true
        }
        SwitchRow {
            visible: ig.pg.d[ig.p + "method"] === "auto" || ig.pg.d[ig.p + "method"] === "dhcp"
            title: I18n.tr("Automatic DNS")
            subtitle: I18n.tr("Off: use only the servers below")
            icon: "dns"
            target: ig.pg.d
            key: ig.p + "autoDns"
            onEdited: ig.pg.d.dirty = true
        }
        TextRow {
            visible: ig.pg.d[ig.p + "method"] !== "disabled" && ig.pg.d[ig.p + "method"] !== "ignore"
            title: I18n.tr("DNS servers")
            subtitle: I18n.tr("Separate several with commas")
            icon: "dns"
            target: ig.pg.d
            key: ig.p + "dns"
            placeholder: ig.fam === 4 ? "1.1.1.1, 9.9.9.9" : "2606:4700:4700::1111"
            onEdited: ig.pg.d.dirty = true
        }
        TextRow {
            visible: ig.pg.d[ig.p + "method"] !== "disabled" && ig.pg.d[ig.p + "method"] !== "ignore"
            title: I18n.tr("Search domains")
            icon: "travel_explore"
            target: ig.pg.d
            key: ig.p + "search"
            placeholder: "home.lan"
            onEdited: ig.pg.d.dirty = true
        }
        DropdownRow {
            visible: ig.fam === 6 && ig.pg.d.ip6method !== "disabled" && ig.pg.d.ip6method !== "ignore"
            title: I18n.tr("Privacy extensions")
            subtitle: I18n.tr("Temporary addresses make this computer harder to track")
            icon: "shield"
            target: ig.pg.d
            key: "ip6privacy"
            options: [{ value: "default", label: I18n.tr("System default") }, { value: "off", label: I18n.tr("Off") }, { value: "public", label: I18n.tr("On, prefer the public address") }, { value: "temporary", label: I18n.tr("On, prefer temporary addresses") }]
            onEdited: ig.pg.d.dirty = true
        }
        SwitchRow {
            visible: ig.pg.d[ig.p + "method"] !== "disabled" && ig.pg.d[ig.p + "method"] !== "ignore"
            title: I18n.tr("Only for its own network")
            subtitle: I18n.tr("Don't send other traffic (the internet) through this connection")
            icon: "alt_route"
            target: ig.pg.d
            key: ig.p + "neverDefault"
            onEdited: ig.pg.d.dirty = true
        }
    }
}
