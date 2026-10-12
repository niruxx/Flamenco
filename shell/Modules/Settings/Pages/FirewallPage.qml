import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services
import qs.Widgets

// ufw / firewalld. Reads without root where possible; changes are queued and
// applied together in a terminal with one sudo prompt.
Page {
    id: page
    title: "Firewall"
    subtitle: "Detects ufw or firewalld. Changes are collected below and applied together; that step asks for your password in a terminal."

    property var st: ({ backend: "", conflict: false, ufw: { installed: false }, firewalld: { installed: false } })
    property bool loaded: false
    property string backend: ""            // which one this page manages
    property var ops: []                   // queued changes: [{ op, ..., label }]
    property string zone: ""               // firewalld zone being edited

    readonly property var ufw: st.ufw ?? ({})
    readonly property var fwd: st.firewalld ?? ({})
    readonly property var cur: backend === "ufw" ? ufw : backend === "firewalld" ? fwd : ({})
    readonly property bool running: cur.service?.active ?? false
    readonly property var zoneInfo: fwd.zoneInfo?.[zone] ?? ({ ports: [], services: [], target: "" })

    function refresh() {
        if (!getter.running)
            getter.running = true;
    }
    function queue(op, label) {
        ops = ops.concat([Object.assign({ label: label }, op)]);
    }
    function unqueue(i) {
        ops = ops.filter((_, j) => j !== i);
    }
    function runInTerminal(args) {
        runner.command = Paths.termHold(Paths.shellQuote(Paths.bin) + " firewall " + args);
        runner.running = true;
    }
    function apply() {
        const spec = { backend: page.backend, ops: page.ops.map(o => { const c = Object.assign({}, o); delete c.label; return c; }) };
        runInTerminal("apply --json " + Paths.shellQuote(JSON.stringify(spec)));
    }

    Component.onCompleted: refresh()

    Process {
        id: getter
        command: [Paths.bin, "firewall", "status", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    page.st = JSON.parse(text);
                    if (!page.backend || !page.st[page.backend]?.installed)
                        page.backend = page.st.backend;
                    if (!page.zone || !(page.fwd.zones ?? []).includes(page.zone))
                        page.zone = page.fwd.defaultZone ?? "";
                    page.loaded = true;
                } catch (e) {}
            }
        }
    }

    // the terminal closes when the user is done; then re-read everything
    Process {
        id: runner
        onExited: {
            page.ops = [];
            page.refresh();
        }
    }

    // ── pending changes ──
    Rectangle {
        visible: page.ops.length > 0
        Layout.fillWidth: true
        implicitHeight: pend.implicitHeight + Theme.sp4 * 2
        radius: Theme.rLg
        color: Theme.alpha(Theme.accent, 0.12)
        border.width: 1
        border.color: Theme.alpha(Theme.accent, 0.5)

        ColumnLayout {
            id: pend
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Theme.sp4
            spacing: 6

            FText { text: page.ops.length + " pending change" + (page.ops.length > 1 ? "s" : ""); font.weight: Font.Bold }
            Repeater {
                model: page.ops
                RowLayout {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    FIcon { icon: "pending_actions"; size: 16; color: Theme.accent }
                    FText { Layout.fillWidth: true; text: modelData.label; elide: Text.ElideRight }
                    FIconButton { icon: "close"; size: 26; iconSize: 14; onClicked: page.unqueue(index) }
                }
            }
            RowLayout {
                spacing: 8
                FButton { text: "Apply"; icon: "admin_panel_settings"; disabled: runner.running; onClicked: page.apply() }
                FButton { text: "Discard"; variant: "outlined"; onClicked: page.ops = [] }
            }
        }
    }

    // ── status ──
    Group {
        title: "Status"

        SettingRow {
            visible: page.loaded && !page.backend
            title: "No firewall installed"
            subtitle: "ufw is simpler; firewalld adds zones (groups of rules per network)"
            icon: "shield"
            Row {
                spacing: 6
                FButton { text: "Install ufw"; variant: "tonal"; onClicked: Quickshell.execDetached(Paths.termHold("sudo pacman -S --needed ufw")) }
                FButton { text: "Install firewalld"; variant: "tonal"; onClicked: Quickshell.execDetached(Paths.termHold("sudo pacman -S --needed firewalld")) }
            }
        }

        SettingRow {
            visible: page.ufw.installed && page.fwd.installed
            title: "Manage"
            subtitle: page.st.conflict ? "Both are running, and their rules clash. Disable one of them." : "Both are installed; only one should run"
            icon: page.st.conflict ? "warning" : "compare_arrows"
            FSegmented {
                implicitWidth: 260
                options: [{ value: "ufw", label: "ufw" }, { value: "firewalld", label: "firewalld" }]
                current: page.backend
                onSelected: v => page.backend = v
            }
        }

        SettingRow {
            visible: page.backend !== ""
            title: page.backend + (page.running ? " is on" : " is off")
            subtitle: (page.cur.service?.enabled ? "Starts at boot" : "Doesn't start at boot") + (page.backend === "ufw" && page.ufw.enabled !== undefined ? " · rules " + (page.ufw.enabled ? "enabled" : "disabled") : "")
            icon: page.running ? "verified_user" : "gpp_bad"
            FSwitch {
                checked: page.running
                onToggled: c => page.queue({ op: c ? "enable" : "disable" }, (c ? "Turn on " : "Turn off ") + page.backend)
            }
        }
    }

    // ── ufw ──
    Group {
        visible: page.backend === "ufw"
        title: "Defaults"
        SettingRow {
            title: "Incoming connections"
            subtitle: "What happens to traffic no rule mentions"
            icon: "call_received"
            FDropdown {
                implicitWidth: 220
                options: [{ value: "deny", label: "Deny (recommended)" }, { value: "reject", label: "Reject" }, { value: "allow", label: "Allow" }]
                current: page.ufw.incoming ?? ""
                onSelected: v => page.queue({ op: "default", policy: v, direction: "incoming" }, "Incoming default: " + v)
            }
        }
        SettingRow {
            title: "Outgoing connections"
            icon: "call_made"
            FDropdown {
                implicitWidth: 220
                options: [{ value: "allow", label: "Allow (recommended)" }, { value: "deny", label: "Deny" }, { value: "reject", label: "Reject" }]
                current: page.ufw.outgoing ?? ""
                onSelected: v => page.queue({ op: "default", policy: v, direction: "outgoing" }, "Outgoing default: " + v)
            }
        }
        SettingRow {
            title: "Logging"
            icon: "receipt_long"
            FDropdown {
                implicitWidth: 220
                options: ["off", "low", "medium", "high", "full"]
                current: page.ufw.logging ?? ""
                onSelected: v => page.queue({ op: "logging", level: v }, "Logging: " + v)
            }
        }
    }

    Group {
        visible: page.backend === "ufw"
        title: "Rules"

        SettingRow {
            visible: page.ufw.rules === null || page.ufw.rules === undefined
            title: "Reading rules needs your password"
            subtitle: "ufw only shows its rules to root. Flamenco keeps a copy after each change."
            icon: "lock"
            FButton { text: "Load rules"; icon: "key"; disabled: runner.running; onClicked: page.runInTerminal("load") }
        }

        SettingRow {
            visible: Array.isArray(page.ufw.rules) && page.ufw.rules.length === 0
            title: "No rules"
            subtitle: "Everything incoming follows the default above"
            icon: "rule"
        }

        Repeater {
            model: Array.isArray(page.ufw.rules) ? page.ufw.rules : []
            SettingRow {
                id: rrow
                required property var modelData
                readonly property bool queuedDelete: page.ops.some(o => o.op === "delete" && o.num === modelData.num)
                title: modelData.to + "  ·  " + modelData.action.toLowerCase() + " " + modelData.direction.toLowerCase()
                subtitle: "from " + modelData.from + (modelData.comment ? " · " + modelData.comment : "") + (queuedDelete ? " · will be deleted" : "")
                icon: modelData.action === "ALLOW" ? "check_circle" : modelData.action === "LIMIT" ? "speed" : "block"
                FIconButton {
                    icon: "delete"
                    iconColor: Theme.error
                    disabled: rrow.queuedDelete
                    onClicked: page.queue({ op: "delete", num: rrow.modelData.num }, "Delete rule " + rrow.modelData.num + ": " + rrow.modelData.to + " " + rrow.modelData.action.toLowerCase())
                }
            }
        }

        SettingRow {
            visible: (page.ufw.rulesTime ?? 0) > 0
            title: "Rules as of " + Qt.formatDateTime(new Date((page.ufw.rulesTime ?? 0) * 1000), "ddd HH:mm")
            icon: "history"
            FButton { text: "Reload"; variant: "tonal"; disabled: runner.running; onClicked: page.runInTerminal("load") }
        }

        // add a rule
        ColumnLayout {
            Layout.fillWidth: true
            Layout.margins: 12
            spacing: 8
            FText { text: "Add a rule"; font.weight: Font.Bold }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                FTextField { id: uPort; Layout.preferredWidth: 150; icon: "lan"; placeholder: "port or 6000:6010" }
                FSegmented { id: uProto; implicitWidth: 200; options: [{ value: "tcp", label: "TCP" }, { value: "udp", label: "UDP" }, { value: "", label: "Both" }]; current: "tcp"; onSelected: v => current = v }
                FDropdown { id: uAction; implicitWidth: 130; options: ["allow", "deny", "reject", "limit"]; current: "allow"; onSelected: v => current = v }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                FTextField { id: uFrom; Layout.fillWidth: true; icon: "public"; placeholder: "from (optional): 192.168.1.0/24" }
                FTextField { id: uComment; Layout.fillWidth: true; icon: "label"; placeholder: "comment (optional)" }
                FButton {
                    text: "Add"
                    icon: "add"
                    disabled: uPort.text.trim() === ""
                    onClicked: {
                        const port = uPort.text.trim() + (uProto.current ? "/" + uProto.current : "");
                        page.queue({ op: "add", port: port, action: uAction.current, from: uFrom.text.trim(), comment: uComment.text.trim() }, uAction.current + " " + port + (uFrom.text.trim() ? " from " + uFrom.text.trim() : ""));
                        uPort.text = "";
                        uFrom.text = "";
                        uComment.text = "";
                    }
                }
            }
        }
    }

    // ── firewalld ──
    Group {
        visible: page.backend === "firewalld" && page.running
        title: "Zones"

        SettingRow {
            visible: !page.fwd.readable
            title: "Couldn't read firewalld"
            subtitle: "firewall-cmd was refused; check that your user may query firewalld (polkit)"
            icon: "warning"
        }

        SettingRow {
            visible: page.fwd.readable ?? false
            title: "Zone"
            subtitle: "Each zone is a set of rules; each network interface belongs to one" + (page.zone === page.fwd.defaultZone ? " · this is the default zone" : "")
            icon: "workspaces"
            Row {
                spacing: 6
                FDropdown {
                    implicitWidth: 200
                    options: (page.fwd.zones ?? []).map(z => ({ value: z, label: z + (z === page.fwd.defaultZone ? " (default)" : "") + ((page.fwd.activeZones ?? {})[z] ? " · active" : "") }))
                    current: page.zone
                    onSelected: v => page.zone = v
                }
                FButton {
                    visible: page.zone !== page.fwd.defaultZone
                    text: "Make default"
                    variant: "tonal"
                    onClicked: page.queue({ op: "set-default-zone", zone: page.zone }, "Default zone: " + page.zone)
                }
            }
        }

        Repeater {
            model: Object.keys(page.fwd.activeZones ?? {}).flatMap(z => (page.fwd.activeZones[z] || []).map(i => ({ iface: i, zone: z })))
            SettingRow {
                id: irow
                required property var modelData
                title: "Interface " + modelData.iface
                subtitle: "In zone " + modelData.zone
                icon: "settings_ethernet"
                FDropdown {
                    implicitWidth: 200
                    options: page.fwd.zones ?? []
                    current: irow.modelData.zone
                    onSelected: v => page.queue({ op: "zone-interface", zone: v, interface: irow.modelData.iface }, "Move " + irow.modelData.iface + " to " + v)
                }
            }
        }
    }

    Group {
        visible: page.backend === "firewalld" && page.running && (page.fwd.readable ?? false)
        title: "Open in “" + page.zone + "”"

        Repeater {
            model: page.zoneInfo.ports ?? []
            SettingRow {
                id: prow
                required property string modelData
                title: modelData
                subtitle: "Port"
                icon: "lan"
                FIconButton { icon: "delete"; iconColor: Theme.error; onClicked: page.queue({ op: "remove-port", zone: page.zone, port: prow.modelData }, "Close " + prow.modelData + " in " + page.zone) }
            }
        }
        Repeater {
            model: page.zoneInfo.services ?? []
            SettingRow {
                id: srow
                required property string modelData
                title: modelData
                subtitle: "Service"
                icon: "dns"
                FIconButton { icon: "delete"; iconColor: Theme.error; onClicked: page.queue({ op: "remove-service", zone: page.zone, name: srow.modelData }, "Remove " + srow.modelData + " from " + page.zone) }
            }
        }
        SettingRow {
            visible: (page.zoneInfo.ports ?? []).length === 0 && (page.zoneInfo.services ?? []).length === 0
            title: "Nothing open in this zone"
            icon: "shield"
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 12
            spacing: 8
            FTextField { id: fPort; Layout.preferredWidth: 160; icon: "lan"; placeholder: "port or 6000-6010" }
            FSegmented { id: fProto; implicitWidth: 150; options: [{ value: "tcp", label: "TCP" }, { value: "udp", label: "UDP" }]; current: "tcp"; onSelected: v => current = v }
            FButton {
                text: "Open port"
                icon: "add"
                disabled: fPort.text.trim() === ""
                onClicked: {
                    const port = fPort.text.trim().replace("-", ":") + "/" + fProto.current;
                    page.queue({ op: "add-port", zone: page.zone, port: port }, "Open " + port + " in " + page.zone);
                    fPort.text = "";
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 12
            Layout.topMargin: 0
            spacing: 8
            FDropdown {
                id: fService
                Layout.fillWidth: true
                placeholder: "Add a service (ssh, http, samba…)"
                options: (page.fwd.services ?? []).filter(x => !(page.zoneInfo.services ?? []).includes(x))
                current: ""
                onSelected: v => page.queue({ op: "add-service", zone: page.zone, name: v }, "Allow " + v + " in " + page.zone)
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        FIconButton { icon: "refresh"; onClicked: page.refresh() }
        FText { text: getter.running ? "Reading firewall…" : ""; dim: true }
    }
}
