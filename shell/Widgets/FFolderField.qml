import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons

// Folder path field: applies shortly after you stop typing (or on Enter),
// shows whether the folder was found, and has a Browse button.
RowLayout {
    id: root

    property string path: ""
    property string placeholder: "~/Pictures/Wallpapers"
    property string status: ""        // "" | "missing" | "empty" | "ok"
    property int count: 0
    property bool busy: false
    signal changed(string path)

    spacing: 8

    function commit() {
        const t = field.text.trim();
        if (t !== "" && t !== root.path)
            root.changed(t);
    }

    FTextField {
        id: field
        Layout.fillWidth: true
        icon: "folder"
        placeholder: root.placeholder
        text: root.path
        border.color: root.status === "missing" ? Theme.error : field.input.activeFocus ? Theme.accent : Theme.border
        onEdited: debounce.restart()
        onAccepted: {
            debounce.stop();
            root.commit();
        }
        onEditingFinished: {
            debounce.stop();
            root.commit();
        }
    }

    // keep the field in sync when the folder changes elsewhere (Browse, other page)
    Connections {
        target: root
        function onPathChanged() {
            if (!field.input.activeFocus)
                field.text = root.path;
        }
    }

    Timer {
        id: debounce
        interval: 700
        onTriggered: root.commit()
    }

    // status
    FIcon {
        icon: root.busy ? "progress_activity" : root.status === "missing" ? "error" : root.status === "empty" ? "image_not_supported" : root.status === "ok" ? "check_circle" : "help"
        size: 20
        fill: 1
        color: root.status === "missing" ? Theme.error : root.status === "ok" ? Theme.success : Theme.textDim
        RotationAnimation on rotation {
            running: root.busy
            from: 0; to: 360; duration: 900; loops: Animation.Infinite
            onRunningChanged: if (!running) parent.rotation = 0
        }
    }

    FButton {
        text: "Browse"
        icon: "folder_open"
        variant: "tonal"
        implicitHeight: 38
        disabled: picker.running
        onClicked: picker.running = true
    }

    // first folder picker available: kdialog, zenity or yad
    Process {
        id: picker
        command: ["sh", "-c", 'start="$1"; ' +
            'if command -v kdialog >/dev/null; then kdialog --getexistingdirectory "$start"; ' +
            'elif command -v zenity >/dev/null; then zenity --file-selection --directory --filename="$start/"; ' +
            'elif command -v yad >/dev/null; then yad --file --directory --filename="$start/"; ' +
            'else echo "@none"; fi', "sh", Paths.normalize(root.path) || Paths.home]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim();
                if (p === "@none")
                    root.noPicker = true;
                else if (p)
                    root.changed(p);
            }
        }
    }
    property bool noPicker: false
}
