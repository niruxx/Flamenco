import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services
import qs.Widgets

// Which Secret Service (org.freedesktop.secrets) provider apps use for passwords.
Page {
    id: page
    title: I18n.tr("Keyring")
    subtitle: I18n.tr("Where apps (browsers, mail, Git, VS Code…) keep your passwords. Pick which keyring answers them.")

    property var st: ({ chosen: "", owner: {}, pam: {}, keyrings: [] })
    property bool loaded: false
    property string status: ""

    readonly property var current: st.keyrings.find(k => k.value === (st.owner.kind || st.chosen)) ?? null
    readonly property var pamServices: Object.keys(st.pam ?? {})
    readonly property var unlocking: pamServices.filter(s => (st.pam[s] ?? []).length > 0)

    function load() {
        if (!getter.running)
            getter.running = true;
    }
    function use(kind) {
        user.command = [Paths.bin, "keyring", "use", kind];
        user.running = true;
    }

    Component.onCompleted: load()

    Process {
        id: getter
        command: [Paths.bin, "keyring", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    page.st = JSON.parse(text);
                    page.loaded = true;
                } catch (e) {}
            }
        }
    }
    Process {
        id: user
        stdout: StdioCollector { onStreamFinished: if (text.trim()) page.status = text.trim().replace(/^keyring: /, "") }
        stderr: StdioCollector { onStreamFinished: if (text.trim()) page.status = text.trim().split("\n").pop().replace(/^flamenco: /, "") }
        onExited: page.load()
    }

    // ── status ──
    FCard {
        Layout.fillWidth: true
        implicitHeight: statusRow.implicitHeight + Theme.sp4 * 2
        RowLayout {
            id: statusRow
            anchors.fill: parent
            anchors.margins: Theme.sp4
            spacing: Theme.sp3
            FIcon {
                icon: page.st.owner.process ? "key" : "key_off"
                size: 32
                fill: 1
                color: page.st.owner.process ? Theme.success : Theme.textDim
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                FText {
                    text: !page.loaded ? I18n.tr("Checking…") : page.st.owner.process ? (page.current ? page.current.label : page.st.owner.process) + " is answering apps" : I18n.tr("No keyring is running right now")
                    font.pixelSize: Theme.fsLg
                    font.weight: Font.Bold
                }
                FText {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    dim: true
                    text: page.st.chosen === "none" ? I18n.tr("Set to none: apps can't store passwords") : page.st.chosen ? I18n.tr("Chosen in Flamenco; starts automatically when an app needs it") : I18n.tr("Using the system default (whichever keyring starts first)")
                }
            }
            FIconButton { icon: "refresh"; onClicked: page.load() }
        }
    }

    // ── choices ──
    Group {
        title: I18n.tr("Keyring")

        Repeater {
            model: page.st.keyrings
            SettingRow {
                id: kr
                required property var modelData
                readonly property bool chosen: page.st.chosen === modelData.value
                title: modelData.label + (chosen ? "  ✓ selected" : "")
                subtitle: modelData.note + (modelData.installed ? "" : " Not installed (" + modelData.package + ").")
                icon: chosen ? "radio_button_checked" : "radio_button_unchecked"
                Row {
                    spacing: 6
                    FButton {
                        visible: !kr.modelData.installed
                        text: I18n.tr("Install")
                        variant: "tonal"
                        onClicked: Quickshell.execDetached(Paths.termHold("sudo pacman -S --needed " + kr.modelData.package + (kr.modelData.managerPackage && kr.modelData.managerPackage !== kr.modelData.package ? " " + kr.modelData.managerPackage : "")))
                    }
                    FButton {
                        visible: kr.modelData.installed && kr.modelData.managerInstalled
                        text: I18n.tr("Open")
                        variant: "outlined"
                        onClicked: Quickshell.execDetached(kr.modelData.manager)
                    }
                    FButton {
                        visible: kr.modelData.installed
                        text: kr.chosen ? I18n.tr("In use") : I18n.tr("Use")
                        disabled: kr.chosen || user.running
                        onClicked: page.use(kr.modelData.value)
                    }
                }
            }
        }

        SettingRow {
            title: I18n.tr("None")
            subtitle: I18n.tr("Don't start any keyring; apps that need one will ask or fail to save passwords")
            icon: page.st.chosen === "none" ? "radio_button_checked" : "radio_button_unchecked"
            FButton {
                text: page.st.chosen === "none" ? I18n.tr("In use") : I18n.tr("Use")
                variant: "outlined"
                disabled: page.st.chosen === "none" || user.running
                onClicked: page.use("none")
            }
        }

        SettingRow {
            visible: page.st.chosen !== ""
            title: I18n.tr("Back to the system default")
            subtitle: I18n.tr("Remove Flamenco's choice and let whichever keyring starts first answer")
            icon: "undo"
            FButton {
                text: I18n.tr("Reset")
                variant: "outlined"
                disabled: user.running
                onClicked: page.use("default")
            }
        }

        SettingRow {
            visible: page.status !== ""
            title: page.status
            icon: "info"
        }
    }

    // ── unlock at login ──
    Group {
        title: I18n.tr("Unlock at login")

        SettingRow {
            visible: page.unlocking.length > 0
            title: I18n.tr("Unlocks automatically")
            subtitle: page.unlocking.map(s => s + ": " + page.st.pam[s].join(", ")).join(" · ")
            icon: "lock_open"
        }

        SettingRow {
            visible: page.loaded && page.unlocking.length === 0
            title: I18n.tr("Your keyring will ask for its password once per session")
            subtitle: I18n.tr("To unlock it with your login password, the login manager's PAM file needs the module below. Flamenco doesn't edit PAM files automatically, because a mistake there can stop you logging in.")
            icon: "password"
        }

        Rectangle {
            visible: page.loaded && page.unlocking.length === 0 && (page.current?.pam ?? "") !== ""
            Layout.fillWidth: true
            Layout.margins: 12
            implicitHeight: pamText.implicitHeight + 24
            radius: Theme.rMd
            color: Theme.bg
            FText {
                id: pamText
                anchors.fill: parent
                anchors.margins: 12
                mono: true
                wrapMode: Text.WrapAnywhere
                font.pixelSize: Theme.fsSm
                text: "# add to /etc/pam.d/" + (page.pamServices.includes("sddm") ? "sddm" : page.pamServices.includes("greetd") ? "greetd" : "login") + "\n"
                    + "auth     optional  " + (page.current?.pam ?? "") + "\n"
                    + "session  optional  " + (page.current?.pam ?? "") + (page.current?.value === "gnome" ? " auto_start" : "")
            }
        }
    }
}
