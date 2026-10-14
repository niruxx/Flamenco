import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services
import qs.Widgets

// Fingerprints (fprintd): enroll and remove your fingers, and use them on the
// lock screen. The login screen's switch is in the Flamenco Greeter group.
Group {
    id: root

    title: "Fingerprint"

    readonly property var st: Fingerprint.st
    readonly property var free: Fingerprint.names.filter(f => !Fingerprint.fingers.includes(f))
    property string choice: ""

    // enrolling: idle | scanning | done | failed
    property string phase: "idle"
    property string finger: ""
    property int scans: 0
    property string hint: ""

    readonly property int stages: st.stages ?? 0

    function enroll(f) {
        finger = f;
        scans = 0;
        hint = "";
        phase = "scanning";
        enroller.command = [Paths.bin, "fingerprint", "enroll", f];
        enroller.running = true;
    }

    function retryHint(result) {
        switch (result) {
        case "enroll-swipe-too-short": return "Too short. Swipe again more slowly";
        case "enroll-finger-not-centered": return "Not centered. Move your finger a little and touch again";
        case "enroll-remove-and-retry": return "Lift your finger, then touch again";
        default: return "Didn't catch that. Touch again";
        }
    }

    function failHint(result) {
        switch (result) {
        case "enroll-duplicate": return "That finger is already enrolled, maybe as another finger or user.";
        case "enroll-data-full": return "The reader has no room for more fingerprints.";
        case "enroll-disconnected": return "The reader was disconnected.";
        default: return "Enrolling didn't finish. Try again.";
        }
    }

    Process {
        id: enroller
        stdout: SplitParser {
            onRead: line => {
                const [kind, detail] = line.split("\t");
                if (kind === "stage") {
                    root.scans++;
                    root.hint = "";
                } else if (kind === "retry") {
                    root.hint = root.retryHint(detail);
                } else if (kind === "done") {
                    root.phase = "done";
                } else if (kind === "fail") {
                    root.phase = "failed";
                    root.hint = root.failHint(detail);
                } else if (kind === "info" && detail) {
                    root.hint = detail;
                }
            }
        }
        onExited: code => {
            if (root.phase === "scanning")
                root.phase = code === 0 ? "done" : "failed";
            Fingerprint.refresh();
        }
    }

    Process {
        id: remover
        onExited: Fingerprint.refresh()
    }

    SettingRow {
        title: !Fingerprint.loaded ? "Checking for a fingerprint reader…"
            : !Fingerprint.installed ? "fprintd isn't installed"
            : !Fingerprint.reader ? "No fingerprint reader found"
            : root.st.device
        subtitle: !Fingerprint.loaded ? ""
            : !Fingerprint.installed ? "fprintd talks to the reader. Install it, then come back here."
            : !Fingerprint.reader ? (root.st.error && root.st.error !== "no reader" ? root.st.error : "fprintd doesn't see a supported reader.")
            : Fingerprint.fingers.length === 0 ? "No fingers enrolled yet"
            : Fingerprint.fingers.length === 1 ? "1 finger enrolled" : Fingerprint.fingers.length + " fingers enrolled"
        icon: Fingerprint.reader ? "fingerprint" : "fingerprint_off"
        Row {
            spacing: 8
            FButton {
                visible: Fingerprint.loaded && !Fingerprint.installed
                text: "Install fprintd"
                variant: "tonal"
                onClicked: Quickshell.execDetached(Paths.termHold("sudo pacman -S --needed fprintd"))
            }
            FIconButton {
                icon: "refresh"
                size: 32
                onClicked: Fingerprint.refresh()
            }
        }
    }

    Repeater {
        model: Fingerprint.reader ? Fingerprint.fingers : []
        SettingRow {
            required property string modelData
            title: Fingerprint.label(modelData)
            icon: "fingerprint"
            FButton {
                text: "Remove"
                variant: "text"
                disabled: remover.running || enroller.running
                onClicked: {
                    remover.command = [Paths.bin, "fingerprint", "delete", modelData];
                    remover.running = true;
                }
            }
        }
    }

    SettingRow {
        visible: Fingerprint.reader && root.phase === "idle" && root.free.length > 0
        title: "Add a fingerprint"
        subtitle: "You'll touch the reader several times"
        icon: "add"
        Row {
            spacing: 8
            FDropdown {
                implicitWidth: 220
                options: root.free.map(f => ({ value: f, label: Fingerprint.label(f) }))
                current: root.free.includes(root.choice) ? root.choice : root.free[0]
                onSelected: v => root.choice = v
            }
            FButton {
                text: "Add"
                icon: "fingerprint"
                disabled: remover.running
                onClicked: root.enroll(root.free.includes(root.choice) ? root.choice : root.free[0])
            }
        }
    }

    // enrolling: progress, hints, cancel
    SettingRow {
        visible: root.phase !== "idle"
        title: root.phase === "done" ? Fingerprint.label(root.finger) + " added"
            : root.phase === "failed" ? "Couldn't add " + Fingerprint.label(root.finger).toLowerCase()
            : root.scans === 0 ? "Touch the reader with your " + Fingerprint.label(root.finger).toLowerCase()
            : "Lift and touch again" + (root.stages > 0 ? " (" + root.scans + " of " + root.stages + ")" : " (" + root.scans + " so far)")
        subtitle: root.hint || (root.phase === "scanning" ? (root.st.scanType === "swipe" ? "Swipe your finger across the reader each time" : "Press, lift, and press again, moving your finger a little each time") : "")
        icon: root.phase === "done" ? "check_circle" : root.phase === "failed" ? "error" : "fingerprint"
        Row {
            spacing: 12
            // progress
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.phase === "scanning" && root.stages > 0
                width: 120
                height: 6
                radius: 3
                color: Theme.alpha(Theme.border, 0.6)
                Rectangle {
                    width: parent.width * Math.min(1, root.scans / Math.max(1, root.stages))
                    height: parent.height
                    radius: 3
                    color: Theme.accent
                    Behavior on width { Anim { duration: Theme.durMed } }
                }
            }
            FButton {
                text: root.phase === "scanning" ? "Cancel" : root.phase === "failed" ? "Try again" : "Done"
                variant: root.phase === "scanning" ? "text" : "tonal"
                onClicked: {
                    if (root.phase === "scanning") {
                        root.phase = "idle";
                        enroller.running = false;   // SIGTERM: the CLI releases the reader
                    } else if (root.phase === "failed") {
                        root.enroll(root.finger);
                    } else {
                        root.phase = "idle";
                    }
                }
            }
        }
    }

    SwitchRow {
        visible: Fingerprint.enrolled
        title: "Unlock the lock screen with a fingerprint"
        subtitle: Settings.data.lock.backend === "command" ? "Only on Flamenco's own lock screen and SDDM themes, not with a lock command" : "Your password still works too"
        icon: "lock_open"
        target: Settings.data.lock
        key: "fingerprint"
    }

    SettingRow {
        visible: Fingerprint.enrolled && !!root.st.pam?.login
        title: "Your login PAM setup also asks for a fingerprint"
        subtitle: "/etc/pam.d/login (or a file it includes) loads pam_fprintd, so typing a password on the lock screen may wait for the reader first. Remove it there if unlocking with a password gets slow."
        icon: "warning"
    }
}
