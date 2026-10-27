import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services
import qs.Widgets

// Settings → Users: your picture, name and password, and (for administrators)
// the other accounts on this computer: add, remove, administrator or not,
// their passwords and names. Anything that needs your password or root opens
// a terminal for it; passwords are only typed into `passwd` there.
Page {
    id: page
    title: I18n.tr("Users")
    subtitle: I18n.tr("Your account, and the other people who use this computer.")

    Component.onCompleted: Users.refresh()
    readonly property var me: Users.self
    // the row of someone else being removed (asks first), and whether to keep their files
    property string removing: ""

    // ── you ──
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: hero.implicitHeight + Theme.sp5 * 2
        radius: Math.max(12, Theme.rLg)
        color: Theme.alpha(Theme.surface, Math.min(1, Theme.settingsOp + 0.04))
        border.width: 1
        border.color: Theme.alpha(Theme.text, 0.05)

        RowLayout {
            id: hero
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Theme.sp5
            spacing: Theme.sp5

            // the picture: click to change it
            Item {
                Layout.preferredWidth: 104
                Layout.preferredHeight: 104
                Avatar {
                    id: bigFace
                    anchors.fill: parent
                    size: 104
                    path: Settings.data.general.avatar ? Paths.expand(Settings.data.general.avatar) : (page.me?.avatar ?? "")
                    name: Users.fullName
                    scale: faceHover.hovered ? 1.04 : 1
                    Behavior on scale { Anim { duration: Theme.durShort; easing.bezierCurve: Theme.curves.springFast } }
                }
                Rectangle {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    width: 34
                    height: 34
                    radius: 17
                    color: Theme.accent
                    border.width: 3
                    border.color: Theme.surface
                    FIcon { anchors.centerIn: parent; icon: "photo_camera"; size: 17; fill: 1; color: Theme.onAccent }
                }
                HoverHandler { id: faceHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: picker.running = true }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                FText {
                    Layout.fillWidth: true
                    text: Users.fullName
                    font.pixelSize: Theme.fsXxl
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }
                FText { text: "@" + Users.me; dim: true }
                Row {
                    Layout.topMargin: 6
                    spacing: 6
                    Rectangle {
                        width: kind.implicitWidth + 18
                        height: 24
                        radius: 12
                        color: Users.isAdmin ? Theme.alpha(Theme.accent, 0.18) : Theme.alpha(Theme.text, 0.07)
                        FText { id: kind; anchors.centerIn: parent; text: Users.isAdmin ? I18n.tr("Administrator") : I18n.tr("Standard user"); font.pixelSize: Theme.fsXs; font.weight: Font.Bold; color: Users.isAdmin ? Theme.accent : Theme.textDim }
                    }
                    Rectangle {
                        visible: Users.accounts
                        width: acct.implicitWidth + 18
                        height: 24
                        radius: 12
                        color: Theme.alpha(Theme.text, 0.07)
                        FText { id: acct; anchors.centerIn: parent; text: I18n.tr("Shown on the login screen"); font.pixelSize: Theme.fsXs; color: Theme.textDim }
                    }
                }
            }
        }
    }

    FText {
        visible: Users.error !== ""
        Layout.fillWidth: true
        text: Users.error
        color: Theme.error
        wrapMode: Text.Wrap
    }

    Group {
        title: I18n.tr("Your account")
        SettingRow {
            title: I18n.tr("Full name")
            subtitle: Users.accounts ? I18n.tr("Shown on the lock and login screens and in apps") : I18n.tr("Changing it asks for your password in a terminal (AccountsService isn't running)")
            icon: "badge"
            Row {
                spacing: 8
                FTextField {
                    id: nameField
                    implicitWidth: 220
                    text: Users.fullName
                    placeholder: I18n.tr("Your name")
                    onAccepted: if (text.trim() && text.trim() !== Users.fullName) Users.setName(text.trim())
                }
                FButton {
                    text: I18n.tr("Save")
                    disabled: nameField.text.trim() === "" || nameField.text.trim() === Users.fullName
                    onClicked: Users.setName(nameField.text.trim())
                }
            }
        }
        SettingRow {
            title: I18n.tr("Picture")
            subtitle: I18n.tr("Cropped to a square; also used by the login screen and other apps")
            icon: "account_circle"
            Row {
                spacing: 8
                FButton {
                    text: I18n.tr("Choose…")
                    icon: "image"
                    variant: "tonal"
                    onClicked: picker.running = true
                }
                FButton {
                    visible: (page.me?.avatar ?? "") !== ""
                    text: I18n.tr("Remove")
                    variant: "text"
                    onClicked: Users.removeAvatar()
                }
            }
        }
        SettingRow {
            title: I18n.tr("Password")
            subtitle: I18n.tr("Opens a terminal, where you type your current password and then the new one")
            icon: "password"
            FButton {
                text: I18n.tr("Change password…")
                variant: "tonal"
                onClicked: Users.changePassword("")
            }
        }
        SettingRow {
            title: I18n.tr("Signing in")
            subtitle: I18n.tr("Automatic login, fingerprint unlock, the lock screen")
            icon: "login"
            FButton {
                text: I18n.tr("Lock & Login")
                variant: "text"
                onClicked: Panels.settingsPage = "lock"
            }
        }
    }

    Group {
        title: I18n.tr("Other users")
        SettingRow {
            visible: !Users.isAdmin
            title: I18n.tr("Only administrators can change other accounts")
            subtitle: I18n.tr("Ask someone in the ") + Users.adminGroup + " group, or change them with sudo"
            icon: "lock"
        }
        SettingRow {
            visible: Users.loaded && Users.others.length === 0
            title: I18n.tr("Nobody else has an account here")
            icon: "group"
        }
        Repeater {
            model: Users.others
            SettingRow {
                id: urow
                required property var modelData
                readonly property bool asking: page.removing === modelData.name
                title: modelData.fullName || modelData.name
                subtitle: "@" + modelData.name + " · " + (modelData.admin ? I18n.tr("Administrator") : I18n.tr("Standard user"))
                icon: ""
                Row {
                    spacing: 6
                    Avatar {
                        anchors.verticalCenter: parent.verticalCenter
                        size: 32
                        path: urow.modelData.avatar
                        name: urow.modelData.fullName || urow.modelData.name
                    }
                    // what an administrator can do, or (removing) the question first
                    FButton {
                        visible: Users.isAdmin && !urow.asking
                        text: urow.modelData.admin ? I18n.tr("Make standard") : I18n.tr("Make admin")
                        variant: "text"
                        onClicked: Users.setAdmin(urow.modelData.name, !urow.modelData.admin)
                    }
                    FIconButton {
                        visible: Users.isAdmin && !urow.asking
                        anchors.verticalCenter: parent.verticalCenter
                        icon: "password"
                        size: 32
                        iconSize: 17
                        onClicked: Users.changePassword(urow.modelData.name)
                    }
                    FIconButton {
                        visible: Users.isAdmin && !urow.asking
                        anchors.verticalCenter: parent.verticalCenter
                        icon: "person_remove"
                        size: 32
                        iconSize: 17
                        iconColor: Theme.error
                        onClicked: page.removing = urow.modelData.name
                    }
                    FText {
                        visible: urow.asking
                        anchors.verticalCenter: parent.verticalCenter
                        text: I18n.tr("Remove ") + urow.modelData.name + "?"
                        color: Theme.error
                        font.weight: Font.DemiBold
                    }
                    FButton {
                        visible: urow.asking
                        text: I18n.tr("Keep files")
                        variant: "tonal"
                        onClicked: {
                            Users.remove(urow.modelData.name, true);
                            page.removing = "";
                        }
                    }
                    FButton {
                        visible: urow.asking
                        text: I18n.tr("Delete all")
                        onClicked: {
                            Users.remove(urow.modelData.name, false);
                            page.removing = "";
                        }
                    }
                    FIconButton {
                        visible: urow.asking
                        anchors.verticalCenter: parent.verticalCenter
                        icon: "close"
                        size: 32
                        iconSize: 17
                        onClicked: page.removing = ""
                    }
                }
            }
        }
    }

    Group {
        title: I18n.tr("Add a user")
        SettingRow {
            visible: !Users.isAdmin
            title: I18n.tr("Needs an administrator")
            subtitle: I18n.tr("You aren't in the ") + Users.adminGroup + " group, so the terminal will ask for an administrator's password (sudo may refuse you)"
            icon: "admin_panel_settings"
        }
        SettingRow {
            title: I18n.tr("Full name")
            icon: "badge"
            FTextField {
                id: newFull
                implicitWidth: 240
                placeholder: I18n.tr("Alex Doe")
                onEdited: t => {
                    // suggest a user name from it until one is typed
                    if (!newUser.touched)
                        newUser.text = t.toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "").replace(/[^a-z0-9]+/g, "").slice(0, 32);
                }
            }
        }
        SettingRow {
            title: I18n.tr("User name")
            subtitle: newUser.text === "" || page.validName(newUser.text) ? I18n.tr("Lowercase letters, digits, _ and -; can't be changed later") : I18n.tr("Start with a letter; only lowercase letters, digits, _ and -")
            icon: "alternate_email"
            FTextField {
                id: newUser
                property bool touched: false
                implicitWidth: 240
                placeholder: "alex"
                onEdited: touched = true
            }
        }
        SettingRow {
            title: I18n.tr("Administrator")
            subtitle: I18n.tr("Can install software and change other accounts (the ") + Users.adminGroup + " group)"
            icon: "admin_panel_settings"
            FSwitch { id: newAdmin }
        }
        SettingRow {
            title: I18n.tr("Login shell")
            subtitle: I18n.tr("What their terminal runs (from /etc/shells)")
            icon: "terminal"
            FDropdown {
                id: newShell
                implicitWidth: 240
                options: Users.shells.map(s => ({ value: s, label: s }))
                current: Users.shells.includes("/bin/bash") ? "/bin/bash" : (Users.shells[0] ?? "")
                onSelected: v => current = v
            }
        }
        SettingRow {
            title: I18n.tr("Extra groups")
            subtitle: newGroups.text === "" || /^[a-z_][a-z0-9_-]*(\s*,\s*[a-z_][a-z0-9_-]*)*$/.test(newGroups.text.trim()) ? I18n.tr("Optional, comma-separated: e.g. video, audio, input, docker") : I18n.tr("Group names are lowercase letters, digits, _ and -, comma-separated")
            icon: "group_add"
            FTextField { id: newGroups; implicitWidth: 240; placeholder: I18n.tr("video, audio") }
        }
        SettingRow {
            title: I18n.tr("Create")
            subtitle: I18n.tr("Opens a terminal: your password (sudo), then a password for the new account")
            icon: "person_add"
            FButton {
                text: I18n.tr("Add user")
                disabled: !page.validName(newUser.text) || Users.users.some(u => u.name === newUser.text)
                    || (newGroups.text.trim() !== "" && !/^[a-z_][a-z0-9_-]*(\s*,\s*[a-z_][a-z0-9_-]*)*$/.test(newGroups.text.trim()))
                onClicked: {
                    Users.add(newUser.text, newFull.text.trim() || newUser.text, newAdmin.checked, newShell.current, newGroups.text.replace(/\s+/g, ""));
                    newGroups.text = "";
                    newUser.text = "";
                    newUser.touched = false;
                    newFull.text = "";
                    newAdmin.checked = false;
                }
            }
        }
    }

    function validName(n) {
        return /^[a-z_][a-z0-9_-]{0,31}$/.test(n);
    }

    // the picture chooser (portal, or kdialog / zenity)
    Process {
        id: picker
        command: [Paths.bin, "pick", "image", Settings.data.general.avatar ? Paths.expand(Settings.data.general.avatar) : Paths.home + "/Pictures"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim();
                if (p)
                    Users.setAvatar(p);
            }
        }
    }
}
