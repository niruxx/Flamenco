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
    title: "Wi-Fi & Network"
    subtitle: page.editing ? "" : "Wi-Fi, wired and VPN connections, through NetworkManager."

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
        title: "Editing connections"
        SwitchRow {
            title: "Use Flamenco's editor"
            subtitle: page.inShell ? "Wi-Fi and wired settings open right here" : "Edit opens " + page.external + " instead"
            icon: "tune"
            target: Settings.data.general
            key: "nativeNetworkEditor"
        }
        TextRow {
            visible: !page.inShell
            title: "Network app"
            subtitle: "The app to open for editing connections"
            icon: "apps"
            target: Settings.data.general
            key: "networkEditor"
            placeholder: "nm-connection-editor"
        }
        SettingRow {
            visible: !page.inShell
            title: "Open " + page.external
            subtitle: "Everything NetworkManager can do, including VPNs, bridges and 802.1X"
            icon: "open_in_new"
            FButton {
                text: "Open"
                variant: "tonal"
                onClicked: page.openExternal([])
            }
        }
    }

    Group {
        visible: !page.editing
        title: "Wi-Fi"
        SettingRow {
            title: "Wi-Fi"
            subtitle: Network.label
            icon: Network.icon
            FSwitch {
                checked: Network.wifiEnabled
                onToggled: c => Network.setWifi(c)
            }
        }
        SettingRow {
            visible: Network.ssid !== ""
            title: "Share this Wi-Fi"
            subtitle: "A QR code a phone can scan to join " + Network.ssid + " (needs qrencode)"
            icon: "qr_code_2"
            FButton {
                text: "Show QR code"
                variant: "tonal"
                onClicked: {
                    Panels.settingsOpen = false;
                    Panels.qr = "@wifi";
                }
            }
        }
        SettingRow {
            title: "Networks nearby"
            subtitle: "Pick a network from the control center"
            icon: "wifi_find"
            FButton {
                text: "Show networks"
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
            title: "Hidden network"
            subtitle: "Join a network that doesn't show its name"
            icon: "wifi_password"
            Row {
                spacing: 8
                FTextField { id: hSsid; implicitWidth: 150; placeholder: "Network name" }
                FTextField { id: hPw; implicitWidth: 150; placeholder: "Password"; password: true }
                FButton {
                    text: "Join"
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
        title: "Wired"
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
            title: "No wired network adapter"
            icon: "settings_ethernet"
        }
        Repeater {
            model: page.wired
            ConnRow { pg: page }
        }
        SettingRow {
            title: "Add a wired connection"
            subtitle: "A separate profile, e.g. a fixed address for one network"
            icon: "add"
            FButton {
                text: "Add"
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
        title: "VPN"

        SettingRow {
            visible: Network.vpns.length === 0
            title: "No VPN connections yet"
            subtitle: "Import one below"
            icon: "vpn_key_off"
        }

        Repeater {
            model: Network.vpns
            SettingRow {
                id: vrow
                required property var modelData
                title: modelData.name
                subtitle: (modelData.type === "wireguard" ? "WireGuard" : "VPN") + " · " + (Network.vpnBusy === modelData.name ? "working…" : modelData.active ? "Connected" : "Disconnected")
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
            title: "Import"
            subtitle: "WireGuard .conf or OpenVPN .ovpn file. OpenVPN needs networkmanager-openvpn."
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
                    text: "Import"
                    disabled: importPath.text === ""
                    onClicked: Network.importVpn(importPath.text)
                }
            }
        }

        SettingRow {
            visible: Network.lastError !== ""
            title: "Last error"
            subtitle: Network.lastError
            icon: "error"
        }
    }

    // ───────────────────────────── editor ─────────────────────────────

    Group {
        visible: !!page.editing
        title: page.ed ? (page.ed.type === "wifi" ? "Wi-Fi network" : "Wired connection") : "Loading…"
        SettingRow {
            title: page.ed?.name ?? ""
            subtitle: !page.ed ? "" : page.ed.active ? "Connected" + (page.ed.device ? " on " + page.ed.device : "") : "Not connected"
            icon: page.ed?.type === "wifi" ? "wifi" : "lan"
            Row {
                spacing: 8
                FButton {
                    text: page.ed?.active ? "Disconnect" : "Connect"
                    variant: "tonal"
                    disabled: !page.ed || runner.running
                    onClicked: page.run([page.ed.active ? "down" : "up", page.ed.uuid], () => page.open(page.ed.uuid))
                }
                FButton {
                    text: "Back"
                    icon: "arrow_back"
                    variant: "text"
                    onClicked: page.close()
                }
            }
        }
    }

    Group {
        visible: !!page.ed
        title: "General"
        TextRow { title: "Name"; icon: "label"; target: draft; key: "name"; onEdited: draft.dirty = true }
        SwitchRow { title: "Connect automatically"; icon: "autorenew"; target: draft; key: "autoconnect"; onEdited: draft.dirty = true }
        SliderRow { visible: draft.autoconnect; title: "Priority"; subtitle: "Higher wins when several saved networks are around"; icon: "low_priority"; target: draft; key: "priority"; from: -10; to: 10; stepSize: 1; onEdited: draft.dirty = true }
        ChoiceRow {
            title: "Metered"
            subtitle: "Apps may hold back big downloads on a metered connection"
            icon: "data_usage"
            target: draft
            key: "metered"
            options: [{ value: "unknown", label: "Automatic" }, { value: "yes", label: "Yes" }, { value: "no", label: "No" }]
            onEdited: draft.dirty = true
        }
        DropdownRow {
            title: "MAC address"
            subtitle: "What this computer shows the network"
            icon: "fingerprint"
            target: draft
            key: "mac"
            options: {
                const o = [{ value: "", label: "Default" }, { value: "permanent", label: "The adapter's own" }, { value: "stable", label: "Random, the same for this network" }, { value: "random", label: "Random each time" }, { value: "preserve", label: "Keep what's set" }];
                if (draft.mac && !o.some(x => x.value === draft.mac))
                    o.push({ value: draft.mac, label: draft.mac });
                return o;
            }
            onEdited: draft.dirty = true
        }
        TextRow { title: "MTU"; subtitle: "Empty for automatic"; icon: "straighten"; target: draft; key: "mtu"; placeholder: "automatic"; onEdited: draft.dirty = true }
    }

    Group {
        visible: page.ed?.type === "wifi"
        title: "Wi-Fi"
        TextRow { title: "Network name (SSID)"; icon: "wifi"; target: draft; key: "ssid"; onEdited: draft.dirty = true }
        SwitchRow { title: "Hidden network"; subtitle: "Look for it even when it doesn't show its name"; icon: "visibility_off"; target: draft; key: "hidden"; onEdited: draft.dirty = true }
        ChoiceRow {
            title: "Band"
            icon: "settings_input_antenna"
            target: draft
            key: "band"
            options: [{ value: "", label: "Any" }, { value: "bg", label: "2.4 GHz" }, { value: "a", label: "5 GHz" }]
            onEdited: draft.dirty = true
        }
        DropdownRow {
            title: "Security"
            icon: "lock"
            target: draft
            key: "security"
            options: {
                const o = [{ value: "none", label: "None (open)" }, { value: "wpa-psk", label: "WPA/WPA2 Personal" }, { value: "sae", label: "WPA3 Personal" }];
                if (page.ed && !o.some(x => x.value === page.ed.security))
                    o.push({ value: page.ed.security, label: page.ed.security === "wpa-eap" ? "Enterprise (802.1X)" : page.ed.security });
                return o;
            }
            onEdited: draft.dirty = true
        }
        SettingRow {
            visible: draft.security === "wpa-psk" || draft.security === "sae"
            title: "Password"
            subtitle: page.ed?.security === draft.security ? "Leave empty to keep the saved one" : "Needed for this security type"
            icon: "password"
            FTextField {
                id: pw
                implicitWidth: 220
                password: true
                placeholder: page.ed?.security === draft.security ? "Unchanged" : "Password"
                onEdited: t => {
                    draft.password = t;
                    draft.dirty = true;
                }
            }
        }
        SettingRow {
            visible: page.ed?.security === "wpa-eap"
            title: "Enterprise sign-in"
            subtitle: "802.1X settings (certificates, identities) aren't edited here; the rest of this page is."
            icon: "badge"
        }
    }

    IpGroup { pg: page; fam: 4 }
    IpGroup { pg: page; fam: 6 }

    Group {
        visible: !!page.ed && !!page.dev
        title: "Details"
        SettingRow { title: "Device"; icon: "memory"; FText { text: (page.dev?.device ?? "") + (page.dev?.driver ? " · " + page.dev.driver : ""); dim: true } }
        SettingRow { title: "Hardware address"; icon: "fingerprint"; FText { text: page.dev?.mac ?? ""; dim: true; mono: true } }
        SettingRow { visible: (page.dev?.speed ?? "") !== "" && page.dev?.speed !== "unknown"; title: "Link speed"; icon: "speed"; FText { text: page.dev?.speed ?? ""; dim: true } }
        SettingRow { title: "IPv4"; icon: "public"; FText { text: page.list(page.dev?.ip4) || "none"; dim: true; mono: true } }
        SettingRow { visible: !!page.dev?.gateway4; title: "Gateway"; icon: "router"; FText { text: page.dev?.gateway4 ?? ""; dim: true; mono: true } }
        SettingRow { visible: (page.dev?.dns4 ?? []).length > 0; title: "DNS"; icon: "dns"; FText { text: page.list(page.dev?.dns4); dim: true; mono: true } }
        SettingRow { visible: (page.dev?.ip6 ?? []).length > 0; title: "IPv6"; icon: "public"; FText { text: page.list(page.dev?.ip6); dim: true; mono: true; elide: Text.ElideMiddle; Layout.maximumWidth: 320 } }
    }

    Group {
        visible: !!page.ed
        title: "Save"
        SettingRow {
            title: draft.dirty ? "Unsaved changes" : "Saved"
            subtitle: page.ed?.active ? "Saving applies the changes to the connection right away" : "Used the next time it connects"
            icon: draft.dirty ? "edit" : "check_circle"
            Row {
                spacing: 8
                FButton { visible: draft.dirty; text: "Revert"; variant: "text"; onClicked: page.loadDraft() }
                FButton { text: "Save"; icon: "done"; disabled: !draft.dirty || runner.running; onClicked: page.save() }
            }
        }
        SettingRow {
            title: "Forget this connection"
            subtitle: page.ed?.type === "wifi" ? "Removes the saved password and settings" : "Removes this profile"
            icon: "delete"
            FButton {
                text: page.armed === page.editing ? "Click again to forget" : "Forget"
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
        title: "Couldn't do that"
        SettingRow {
            title: page.needsRoot ? "NetworkManager wants administrator rights" : page.error
            subtitle: page.needsRoot ? "Run the same change in a terminal with sudo." : ""
            icon: "error"
            FButton {
                visible: page.needsRoot
                text: "Use sudo"
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
        subtitle: (modelData.active ? "Connected" + (modelData.device ? " on " + modelData.device : "") : "Saved")
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
        title: "IPv" + fam
        DropdownRow {
            title: "Method"
            icon: "settings_ethernet"
            target: ig.pg.d
            key: ig.p + "method"
            options: ig.fam === 4
                ? [{ value: "auto", label: "Automatic (DHCP)" }, { value: "manual", label: "Manual" }, { value: "link-local", label: "Link-local only" }, { value: "shared", label: "Share with other computers" }, { value: "disabled", label: "Off" }]
                : [{ value: "auto", label: "Automatic" }, { value: "dhcp", label: "Automatic, DHCP only" }, { value: "manual", label: "Manual" }, { value: "link-local", label: "Link-local only" }, { value: "ignore", label: "Ignore" }, { value: "disabled", label: "Off" }]
            onEdited: ig.pg.d.dirty = true
        }
        TextRow {
            visible: ig.pg.d[ig.p + "method"] === "manual"
            title: "Addresses"
            subtitle: "With the prefix length; separate several with commas"
            icon: "pin"
            target: ig.pg.d
            key: ig.p + "addresses"
            placeholder: ig.fam === 4 ? "192.168.1.50/24" : "2001:db8::50/64"
            onEdited: ig.pg.d.dirty = true
        }
        TextRow {
            visible: ig.pg.d[ig.p + "method"] === "manual"
            title: "Gateway"
            icon: "router"
            target: ig.pg.d
            key: ig.p + "gateway"
            placeholder: ig.fam === 4 ? "192.168.1.1" : "fe80::1"
            onEdited: ig.pg.d.dirty = true
        }
        SwitchRow {
            visible: ig.pg.d[ig.p + "method"] === "auto" || ig.pg.d[ig.p + "method"] === "dhcp"
            title: "Automatic DNS"
            subtitle: "Off: use only the servers below"
            icon: "dns"
            target: ig.pg.d
            key: ig.p + "autoDns"
            onEdited: ig.pg.d.dirty = true
        }
        TextRow {
            visible: ig.pg.d[ig.p + "method"] !== "disabled" && ig.pg.d[ig.p + "method"] !== "ignore"
            title: "DNS servers"
            subtitle: "Separate several with commas"
            icon: "dns"
            target: ig.pg.d
            key: ig.p + "dns"
            placeholder: ig.fam === 4 ? "1.1.1.1, 9.9.9.9" : "2606:4700:4700::1111"
            onEdited: ig.pg.d.dirty = true
        }
        TextRow {
            visible: ig.pg.d[ig.p + "method"] !== "disabled" && ig.pg.d[ig.p + "method"] !== "ignore"
            title: "Search domains"
            icon: "travel_explore"
            target: ig.pg.d
            key: ig.p + "search"
            placeholder: "home.lan"
            onEdited: ig.pg.d.dirty = true
        }
        DropdownRow {
            visible: ig.fam === 6 && ig.pg.d.ip6method !== "disabled" && ig.pg.d.ip6method !== "ignore"
            title: "Privacy extensions"
            subtitle: "Temporary addresses make this computer harder to track"
            icon: "shield"
            target: ig.pg.d
            key: "ip6privacy"
            options: [{ value: "default", label: "System default" }, { value: "off", label: "Off" }, { value: "public", label: "On, prefer the public address" }, { value: "temporary", label: "On, prefer temporary addresses" }]
            onEdited: ig.pg.d.dirty = true
        }
        SwitchRow {
            visible: ig.pg.d[ig.p + "method"] !== "disabled" && ig.pg.d[ig.p + "method"] !== "ignore"
            title: "Only for its own network"
            subtitle: "Don't send other traffic (the internet) through this connection"
            icon: "alt_route"
            target: ig.pg.d
            key: ig.p + "neverDefault"
            onEdited: ig.pg.d.dirty = true
        }
    }
}
